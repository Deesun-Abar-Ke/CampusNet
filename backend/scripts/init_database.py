"""
Database initialization script
Creates all tables required for the RAG chatbot system
"""
import os
import sys
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

# Add parent directory to path to import models
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import db, Users, Tution, ChatSession, ChatMessage, UserDocument, DocumentEmbedding, InstitutionalKnowledge
from config import Config

def create_app():
    """Create Flask app for database operations"""
    app = Flask(__name__)
    app.config.from_object(Config)
    db.init_app(app)
    return app

def init_database():
    """Initialize database tables"""
    try:
        app = create_app()
        
        with app.app_context():
            print("🚀 Creating database tables...")
            
            # Create all tables
            db.create_all()
            
            print("✅ Database tables created successfully!")
            
            # Test the vector extension
            from sqlalchemy import text
            try:
                result = db.session.execute(text("SELECT vector '[1,2,3]' <-> vector '[4,5,6]';"))
                distance = result.fetchone()[0]
                print(f"✅ Vector extension test: distance = {distance}")
            except Exception as e:
                print(f"⚠️  Vector extension test failed: {e}")
            
            return True
            
    except Exception as e:
        print(f"❌ Error creating database tables: {e}")
        return False

if __name__ == "__main__":
    print("🔧 Initializing CampusNet RAG Database...")
    success = init_database()
    
    if success:
        print("\n🎉 Database initialization complete!")
        print("📋 Tables created:")
        print("   - users")
        print("   - tutions")
        print("   - chat_sessions")
        print("   - chat_messages")
        print("   - user_documents")
        print("   - document_embeddings (with pgvector support)")
        print("   - institutional_knowledge")
        print("\n🚀 Ready to initialize knowledge base!")
    else:
        print("\n❌ Database initialization failed!")
        sys.exit(1)
