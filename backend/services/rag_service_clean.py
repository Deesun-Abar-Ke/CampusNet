import os
import json
import numpy as np
from typing import List, Dict, Tuple, Optional
from sentence_transformers import SentenceTransformer
from sqlalchemy import text
from sqlalchemy.sql import func
import logging
from datetime import datetime

from models import db, DocumentEmbedding, InstitutionalKnowledge, UserDocument
from config import Config
from services.groq_service import get_groq_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RAGService:
    """
    Retrieval-Augmented Generation Service using PostgreSQL pgvector
    Handles document processing, embedding generation, and context retrieval
    """
    
    def __init__(self):
        """Initialize RAG service with sentence transformers and pgvector"""
        self.config = Config
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')  # 384 dimensions
        self.embedding_dim = 384
        self.chunk_size = Config.CHUNK_SIZE
        self.chunk_overlap = Config.CHUNK_OVERLAP
        self.max_context_length = Config.MAX_CONTEXT_LENGTH
        
        logger.info("RAG Service initialized with sentence-transformers and pgvector")
    
    def create_embeddings(self, texts: List[str]) -> np.ndarray:
        """Create embeddings for a list of texts using sentence-transformers"""
        try:
            embeddings = self.embedding_model.encode(texts, convert_to_numpy=True)
            return embeddings
        except Exception as e:
            logger.error(f"Error creating embeddings: {e}")
            raise
    
    def split_text_into_chunks(self, text: str) -> List[str]:
        """Split text into overlapping chunks"""
        if len(text) <= self.chunk_size:
            return [text]
        
        chunks = []
        start = 0
        
        while start < len(text):
            end = start + self.chunk_size
            
            # If we're not at the end, try to break at a sentence or word boundary
            if end < len(text):
                # Look for sentence endings
                sentence_end = text.rfind('.', start, end)
                if sentence_end > start + self.chunk_size // 2:
                    end = sentence_end + 1
                else:
                    # Look for word boundaries
                    word_end = text.rfind(' ', start, end)
                    if word_end > start + self.chunk_size // 2:
                        end = word_end
            
            chunk = text[start:end].strip()
            if chunk:
                chunks.append(chunk)
            
            # Move start position with overlap
            start = end - self.chunk_overlap
            if start >= len(text):
                break
        
        return chunks
    
    def process_institutional_knowledge(self, title: str, content: str, 
                                      content_type: str = 'manual', 
                                      source_url: str = None) -> bool:
        """Process and store institutional knowledge with embeddings"""
        try:
            # Create or update institutional knowledge entry
            knowledge = InstitutionalKnowledge.query.filter_by(title=title).first()
            if not knowledge:
                knowledge = InstitutionalKnowledge(
                    title=title,
                    content=content,
                    content_type=content_type,
                    category='general',  # Required field
                    source_url=source_url
                )
                db.session.add(knowledge)
                db.session.flush()  # Get the ID
            else:
                knowledge.content = content
                knowledge.last_updated = datetime.utcnow()
            
            # Remove existing embeddings for this knowledge
            DocumentEmbedding.query.filter_by(
                source_type='institutional',
                source_metadata=json.dumps({'knowledge_id': knowledge.id})
            ).delete()
            
            # Split content into chunks
            chunks = self.split_text_into_chunks(content)
            logger.info(f"Processing {len(chunks)} chunks for '{title}'")
            
            # Create embeddings for chunks
            embeddings = self.create_embeddings(chunks)
            
            # Store embeddings in database
            for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
                doc_embedding = DocumentEmbedding(
                    user_id=None,  # Institutional knowledge
                    document_id=None,
                    content_chunk=chunk,
                    chunk_index=i,
                    embedding_vector=embedding.tolist(),  # pgvector accepts lists
                    source_type='institutional',
                    source_metadata=json.dumps({
                        'knowledge_id': knowledge.id,
                        'title': title,
                        'content_type': content_type
                    })
                )
                db.session.add(doc_embedding)
            
            db.session.commit()
            logger.info(f"Successfully processed institutional knowledge: {title}")
            return True
            
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error processing institutional knowledge '{title}': {e}")
            return False
    
    def process_user_document(self, user_id: int, document_id: int, content: str) -> bool:
        """Process and store user document with embeddings"""
        try:
            # Get document info
            document = UserDocument.query.get(document_id)
            if not document or document.user_id != user_id:
                logger.error(f"Document {document_id} not found for user {user_id}")
                return False
            
            # Remove existing embeddings for this document
            DocumentEmbedding.query.filter_by(
                user_id=user_id,
                document_id=document_id
            ).delete()
            
            # Split content into chunks
            chunks = self.split_text_into_chunks(content)
            logger.info(f"Processing {len(chunks)} chunks for user document {document_id}")
            
            # Create embeddings for chunks
            embeddings = self.create_embeddings(chunks)
            
            # Store embeddings in database
            for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
                doc_embedding = DocumentEmbedding(
                    user_id=user_id,
                    document_id=document_id,
                    content_chunk=chunk,
                    chunk_index=i,
                    embedding_vector=embedding.tolist(),  # pgvector accepts lists
                    source_type='user_document',
                    source_metadata=json.dumps({
                        'filename': document.filename,
                        'file_type': document.file_type
                    })
                )
                db.session.add(doc_embedding)
            
            # Update document processing status
            document.is_processed = True
            document.processing_status = 'completed'
            document.processed_at = datetime.utcnow()
            document.extracted_text = content
            
            db.session.commit()
            logger.info(f"Successfully processed user document {document_id}")
            return True
            
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error processing user document {document_id}: {e}")
            return False
    
    def similarity_search(self, query: str, user_id: Optional[int] = None, 
                         top_k: int = 5, include_user_docs: bool = True) -> List[Dict]:
        """Perform similarity search using pgvector"""
        try:
            # Create query embedding
            query_embedding = self.embedding_model.encode([query], convert_to_numpy=True)[0]
            
            # Convert to proper format for pgvector (as string representation)
            embedding_str = '[' + ','.join(map(str, query_embedding.tolist())) + ']'
            
            # Build the query
            query_parts = []
            params = {'top_k': top_k}
            
            # Base query for institutional knowledge
            institutional_query = f"""
                SELECT 
                    content_chunk,
                    source_metadata,
                    embedding_vector <=> '{embedding_str}'::vector as distance,
                    'institutional' as source_type
                FROM document_embeddings 
                WHERE source_type = 'institutional'
            """
            query_parts.append(institutional_query)
            
            # Add user documents if requested and user_id provided
            if include_user_docs and user_id:
                user_query = f"""
                    SELECT 
                        content_chunk,
                        source_metadata,
                        embedding_vector <=> '{embedding_str}'::vector as distance,
                        'user_document' as source_type
                    FROM document_embeddings 
                    WHERE source_type = 'user_document' AND user_id = {user_id}
                """
                query_parts.append(user_query)
            
            # Combine queries and order by similarity
            combined_query = f"""
                ({') UNION ALL ('.join(query_parts)})
                ORDER BY distance ASC
                LIMIT {top_k}
            """
            
            # Execute query
            result = db.session.execute(text(combined_query))
            rows = result.fetchall()
            
            # Format results
            search_results = []
            for row in rows:
                metadata = json.loads(row.source_metadata) if row.source_metadata else {}
                search_results.append({
                    'content': row.content_chunk,
                    'source_type': row.source_type,
                    'distance': float(row.distance),
                    'similarity': 1 - float(row.distance),  # Convert distance to similarity
                    'metadata': metadata
                })
            
            logger.info(f"Found {len(search_results)} similar chunks for query")
            return search_results
            
        except Exception as e:
            logger.error(f"Error in similarity search: {e}")
            return []
    
    def get_relevant_context(self, query: str, user_id: Optional[int] = None, 
                           max_context_length: Optional[int] = None) -> str:
        """Get relevant context for RAG"""
        if max_context_length is None:
            max_context_length = self.max_context_length
        
        # Perform similarity search
        results = self.similarity_search(
            query=query, 
            user_id=user_id, 
            top_k=10,  # Get more results to filter by length
            include_user_docs=True
        )
        
        if not results:
            return "No relevant context found."
        
        # Build context string with source attribution
        context_parts = []
        current_length = 0
        
        for result in results:
            content = result['content']
            source_info = self._format_source_info(result)
            
            # Format: [Source] Content
            formatted_content = f"[{source_info}] {content}"
            
            # Check if adding this would exceed length limit
            if current_length + len(formatted_content) > max_context_length:
                if current_length == 0:  # If first chunk is too long, truncate it
                    available_space = max_context_length - len(f"[{source_info}] ")
                    truncated_content = content[:available_space] + "..."
                    context_parts.append(f"[{source_info}] {truncated_content}")
                break
            
            context_parts.append(formatted_content)
            current_length += len(formatted_content) + 2  # +2 for newlines
        
        context = "\n\n".join(context_parts)
        
        logger.info(f"Generated context of {len(context)} characters from {len(context_parts)} sources")
        return context
    
    def _format_source_info(self, result: Dict) -> str:
        """Format source information for context"""
        metadata = result.get('metadata', {})
        source_type = result.get('source_type', 'unknown')
        
        if source_type == 'institutional':
            title = metadata.get('title', 'MIST Knowledge')
            return f"MIST: {title}"
        elif source_type == 'user_document':
            filename = metadata.get('filename', 'User Document')
            return f"Your Document: {filename}"
        else:
            return "Unknown Source"
    
    def get_user_document_stats(self, user_id: int) -> Dict:
        """Get statistics about user's documents and embeddings"""
        try:
            # Count documents
            total_docs = UserDocument.query.filter_by(user_id=user_id).count()
            processed_docs = UserDocument.query.filter_by(
                user_id=user_id, 
                is_processed=True
            ).count()
            
            # Count embeddings
            total_embeddings = DocumentEmbedding.query.filter_by(
                user_id=user_id,
                source_type='user_document'
            ).count()
            
            return {
                'total_documents': total_docs,
                'processed_documents': processed_docs,
                'total_embeddings': total_embeddings,
                'processing_rate': (processed_docs / total_docs * 100) if total_docs > 0 else 0
            }
            
        except Exception as e:
            logger.error(f"Error getting user document stats: {e}")
            return {
                'total_documents': 0,
                'processed_documents': 0,
                'total_embeddings': 0,
                'processing_rate': 0
            }
    
    def delete_user_embeddings(self, user_id: int, document_id: Optional[int] = None) -> bool:
        """Delete user's embeddings"""
        try:
            query = DocumentEmbedding.query.filter_by(user_id=user_id)
            if document_id:
                query = query.filter_by(document_id=document_id)
            
            deleted_count = query.delete()
            db.session.commit()
            
            logger.info(f"Deleted {deleted_count} embeddings for user {user_id}")
            return True
            
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error deleting user embeddings: {e}")
            return False

    # Additional methods for testing and integration
    def search_similar_documents(self, query: str, limit: int = 5, user_id: Optional[int] = None) -> List[Dict]:
        """Search for similar documents - wrapper for similarity_search"""
        return self.similarity_search(query=query, user_id=user_id, top_k=limit)

    def retrieve_context(self, query: str, user_id: Optional[int] = None) -> tuple:
        """Retrieve context and sources for chatbot integration"""
        try:
            # Get relevant context
            context = self.get_relevant_context(query=query, user_id=user_id)
            
            # Get source information
            search_results = self.similarity_search(query=query, user_id=user_id, top_k=5)
            sources = []
            for result in search_results:
                sources.append({
                    'content_preview': result['content'][:100] + "...",
                    'similarity': result['similarity'],
                    'source_type': result['source_type'],
                    'metadata': result['metadata']
                })
            
            return context, sources
            
        except Exception as e:
            logger.error(f"Error retrieving context: {e}")
            return "No relevant context available.", []

# Global instance
_rag_service = None

def get_rag_service():
    """Get or create the RAG service instance"""
    global _rag_service
    if _rag_service is None:
        _rag_service = RAGService()
    return _rag_service
