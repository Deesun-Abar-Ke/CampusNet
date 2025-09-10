#!/usr/bin/env python3
"""
🎯 COMPLETE SYSTEM VALIDATION SCRIPT
Validates all enhanced features: Session Management + Knowledge Base
"""

import sys
import os
import traceback
from datetime import datetime

# Add project root to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def print_section(title):
    """Print formatted section header"""
    print(f"\n{'='*60}")
    print(f"🔍 {title}")
    print('='*60)

def print_status(component, status, details=""):
    """Print component status"""
    emoji = "✅" if status else "❌"
    print(f"{emoji} {component}: {details}")

def validate_file_structure():
    """Validate that all essential files are in the correct locations"""
    print_section("FILE STRUCTURE VALIDATION")
    
    required_files = {
        "app.py": "Flask application entry point",
        "models.py": "Database models",
        "config.py": "Configuration settings",
        "routes/chat_routes.py": "Enhanced chat routes",
        "services/knowledge_base_manager.py": "Knowledge base manager",
        "services/rag_service.py": "RAG service",
        "knowledge_base/urls_to_scrape.json": "Web scraping configuration",
        "run_web_scraper.py": "Web scraping utility",
        "process_text_files.py": "Text file processor"
    }
    
    all_good = True
    for file_path, description in required_files.items():
        if os.path.exists(file_path):
            print_status(f"{file_path}", True, description)
        else:
            print_status(f"{file_path}", False, f"MISSING: {description}")
            all_good = False
    
    return all_good

def validate_imports():
    """Test that all critical imports work"""
    print_section("IMPORT VALIDATION")
    
    import_tests = []
    
    # Test Flask app import
    try:
        from app import app, db
        import_tests.append(("Flask App", True, "app.py imports successfully"))
    except Exception as e:
        import_tests.append(("Flask App", False, f"Import failed: {str(e)}"))
    
    # Test models import
    try:
        from models import Users, ChatSession, ChatMessage
        import_tests.append(("Database Models", True, "models.py imports successfully"))
    except Exception as e:
        import_tests.append(("Database Models", False, f"Import failed: {str(e)}"))
    
    # Test services import
    try:
        from services.knowledge_base_manager import get_knowledge_manager
        import_tests.append(("Knowledge Base Manager", True, "services import successful"))
    except Exception as e:
        import_tests.append(("Knowledge Base Manager", False, f"Import failed: {str(e)}"))
    
    # Test chat routes import
    try:
        from routes.chat_routes import chat_bp
        import_tests.append(("Chat Routes", True, "Enhanced chat routes available"))
    except Exception as e:
        import_tests.append(("Chat Routes", False, f"Import failed: {str(e)}"))
    
    all_good = True
    for component, status, details in import_tests:
        print_status(component, status, details)
        if not status:
            all_good = False
    
    return all_good

def validate_database_connection():
    """Test database connectivity"""
    print_section("DATABASE CONNECTION")
    
    try:
        from app import app, db
        from models import Users, ChatSession, InstitutionalKnowledge
        
        with app.app_context():
            # Test basic connection
            from sqlalchemy import text
            result = db.session.execute(text('SELECT 1'))
            print_status("Database Connection", True, "Connection successful")
            
            # Test tables exist
            from sqlalchemy import inspect
            inspector = inspect(db.engine)
            tables = inspector.get_table_names()
            required_tables = ['users', 'chat_sessions', 'chat_messages', 'institutional_knowledge', 'document_embeddings']
            
            for table in required_tables:
                if table in tables:
                    print_status(f"Table: {table}", True, "Table exists")
                else:
                    print_status(f"Table: {table}", False, "Table missing")
            
            return True
            
    except Exception as e:
        print_status("Database Connection", False, f"Error: {str(e)}")
        return False

def validate_knowledge_base():
    """Test knowledge base functionality"""
    print_section("KNOWLEDGE BASE VALIDATION")
    
    try:
        from services.knowledge_base_manager import get_knowledge_manager
        from app import app
        
        with app.app_context():
            kb_manager = get_knowledge_manager()
            
            # Test knowledge base status
            status = kb_manager.get_knowledge_base_status()
            print_status("Knowledge Base Manager", True, f"Status: {status}")
            
            # Test URL configuration
            if os.path.exists("knowledge_base/urls_to_scrape.json"):
                import json
                with open("knowledge_base/urls_to_scrape.json", 'r') as f:
                    urls_config = json.load(f)
                print_status("URL Configuration", True, f"Found {len(urls_config.get('mist_urls', []))} URLs configured")
            else:
                print_status("URL Configuration", False, "urls_to_scrape.json not found")
            
            return True
            
    except Exception as e:
        print_status("Knowledge Base", False, f"Error: {str(e)}")
        traceback.print_exc()
        return False

def validate_session_management():
    """Test session management functionality"""
    print_section("SESSION MANAGEMENT VALIDATION")
    
    try:
        from routes.chat_routes import chat_bp
        from app import app
        import json
        
        with app.test_client() as client:
            with app.app_context():
                # Test user sessions endpoint
                response = client.get('/api/chat/sessions/test_user')
                if response.status_code == 200:
                    sessions = json.loads(response.data)
                    print_status("Get User Sessions", True, f"Retrieved {len(sessions)} sessions")
                else:
                    print_status("Get User Sessions", False, f"HTTP {response.status_code}")
                
                # Test create session endpoint
                response = client.post('/api/chat/sessions', 
                                     json={'user_id': 'test_user', 'title': 'Validation Test'})
                if response.status_code in [200, 201]:
                    print_status("Create Session", True, "Session creation successful")
                else:
                    print_status("Create Session", False, f"HTTP {response.status_code}")
                
                return True
        
    except Exception as e:
        print_status("Session Management", False, f"Error: {str(e)}")
        traceback.print_exc()
        return False

def main():
    """Run complete system validation"""
    print(f"""
🎯 CAMPUSNET SYSTEM VALIDATION
{'='*60}
Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Validating: Enhanced Session Management + Knowledge Base System
""")
    
    validation_results = []
    
    # Run all validations
    validation_results.append(("File Structure", validate_file_structure()))
    validation_results.append(("Imports", validate_imports()))
    validation_results.append(("Database", validate_database_connection()))
    validation_results.append(("Knowledge Base", validate_knowledge_base()))
    validation_results.append(("Session Management", validate_session_management()))
    
    # Print final summary
    print_section("VALIDATION SUMMARY")
    
    passed = 0
    total = len(validation_results)
    
    for component, status in validation_results:
        print_status(component, status, "PASSED" if status else "FAILED")
        if status:
            passed += 1
    
    print(f"\n🎯 OVERALL RESULT: {passed}/{total} components validated successfully")
    
    if passed == total:
        print("\n🎉 ALL SYSTEMS GO! Your enhanced CampusNet backend is ready!")
        print("""
🚀 NEXT STEPS:
1. Run web scraper: python run_web_scraper.py
2. Process text files: python process_text_files.py  
3. Start the server: python app.py
4. Test the enhanced chatbot with session management!
        """)
    else:
        print(f"\n⚠️  {total - passed} issues found. Please review the failed components above.")
        print("Check the KNOWLEDGE_BASE_GUIDE.md for troubleshooting steps.")

if __name__ == "__main__":
    main()
