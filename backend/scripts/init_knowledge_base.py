"""
Knowledge Base Initialization Script
This script loads MIST institutional knowledge into the database
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from flask import Flask
from models import db, InstitutionalKnowledge
from services.rag_service import RAGService
from config import Config
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app():
    """Create Flask app for script execution"""
    app = Flask(__name__)
    Config.init_app(app)
    db.init_app(app)
    return app

def load_institutional_knowledge():
    """Load MIST institutional knowledge from text files"""
    
    app = create_app()
    
    with app.app_context():
        # Initialize RAG service
        rag_service = RAGService()
        
        # Knowledge base directory
        knowledge_dir = Config.INSTITUTIONAL_DATA_PATH
        
        if not os.path.exists(knowledge_dir):
            logger.error(f"Knowledge base directory not found: {knowledge_dir}")
            return False
        
        # Define knowledge files to process
        knowledge_files = [
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
        
        processed_count = 0
        
        for file_info in knowledge_files:
            file_path = os.path.join(knowledge_dir, file_info['filename'])
            
            if not os.path.exists(file_path):
                logger.warning(f"File not found: {file_path}")
                continue
            
            try:
                # Read file content
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check if already exists
                existing = InstitutionalKnowledge.query.filter_by(
                    title=file_info['title']
                ).first()
                
                if existing:
                    logger.info(f"Knowledge already exists: {file_info['title']}")
                    # Update existing content
                    existing.content = content
                    existing.is_processed = False  # Mark for reprocessing
                    db.session.commit()
                else:
                    # Process new knowledge
                    success = rag_service.process_institutional_knowledge(
                        title=file_info['title'],
                        content=content,
                        content_type=file_info['content_type']
                    )
                    
                    if success:
                        processed_count += 1
                        logger.info(f"Successfully processed: {file_info['title']}")
                    else:
                        logger.error(f"Failed to process: {file_info['title']}")
                
            except Exception as e:
                logger.error(f"Error processing {file_info['filename']}: {e}")
                continue
        
        logger.info(f"Knowledge base initialization complete. Processed {processed_count} documents.")
        return True

if __name__ == "__main__":
    print("🚀 Initializing MIST Knowledge Base...")
    success = load_institutional_knowledge()
    
    if success:
        print("✅ Knowledge base initialized successfully!")
        print("\n📚 Available knowledge categories:")
        print("- General MIST Information")
        print("- Academic Programs")
        print("- You can add more files to knowledge_base/institutional_data/")
    else:
        print("❌ Failed to initialize knowledge base")
        sys.exit(1)
