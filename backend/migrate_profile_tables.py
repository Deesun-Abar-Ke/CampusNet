"""
Create Profile Tables Migration
Creates the new profile, achievements, skills, and cv_templates tables
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app
from models import db

def migrate_profile_tables():
    """Create the new profile-related tables"""
    
    print("🔄 CREATING PROFILE TABLES")
    print("="*40)
    
    try:
        with app.app_context():
            # Create all tables (will only create new ones)
            db.create_all()
            
            print("✅ Successfully created profile tables:")
            print("   • profiles")
            print("   • achievements") 
            print("   • skills")
            print("   • cv_templates")
            
            return True
            
    except Exception as e:
        print(f"❌ Error creating profile tables: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main migration function"""
    print("🚀 PROFILE SYSTEM MIGRATION")
    print("="*50)
    
    success = migrate_profile_tables()
    
    print("\n" + "="*50)
    if success:
        print("🎉 PROFILE MIGRATION COMPLETED!")
        print("\n✅ New tables created:")
        print("• profiles - User profile information")
        print("• achievements - User achievements by category")
        print("• skills - User skills with proficiency levels")
        print("• cv_templates - CV template configurations")
        print("\n🎯 Ready to initialize profile system!")
    else:
        print("❌ PROFILE MIGRATION FAILED!")
        print("Please check the errors above and fix any issues.")

if __name__ == "__main__":
    main()
