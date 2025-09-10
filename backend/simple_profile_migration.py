"""
Simple Profile Migration Script
Creates Profile and Achievement tables without complex dependencies
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app

def create_profile_tables():
    """Create profile-related tables"""
    try:
        with app.app_context():
            from models import db, Profile, Achievement
            
            print("🔧 Creating profile tables...")
            
            # Create tables
            db.create_all()
            
            print("✅ Profile tables created successfully!")
            print("\n📊 Tables created:")
            print("   • profiles")
            print("   • achievements")
            print("   • skills")
            
            # Test database connection
            from models import Users
            user_count = Users.query.count()
            print(f"\n🔍 Current users in database: {user_count}")
            
            return True
            
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False

if __name__ == "__main__":
    print("🚀 PROFILE SYSTEM MIGRATION")
    print("="*40)
    
    success = create_profile_tables()
    
    if success:
        print("\n🎉 Migration completed successfully!")
        print("\n📝 Next steps:")
        print("1. Test the backend: python app.py")
        print("2. Create a user profile via API")
        print("3. Generate your first CV!")
    else:
        print("\n❌ Migration failed. Please check the errors above.")
