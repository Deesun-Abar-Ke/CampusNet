"""
Enhanced Chatbot Service with Advanced Pipeline
Implements 4-step processing: Query Refinement → Context Search → Dual Search → Response Generation
"""

import os
import logging
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

from services.groq_service import get_groq_service
from services.rag_service import RAGService
from services.web_search_service import get_web_search_service
from models import ChatMessage

logger = logging.getLogger(__name__)

class EnhancedChatbotService:
    """Advanced chatbot service with 4-step pipeline processing"""
    
    def __init__(self):
        """Initialize enhanced chatbot service"""
        self.groq_service = get_groq_service(use_chatbot_key=True)  # Use chatbot-specific API key
        self.rag_service = RAGService()
        self.web_search_service = get_web_search_service()
        
        # Configuration
        self.similarity_threshold = 0.3  # Minimum similarity for good RAG results
        self.max_conversation_history = 10  # Number of previous messages to consider
        self.always_web_search = True  # Always perform web search even if RAG finds results
        
        logger.info("Enhanced Chatbot Service initialized with 4-step pipeline")
    
    def process_chat_message(self, 
                           user_message: str, 
                           user_id: int, 
                           session_id: int) -> Dict[str, Any]:
        """
        Main entry point for enhanced chatbot processing
        
        Args:
            user_message: Raw user input
            user_id: User ID for personalization
            session_id: Session ID for conversation context
            
        Returns:
            Dictionary with response and processing metadata
        """
        try:
            logger.info(f"🚀 Starting enhanced chatbot pipeline for user {user_id}")
            
            # Step 1: Query Refinement
            refined_query = self._step1_refine_query(user_message)
            logger.info(f"📝 Step 1 - Query refined: {refined_query[:100]}...")
            
            # Step 2: Get Conversation Context
            conversation_context = self._step2_get_conversation_context(session_id)
            logger.info(f"💬 Step 2 - Found {len(conversation_context)} previous messages")
            
            # Step 3: Dual Search (Knowledge Base + Web)
            knowledge_context, web_context, search_metadata = self._step3_dual_search(
                refined_query, user_id
            )
            logger.info(f"🔍 Step 3 - Knowledge: {len(knowledge_context) if knowledge_context else 0} chars, Web: {len(web_context) if web_context else 0} chars")
            
            # Step 4: Generate Response with Full Context
            response_data = self._step4_generate_response(
                original_query=user_message,
                refined_query=refined_query,
                conversation_context=conversation_context,
                knowledge_context=knowledge_context,
                web_context=web_context,
                search_metadata=search_metadata
            )
            
            logger.info("✅ Enhanced chatbot pipeline completed successfully")
            
            return {
                'success': True,
                'response': response_data['response'],
                'metadata': {
                    'original_query': user_message,
                    'refined_query': refined_query,
                    'conversation_messages': len(conversation_context),
                    'knowledge_used': bool(knowledge_context),
                    'web_search_used': bool(web_context),
                    'processing_steps': ['query_refinement', 'conversation_context', 'dual_search', 'response_generation'],
                    'search_metadata': search_metadata
                }
            }
            
        except Exception as e:
            logger.error(f"❌ Enhanced chatbot pipeline failed: {e}")
            return {
                'success': False,
                'response': "I apologize, but I encountered an error processing your request. Please try again.",
                'error': str(e)
            }
    
    def _step1_refine_query(self, user_message: str) -> str:
        """
        Step 1: Refine user query using LLM
        Improves unclear, incomplete, or contextually poor queries
        """
        try:
            refinement_prompt = f"""You are a query refinement specialist for MIST (Military Institute of Science and Technology) chatbot.

Your task: Take the user's query and refine it to be more specific, clear, and contextually relevant for MIST.

Guidelines:
1. If the query is about MIST topics (admissions, courses, faculty, etc.), make it more specific
2. If the query is vague, add relevant MIST context 
3. If the query is well-formed, return it as-is
4. Keep the original intent but improve clarity
5. Add "MIST" context only when relevant

User Query: "{user_message}"

Refined Query:"""

            result = self.groq_service.generate_response(
                message=refinement_prompt,
                conversation_history=[],
                context=None
            )
            
            if result.get('success'):
                refined = result['response'].strip()
                # Remove markdown formatting and extract just the query
                refined = refined.replace('**', '').replace('*', '')
                if refined.startswith('Refined Query:'):
                    refined = refined.replace('Refined Query:', '').strip()
                
                # Fallback to original if refinement fails
                return refined if refined and len(refined) > 10 else user_message
            else:
                return user_message
                
        except Exception as e:
            logger.warning(f"Query refinement failed: {e}")
            return user_message
    
    def _step2_get_conversation_context(self, session_id: int) -> List[Dict[str, str]]:
        """
        Step 2: Get previous conversation messages for context
        Retrieves last N messages from the same session
        """
        try:
            # Get last N messages from this session
            recent_messages = ChatMessage.query.filter_by(
                session_id=session_id
            ).order_by(ChatMessage.timestamp.desc()).limit(self.max_conversation_history).all()
            
            conversation_context = []
            for msg in reversed(recent_messages):  # Reverse to get chronological order
                conversation_context.append({
                    'role': 'user',
                    'content': msg.content
                })
                if msg.ai_response:
                    conversation_context.append({
                        'role': 'assistant',
                        'content': msg.ai_response
                    })
            
            return conversation_context
            
        except Exception as e:
            logger.error(f"Failed to get conversation context: {e}")
            return []
    
    def _step3_dual_search(self, query: str, user_id: int) -> Tuple[Optional[str], Optional[str], Dict]:
        """
        Step 3: Dual search - Knowledge base + Web search
        Always performs both searches as configured
        """
        knowledge_context = None
        web_context = None
        search_metadata = {
            'knowledge_similarity': 0.0,
            'knowledge_sources': 0,
            'web_sources': 0,
            'search_strategy': 'dual_search'
        }
        
        # Knowledge Base Search
        try:
            # Get similarity search results to check quality
            search_results = self.rag_service.similarity_search(
                query=query,
                user_id=user_id,
                top_k=5
            )
            
            if search_results:
                best_similarity = 1 - search_results[0].get('distance', 1.0)
                search_metadata['knowledge_similarity'] = best_similarity
                search_metadata['knowledge_sources'] = len(search_results)
                
                # Get context if similarity is good enough
                if best_similarity > self.similarity_threshold:
                    knowledge_context = self.rag_service.get_relevant_context(
                        query=query,
                        user_id=user_id,
                        max_context_length=2000
                    )
                    logger.info(f"📚 Knowledge base search: {best_similarity:.3f} similarity")
                else:
                    logger.info(f"📚 Knowledge base search: {best_similarity:.3f} similarity (below threshold)")
            
        except Exception as e:
            logger.error(f"Knowledge base search failed: {e}")
        
        # Web Search (Always performed as per requirement)
        try:
            if self.always_web_search and self.web_search_service.is_available():
                web_context = self.web_search_service.get_context_from_search(
                    query=query,
                    max_length=1500
                )
                
                if web_context:
                    # Count web sources by counting [Web Search] markers
                    web_sources = web_context.count('[Web Search')
                    search_metadata['web_sources'] = web_sources
                    logger.info(f"🌐 Web search: Found {web_sources} sources")
                else:
                    logger.info("🌐 Web search: No results found")
            else:
                logger.info("🌐 Web search: Disabled or unavailable")
                
        except Exception as e:
            logger.error(f"Web search failed: {e}")
        
        return knowledge_context, web_context, search_metadata
    
    def _step4_generate_response(self, 
                               original_query: str,
                               refined_query: str, 
                               conversation_context: List[Dict],
                               knowledge_context: Optional[str],
                               web_context: Optional[str],
                               search_metadata: Dict) -> Dict[str, Any]:
        """
        Step 4: Generate final response with all context
        Combines all previous steps into a comprehensive response
        """
        try:
            # Build comprehensive context
            context_parts = []
            
            if knowledge_context:
                context_parts.append(f"**MIST Knowledge Base Information:**\n{knowledge_context}")
            
            if web_context:
                context_parts.append(f"**Current Web Information:**\n{web_context}")
            
            combined_context = "\n\n".join(context_parts) if context_parts else None
            
            # Generate response with full context
            result = self.groq_service.generate_response(
                message=refined_query,
                conversation_history=conversation_context,
                context=combined_context
            )
            
            if result.get('success'):
                return {
                    'response': result['response'],
                    'context_used': bool(combined_context),
                    'context_sources': len(context_parts)
                }
            else:
                return {
                    'response': "I apologize, but I encountered an error generating a response. Please try again.",
                    'context_used': False,
                    'context_sources': 0
                }
                
        except Exception as e:
            logger.error(f"Response generation failed: {e}")
            return {
                'response': "I apologize, but I encountered an error generating a response. Please try again.",
                'context_used': False,
                'context_sources': 0
            }

# Global service instance
_enhanced_chatbot_service = None

def get_enhanced_chatbot_service():
    """Get or create enhanced chatbot service instance"""
    global _enhanced_chatbot_service
    if _enhanced_chatbot_service is None:
        _enhanced_chatbot_service = EnhancedChatbotService()
    return _enhanced_chatbot_service
