"""
Simple TXT File Knowledge Upload System for MIST Chatbot
Place your complete MIST information in 'mist_knowledge_base/mist_complete_info.txt'
Then run this script to upload to vector database
"""

import os
import shutil
from datetime import datetime
from flask import Flask
from models import db
from config import Config
from services.rag_service import RAGService

def upload_txt_knowledge():
    """Upload TXT file knowledge to vector database"""
    
    # Setup Flask app context
    app = Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI'] = Config.SQLALCHEMY_DATABASE_URI
    db.init_app(app)
    
    with app.app_context():
        print("🚀 MIST Knowledge Upload System")
        print("=" * 50)
        
        # Define file paths
        knowledge_file = "mist_knowledge_base/mist_complete_info.txt"
        processed_dir = "mist_knowledge_base/processed"
        
        # Check if knowledge file exists
        if not os.path.exists(knowledge_file):
            print(f"❌ Error: Please create the file '{knowledge_file}' with your MIST information")
            print(f"📁 Expected location: {os.path.abspath(knowledge_file)}")
            return False
        
        try:
            # Read the TXT file
            print(f"📖 Reading knowledge from: {knowledge_file}")
            with open(knowledge_file, 'r', encoding='utf-8') as f:
                content = f.read().strip()
            
            if not content:
                print("❌ Error: The knowledge file is empty")
                return False
            
            print(f"📊 File content length: {len(content)} characters")
            
            # Initialize RAG service
            print("🧠 Initializing RAG service...")
            rag_service = RAGService()
            
            # Ask user if they want to clear existing knowledge or append
            print("📚 Current knowledge in database...")
            from models import DocumentEmbedding
            existing_count = DocumentEmbedding.query.filter_by(source_type='institutional').count()
            print(f"   Existing institutional embeddings: {existing_count}")
            
            if existing_count > 0:
                clear_choice = input("🤔 Clear existing knowledge and replace? (y/n, default=n): ").strip().lower()
                if clear_choice == 'y':
                    print("🗑️  Clearing existing institutional knowledge...")
                    DocumentEmbedding.query.filter_by(source_type='institutional').delete()
                    db.session.commit()
                    print("✅ Existing knowledge cleared")
                else:
                    print("➕ Appending to existing knowledge...")
            else:
                print("📝 No existing knowledge found, adding new content...")
            
            # Add content to vector database
            print("💾 Adding content to vector database...")
            success = rag_service.process_institutional_knowledge(
                title="MIST Complete Information",
                content=content,
                content_type='complete_knowledge_base'
            )
            
            if success:
                # Create backup copy
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_file = f"{processed_dir}/mist_complete_info_{timestamp}.txt"
                os.makedirs(processed_dir, exist_ok=True)
                shutil.copy2(knowledge_file, backup_file)
                
                print("✅ Success! Knowledge uploaded to vector database")
                print(f"💾 Backup created: {backup_file}")
                
                # Show statistics
                from models import DocumentEmbedding
                total_embeddings = DocumentEmbedding.query.filter_by(source_type='institutional').count()
                print(f"📈 Total embeddings in database: {total_embeddings}")
                
                return True
            else:
                print("❌ Failed to upload knowledge to database")
                return False
                
        except Exception as e:
            print(f"❌ Error processing file: {e}")
            return False

def check_knowledge_status():
    """Check current knowledge base status"""
    app = Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI'] = Config.SQLALCHEMY_DATABASE_URI
    db.init_app(app)
    
    with app.app_context():
        from models import DocumentEmbedding
        
        print("📊 Current Knowledge Base Status:")
        print("-" * 40)
        
        institutional_count = DocumentEmbedding.query.filter_by(source_type='institutional').count()
        user_count = DocumentEmbedding.query.filter_by(source_type='user_document').count()
        
        print(f"🏛️  Institutional Knowledge: {institutional_count} embeddings")
        print(f"👤 User Documents: {user_count} embeddings")
        print(f"📊 Total Embeddings: {institutional_count + user_count}")
        
        if institutional_count > 0:
            # Show recent entries
            recent = DocumentEmbedding.query.filter_by(source_type='institutional').order_by(
                DocumentEmbedding.created_at.desc()
            ).limit(3).all()
            
            print("\n📋 Recent Institutional Knowledge:")
            for i, embedding in enumerate(recent, 1):
                preview = embedding.content_chunk[:100] + "..." if len(embedding.content_chunk) > 100 else embedding.content_chunk
                print(f"   {i}. {preview}")

if __name__ == "__main__":
    print("MIST Knowledge Upload System")
    print("1. Check current status")
    print("2. Upload new knowledge from TXT file")
    
    choice = input("\nEnter choice (1 or 2): ").strip()
    
    if choice == "1":
        check_knowledge_status()
    elif choice == "2":
        upload_txt_knowledge()
    else:
        print("Invalid choice. Please run again and enter 1 or 2.")
