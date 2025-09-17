#!/usr/bin/env python3
"""
MIST Knowledge Base Initialization Script
This script loads institutional knowledge into the database for RAG functionality
"""

import os
import sys
from pathlib import Path

# Add backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.append(str(backend_dir))

from flask import Flask
from models import db, InstitutionalKnowledge
from services.rag_service import RAGService
from config import Config
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def create_app():
    """Create Flask app for database operations"""
    app = Flask(__name__)
    
    try:
        Config.init_app(app)
        print("✅ Using new configuration system")
    except Exception as e:
        print(f"⚠️ Configuration error: {e}")
        return None
    
    db.init_app(app)
    return app

def load_institutional_documents():
    """Load institutional documents from the knowledge base directory"""
    
    knowledge_base_path = Config.INSTITUTIONAL_DATA_PATH
    
    if not os.path.exists(knowledge_base_path):
        print(f"❌ Knowledge base directory not found: {knowledge_base_path}")
        return False
    
    rag_service = RAGService()
    loaded_count = 0
    
    # Define document mappings
    documents = [
        {
            'filename': 'mist_general_info.txt',
            'title': 'MIST General Information',
            'category': 'general',
            'content_type': 'text'
        },
        {
            'filename': 'mist_academics.txt', 
            'title': 'MIST Academic Programs',
            'category': 'academic',
            'content_type': 'text'
        }
    ]
    
    for doc_info in documents:
        file_path = os.path.join(knowledge_base_path, doc_info['filename'])
        
        if os.path.exists(file_path):
            try:
                # Read file content
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check if document already exists
                existing = InstitutionalKnowledge.query.filter_by(
                    title=doc_info['title']
                ).first()
                
                if existing:
                    print(f"📄 Updating existing document: {doc_info['title']}")
                    existing.content = content
                    existing.is_processed = False  # Mark for reprocessing
                    db.session.commit()
                else:
                    print(f"📄 Loading new document: {doc_info['title']}")
                
                # Process document with RAG service
                success = rag_service.process_institutional_document(
                    title=doc_info['title'],
                    content=content,
                    content_type=doc_info['content_type'],
                    category=doc_info['category']
                )
                
                if success:
                    loaded_count += 1
                    print(f"✅ Successfully processed: {doc_info['title']}")
                else:
                    print(f"❌ Failed to process: {doc_info['title']}")
                    
            except Exception as e:
                print(f"❌ Error processing {doc_info['filename']}: {str(e)}")
        else:
            print(f"⚠️ File not found: {file_path}")
    
    print(f"\n🎉 Successfully loaded {loaded_count} institutional documents")
    return loaded_count > 0

def initialize_database():
    """Initialize database tables"""
    try:
        db.create_all()
        print("✅ Database tables created/verified")
        return True
    except Exception as e:
        print(f"❌ Database initialization failed: {str(e)}")
        return False

def main():
    """Main initialization function"""
    print("🚀 Initializing MIST Knowledge Base...")
    
    # Validate environment
    if not Config.GEMINI_API_KEY:
        print("❌ GEMINI_API_KEY not found in environment variables")
        print("   Please set your Gemini API key in the .env file")
        return False
    
    # Create Flask app
    app = create_app()
    if not app:
        print("❌ Failed to create Flask app")
        return False
    
    with app.app_context():
        # Initialize database
        if not initialize_database():
            return False
        
        # Load knowledge base
        if not load_institutional_documents():
            print("⚠️ No documents were loaded")
            return False
    
    print("\n🎉 Knowledge base initialization completed successfully!")
    print("\nNext steps:")
    print("1. Start your Flask server: python app.py")
    print("2. The AI chatbot will now have access to MIST institutional knowledge")
    print("3. Users can upload their own documents for personalized assistance")
    
    return True

if __name__ == "__main__":
    if main():
        sys.exit(0)
    else:
        sys.exit(1)
