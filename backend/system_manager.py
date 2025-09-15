#!/usr/bin/env python3
"""
CampusNet System Management Tool
Comprehensive management for session handling, knowledge base, and system cleanup
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app, db
from models import ChatSession, ChatMessage, InstitutionalKnowledge, Users
from services.knowledge_base_manager import get_knowledge_manager
from services.enhanced_chatbot_service import get_enhanced_chatbot_service
import logging
from datetime import datetime, timedelta
from sqlalchemy import text

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CampusNetSystemManager:
    """Comprehensive system management for CampusNet"""
    
    def __init__(self):
        self.app = app
        self.db = db
        self.kb_manager = get_knowledge_manager()
        
    def session_management_report(self):
        """Generate comprehensive session management report"""
        print("🔄 SESSION MANAGEMENT ANALYSIS")
        print("=" * 50)
        
        with self.app.app_context():
            # Total sessions and users
            total_sessions = ChatSession.query.count()
            active_sessions = ChatSession.query.filter_by(is_active=True).count()
            total_users_with_sessions = ChatSession.query.distinct(ChatSession.user_id).count()
            
            print(f"📊 Total Sessions: {total_sessions}")
            print(f"✅ Active Sessions: {active_sessions}")
            print(f"👥 Users with Sessions: {total_users_with_sessions}")
            
            # Session activity in last 7 days
            week_ago = datetime.utcnow() - timedelta(days=7)
            recent_activity = ChatSession.query.filter(
                ChatSession.updated_at >= week_ago
            ).count()
            
            print(f"📅 Sessions Active (Last 7 days): {recent_activity}")
            
            # Average messages per session
            total_messages = ChatMessage.query.count()
            avg_messages = total_messages / total_sessions if total_sessions > 0 else 0
            
            print(f"💬 Total Messages: {total_messages}")
            print(f"📈 Average Messages per Session: {avg_messages:.2f}")
            
            # Top 5 most active users
            print("\n🏆 TOP 5 MOST ACTIVE USERS:")
            user_activity = self.db.session.execute(text("""
                SELECT 
                    u.username,
                    COUNT(DISTINCT cs.id) as session_count,
                    COUNT(cm.id) as message_count,
                    MAX(cs.updated_at) as last_activity
                FROM users u
                LEFT JOIN chat_sessions cs ON u.id = cs.user_id
                LEFT JOIN chat_messages cm ON cs.id = cm.session_id
                WHERE cs.is_active = true
                GROUP BY u.id, u.username
                ORDER BY message_count DESC
                LIMIT 5
            """)).fetchall()
            
            for i, user in enumerate(user_activity, 1):
                print(f"   {i}. {user.username}: {user.session_count} sessions, {user.message_count} messages")
            
    def knowledge_base_analysis(self):
        """Analyze knowledge base status and suggest improvements"""
        print("\n📚 KNOWLEDGE BASE ANALYSIS")
        print("=" * 50)
        
        with self.app.app_context():
            # Get knowledge base status
            status = self.kb_manager.get_knowledge_base_status()
            
            if status['success']:
                print(f"📖 Total Entries: {status['total_entries']}")
                print(f"✅ Processed Entries: {status['processed_entries']}")
                print(f"⏳ Unprocessed Entries: {status['unprocessed_entries']}")
                
                if status['unprocessed_entries'] > 0:
                    print(f"⚠️  WARNING: {status['unprocessed_entries']} entries need RAG processing!")
                
                print("\n📂 CATEGORIES:")
                for category, count in status['categories'].items():
                    print(f"   - {category}: {count} entries")
                
                print("\n🕒 RECENT ADDITIONS:")
                for entry in status['recent_entries']:
                    print(f"   - {entry['title'][:50]}... ({entry['category']})")
                
                # Check for duplicates
                duplicates = self.db.session.execute(text("""
                    SELECT source_url, COUNT(*) as count
                    FROM institutional_knowledge 
                    WHERE source_url IS NOT NULL 
                    GROUP BY source_url 
                    HAVING COUNT(*) > 1
                """)).fetchall()
                
                if duplicates:
                    print(f"\n🚨 DUPLICATE DETECTION: Found {len(duplicates)} duplicate URL groups!")
                    print("   Run cleanup to remove duplicates")
                else:
                    print("\n✅ No duplicates found in knowledge base")
            else:
                print(f"❌ Error getting knowledge base status: {status.get('error')}")
    
    def system_health_check(self):
        """Comprehensive system health check"""
        print("\n🏥 SYSTEM HEALTH CHECK")
        print("=" * 50)
        
        with self.app.app_context():
            try:
                # Database connectivity
                self.db.session.execute(text("SELECT 1"))
                print("✅ Database Connection: OK")
                
                # Enhanced chatbot service
                chatbot = get_enhanced_chatbot_service()
                print("✅ Enhanced Chatbot Service: OK")
                
                # RAG service
                rag_test = self.kb_manager.rag_service
                print("✅ RAG Service: OK")
                
                # Check table existence
                tables = ['users', 'chat_sessions', 'chat_messages', 'institutional_knowledge']
                for table in tables:
                    count = self.db.session.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
                    print(f"✅ Table '{table}': {count} records")
                
                # Check for orphaned data
                orphaned_messages = self.db.session.execute(text("""
                    SELECT COUNT(*) FROM chat_messages cm
                    LEFT JOIN chat_sessions cs ON cm.session_id = cs.id
                    WHERE cs.id IS NULL
                """)).scalar()
                
                if orphaned_messages > 0:
                    print(f"⚠️  Found {orphaned_messages} orphaned messages")
                else:
                    print("✅ No orphaned messages found")
                
            except Exception as e:
                print(f"❌ System health check failed: {e}")
    
    def sqlite_investigation(self):
        """Investigate SQLite usage in the system"""
        print("\n🔍 SQLITE INVESTIGATION")
        print("=" * 50)
        
        # Check for SQLite files
        sqlite_files = []
        for root, dirs, files in os.walk('.'):
            for file in files:
                if file.endswith('.db') or file.endswith('.sqlite') or file.endswith('.sqlite3'):
                    sqlite_files.append(os.path.join(root, file))
        
        if sqlite_files:
            print("🗃️  Found SQLite files:")
            for file in sqlite_files:
                print(f"   - {file}")
            print("\n⚠️  SQLite files detected. Consider removal if using PostgreSQL/Supabase only.")
        else:
            print("✅ No SQLite files found. System is clean.")
        
        # Check for SQLite imports in code
        sqlite_imports = []
        for root, dirs, files in os.walk('.'):
            if 'test_files' in root or '__pycache__' in root:
                continue
            for file in files:
                if file.endswith('.py'):
                    filepath = os.path.join(root, file)
                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            content = f.read()
                            if 'sqlite' in content.lower():
                                sqlite_imports.append(filepath)
                    except:
                        pass
        
        if sqlite_imports:
            print("\n📝 Files with SQLite references:")
            for file in sqlite_imports:
                print(f"   - {file}")
        else:
            print("\n✅ No SQLite references found in code.")
    
    def cleanup_recommendations(self):
        """Provide cleanup recommendations"""
        print("\n🧹 CLEANUP RECOMMENDATIONS")
        print("=" * 50)
        
        recommendations = []
        
        with self.app.app_context():
            # Check for unprocessed knowledge base entries
            unprocessed = InstitutionalKnowledge.query.filter_by(is_processed=False).count()
            if unprocessed > 0:
                recommendations.append(f"Process {unprocessed} unprocessed knowledge base entries")
            
            # Check for inactive sessions with no messages
            empty_sessions = self.db.session.execute(text("""
                SELECT COUNT(*) FROM chat_sessions cs
                LEFT JOIN chat_messages cm ON cs.id = cm.session_id
                WHERE cm.id IS NULL AND cs.is_active = false
            """)).scalar()
            
            if empty_sessions > 0:
                recommendations.append(f"Remove {empty_sessions} empty inactive sessions")
            
            # Check for old inactive sessions
            month_ago = datetime.utcnow() - timedelta(days=30)
            old_sessions = ChatSession.query.filter(
                ChatSession.is_active == False,
                ChatSession.updated_at < month_ago
            ).count()
            
            if old_sessions > 0:
                recommendations.append(f"Archive {old_sessions} old inactive sessions")
        
        if recommendations:
            print("📋 Recommended Actions:")
            for i, rec in enumerate(recommendations, 1):
                print(f"   {i}. {rec}")
        else:
            print("✅ System is clean. No cleanup recommendations.")
    
    def run_comprehensive_analysis(self):
        """Run complete system analysis"""
        print("🚀 CAMPUSNET SYSTEM ANALYSIS")
        print("=" * 50)
        print(f"📅 Analysis Date: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}")
        
        self.session_management_report()
        self.knowledge_base_analysis()
        self.system_health_check()
        self.sqlite_investigation()
        self.cleanup_recommendations()
        
        print("\n" + "=" * 50)
        print("📊 ANALYSIS COMPLETE")

def main():
    """Main function to run system analysis"""
    manager = CampusNetSystemManager()
    manager.run_comprehensive_analysis()

if __name__ == "__main__":
    main()
