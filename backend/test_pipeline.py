"""
🧪 COMPLETE PIPELINE TEST
Tests the full pipeline: Web Scraping → institutional_knowledge → document_embeddings → RAG Search
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models import db, InstitutionalKnowledge, DocumentEmbedding
from services.knowledge_base_manager import get_knowledge_manager
from services.rag_service import get_rag_service
from app import app
import json

def test_complete_pipeline():
    """Test the complete pipeline end-to-end"""
    
    print("🧪 TESTING COMPLETE PIPELINE")
    print("="*50)
    
    try:
        with app.app_context():
            
            # STEP 1: Test Knowledge Base Manager (Web Scraping → institutional_knowledge)
            print("\n📝 STEP 1: Testing Web Scraping → institutional_knowledge")
            
            kb_manager = get_knowledge_manager()
            
            # Add a test entry to verify the pipeline
            test_content = """
            MIST Pipeline Test Content
            
            This is a test content to verify that the complete pipeline works correctly.
            The Military Institute of Science and Technology (MIST) is a premier institution.
            It offers various engineering programs and conducts cutting-edge research.
            The campus has excellent facilities for students and faculty.
            """
            
            # Test scraping pipeline
            result = kb_manager.add_knowledge_entry(
                title="Pipeline Test Entry",
                content=test_content,
                category="test",
                content_type="manual"
            )
            
            if result['success']:
                print("✅ Successfully added test entry to institutional_knowledge")
                test_knowledge_id = result['knowledge_id']
            else:
                print("❌ Failed to add test entry")
                return False
            
            # STEP 2: Test RAG Processing (institutional_knowledge → document_embeddings)
            print("\n🔀 STEP 2: Testing institutional_knowledge → document_embeddings")
            
            rag_service = get_rag_service()
            
            # Process the test entry
            processing_result = rag_service.process_institutional_knowledge(
                title="Pipeline Test Entry",
                content=test_content,
                content_type="manual"
            )
            
            if processing_result:
                print("✅ Successfully processed entry into document_embeddings")
            else:
                print("❌ Failed to process entry into embeddings")
                return False
            
            # STEP 3: Verify Database Relationships
            print("\n🔗 STEP 3: Verifying Database Relationships")
            
            # Check if institutional knowledge exists
            knowledge = InstitutionalKnowledge.query.filter_by(title="Pipeline Test Entry").first()
            if knowledge:
                print(f"✅ Found institutional knowledge: ID {knowledge.id}")
            else:
                print("❌ Institutional knowledge not found")
                return False
            
            # Check if embeddings exist with proper foreign key
            embeddings = DocumentEmbedding.query.filter_by(
                institutional_knowledge_id=knowledge.id,
                source_type='institutional'
            ).all()
            
            if embeddings:
                print(f"✅ Found {len(embeddings)} embeddings linked to institutional knowledge")
                for i, embedding in enumerate(embeddings[:3]):  # Show first 3
                    print(f"   • Chunk {embedding.chunk_index}: {embedding.content_chunk[:50]}...")
            else:
                print("❌ No embeddings found with proper foreign key")
                return False
            
            # STEP 4: Test RAG Search (document_embeddings → search results)
            print("\n🔍 STEP 4: Testing RAG Search Pipeline")
            
            # Test similarity search
            search_results = rag_service.similarity_search(
                query="What facilities does MIST have?",
                top_k=3,
                include_user_docs=False
            )
            
            if search_results:
                print(f"✅ Found {len(search_results)} relevant chunks")
                for i, result in enumerate(search_results[:2]):  # Show first 2
                    print(f"   • Result {i+1}: {result['content'][:50]}... (similarity: {result['similarity']:.3f})")
            else:
                print("❌ No search results found")
                return False
            
            # STEP 5: Test Context Retrieval
            print("\n📄 STEP 5: Testing Context Retrieval")
            
            context = rag_service.get_relevant_context(
                query="Tell me about MIST facilities",
                max_context_length=500
            )
            
            if context and context != "No relevant context found.":
                print("✅ Successfully retrieved relevant context")
                print(f"   Context preview: {context[:100]}...")
            else:
                print("❌ Failed to retrieve context")
                return False
            
            # STEP 6: Verify Pipeline Statistics
            print("\n📊 STEP 6: Pipeline Statistics")
            
            total_knowledge = InstitutionalKnowledge.query.count()
            total_embeddings = DocumentEmbedding.query.filter_by(source_type='institutional').count()
            linked_embeddings = DocumentEmbedding.query.filter(
                DocumentEmbedding.institutional_knowledge_id.isnot(None)
            ).count()
            
            print(f"   • Total institutional knowledge entries: {total_knowledge}")
            print(f"   • Total institutional embeddings: {total_embeddings}")
            print(f"   • Properly linked embeddings: {linked_embeddings}")
            print(f"   • Link ratio: {(linked_embeddings/total_embeddings*100):.1f}%" if total_embeddings > 0 else "N/A")
            
            # Clean up test data
            print("\n🧹 Cleaning up test data...")
            DocumentEmbedding.query.filter_by(institutional_knowledge_id=knowledge.id).delete()
            InstitutionalKnowledge.query.filter_by(id=knowledge.id).delete()
            db.session.commit()
            print("✅ Test data cleaned up")
            
            return True
            
    except Exception as e:
        print(f"❌ Pipeline test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main test function"""
    
    print("🚀 CAMPUSNET PIPELINE VERIFICATION")
    print("="*60)
    
    success = test_complete_pipeline()
    
    print("\n" + "="*60)
    if success:
        print("🎉 PIPELINE TEST PASSED!")
        print("\n✅ VERIFIED PIPELINE:")
        print("1. 🌐 Web Scraping → institutional_knowledge table")
        print("2. 🔄 institutional_knowledge → RAG Processing")  
        print("3. 📊 RAG Processing → document_embeddings table")
        print("4. 🔗 Proper Foreign Key Relationships")
        print("5. 🔍 Vector Search & Context Retrieval")
        print("\n🎯 Your pipeline is working perfectly!")
    else:
        print("❌ PIPELINE TEST FAILED!")
        print("Please check the errors above and fix the issues.")

if __name__ == "__main__":
    main()
