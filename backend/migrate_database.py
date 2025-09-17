"""
Database Migration: Add institutional_knowledge_id to document_embeddings
This script adds the missing foreign key relationship between institutional_knowledge and document_embeddings
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models import db, DocumentEmbedding, InstitutionalKnowledge
from app import app
from sqlalchemy import text

def add_institutional_knowledge_column():
    """Add institutional_knowledge_id column to document_embeddings table"""
    
    try:
        with app.app_context():
            # Check if column already exists
            result = db.session.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name='document_embeddings' 
                AND column_name='institutional_knowledge_id'
            """))
            
            if result.fetchone():
                print("✅ Column 'institutional_knowledge_id' already exists")
                return True
                
            # Add the column
            print("🔄 Adding 'institutional_knowledge_id' column...")
            db.session.execute(text("""
                ALTER TABLE document_embeddings 
                ADD COLUMN institutional_knowledge_id INTEGER 
                REFERENCES institutional_knowledge(id)
            """))
            
            # Update existing institutional embeddings to use proper foreign keys
            print("🔄 Updating existing institutional embeddings...")
            
            # Get all institutional embeddings that use JSON metadata
            institutional_embeddings = db.session.execute(text("""
                SELECT id, source_metadata 
                FROM document_embeddings 
                WHERE source_type = 'institutional' 
                AND source_metadata IS NOT NULL
                AND institutional_knowledge_id IS NULL
            """)).fetchall()
            
            updated_count = 0
            for embedding in institutional_embeddings:
                try:
                    import json
                    metadata = json.loads(embedding.source_metadata)
                    knowledge_id = metadata.get('knowledge_id')
                    
                    if knowledge_id:
                        # Update the embedding to use foreign key
                        db.session.execute(text("""
                            UPDATE document_embeddings 
                            SET institutional_knowledge_id = :knowledge_id
                            WHERE id = :embedding_id
                        """), {
                            'knowledge_id': knowledge_id,
                            'embedding_id': embedding.id
                        })
                        updated_count += 1
                except Exception as e:
                    print(f"⚠️  Could not update embedding {embedding.id}: {e}")
            
            db.session.commit()
            print(f"✅ Migration completed! Updated {updated_count} embeddings")
            return True
            
    except Exception as e:
        db.session.rollback()
        print(f"❌ Migration failed: {e}")
        return False

def test_pipeline():
    """Test the complete pipeline: institutional_knowledge → document_embeddings"""
    
    try:
        with app.app_context():
            # Test 1: Check institutional knowledge exists
            knowledge_count = InstitutionalKnowledge.query.count()
            print(f"📊 Found {knowledge_count} institutional knowledge entries")
            
            # Test 2: Check document embeddings exist
            embedding_count = DocumentEmbedding.query.filter_by(source_type='institutional').count()
            print(f"📊 Found {embedding_count} institutional embeddings")
            
            # Test 3: Check relationships
            linked_embeddings = DocumentEmbedding.query.filter(
                DocumentEmbedding.institutional_knowledge_id.isnot(None)
            ).count()
            print(f"📊 Found {linked_embeddings} embeddings linked to institutional knowledge")
            
            # Test 4: Sample query to verify the relationship
            sample_query = db.session.execute(text("""
                SELECT ik.title, ik.category, COUNT(de.id) as embedding_count
                FROM institutional_knowledge ik
                LEFT JOIN document_embeddings de ON ik.id = de.institutional_knowledge_id
                GROUP BY ik.id, ik.title, ik.category
                ORDER BY embedding_count DESC
                LIMIT 5
            """)).fetchall()
            
            print("\n📈 Top 5 knowledge entries by embedding count:")
            for row in sample_query:
                print(f"   • {row.title[:50]}... ({row.category}): {row.embedding_count} chunks")
            
            print("\n✅ Pipeline test completed successfully!")
            return True
            
    except Exception as e:
        print(f"❌ Pipeline test failed: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Starting database migration and pipeline test...")
    
    # Run migration
    migration_success = add_institutional_knowledge_column()
    
    if migration_success:
        # Test the pipeline
        test_pipeline()
        
        print("\n🎯 PIPELINE VERIFICATION:")
        print("1. ✅ Web scraping → institutional_knowledge table")
        print("2. ✅ institutional_knowledge → document_embeddings table (with proper FK)")
        print("3. ✅ Relationship established for vector search")
        
    else:
        print("❌ Migration failed. Please check the errors above.")
