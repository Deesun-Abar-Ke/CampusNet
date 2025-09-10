"""
Test script to check Users table constraints and identify signup issues
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app
from models import db, Users
import traceback

def test_users_table():
    """Test the Users table structure and constraints"""
    
    print("🔍 TESTING USERS TABLE")
    print("="*50)
    
    try:
        with app.app_context():
            # Check table structure
            print("1. Checking Users table structure...")
            inspector = db.inspect(db.engine)
            
            if 'users' not in inspector.get_table_names():
                print("❌ Users table does not exist!")
                return False
            
            # Get table info
            columns = inspector.get_columns('users')
            print("📋 Users table columns:")
            for col in columns:
                nullable = "NULL" if col['nullable'] else "NOT NULL"
                unique = " UNIQUE" if col.get('unique') else ""
                print(f"   • {col['name']}: {col['type']}{unique} {nullable}")
            
            # Check constraints
            print("\n📋 Users table constraints:")
            try:
                constraints = inspector.get_pk_constraint('users')
                print(f"   • Primary Key: {constraints}")
                
                unique_constraints = inspector.get_unique_constraints('users')
                print(f"   • Unique Constraints: {unique_constraints}")
                
                foreign_keys = inspector.get_foreign_keys('users')
                print(f"   • Foreign Keys: {foreign_keys}")
            except Exception as e:
                print(f"   • Could not get constraints: {e}")
            
            # Test creating a user
            print("\n2. Testing user creation...")
            
            # First check if email already exists
            existing_user = Users.query.filter_by(email='test_user_12345@example.com').first()
            if existing_user:
                print("   • Deleting existing test user...")
                db.session.delete(existing_user)
                db.session.commit()
            
            # Try to create a new user
            test_user = Users(
                name="Test User",
                email="test_user_12345@example.com",
                phone="1234567890",
                designation="Student",
                password="test_password"
            )
            
            print("   • Adding user to session...")
            db.session.add(test_user)
            
            print("   • Committing to database...")
            db.session.commit()
            
            print("✅ User created successfully!")
            print(f"   • User ID: {test_user.id}")
            print(f"   • User Name: {test_user.name}")
            print(f"   • User Email: {test_user.email}")
            
            # Clean up
            print("   • Cleaning up test user...")
            db.session.delete(test_user)
            db.session.commit()
            print("✅ Test completed successfully!")
            
            return True
            
    except Exception as e:
        print(f"❌ Error during user table test: {e}")
        traceback.print_exc()
        try:
            db.session.rollback()
        except:
            pass
        return False

def test_signup_data():
    """Test the actual signup data that failed"""
    print("\n🔍 TESTING ACTUAL SIGNUP DATA")
    print("="*50)
    
    try:
        with app.app_context():
            # Test the exact data that failed
            signup_data = {
                'name': 'Aunindya Saha',
                'email': 'aps2025@gmail.com',
                'phone': '1234578965',
                'designation': 'Student',
                'password': 'aps2025@gmail.com'
            }
            
            print("📋 Testing signup data:")
            for key, value in signup_data.items():
                print(f"   • {key}: '{value}' (length: {len(str(value))})")
            
            # Check if email exists
            existing_user = Users.query.filter_by(email=signup_data['email']).first()
            if existing_user:
                print(f"❌ Email already exists! User ID: {existing_user.id}")
                return False
            else:
                print("✅ Email is unique")
            
            # Try to create user with this data
            new_user = Users(**signup_data)
            db.session.add(new_user)
            db.session.commit()
            
            print("✅ Signup data test successful!")
            print(f"   • New user ID: {new_user.id}")
            
            # Clean up
            db.session.delete(new_user)
            db.session.commit()
            print("✅ Cleanup completed")
            
            return True
            
    except Exception as e:
        print(f"❌ Error with signup data: {e}")
        traceback.print_exc()
        try:
            db.session.rollback()
        except:
            pass
        return False

if __name__ == "__main__":
    print("🚀 USERS TABLE DIAGNOSTIC TEST")
    print("="*60)
    
    success1 = test_users_table()
    success2 = test_signup_data()
    
    print("\n" + "="*60)
    if success1 and success2:
        print("🎉 ALL TESTS PASSED! The Users table is working correctly.")
        print("The signup issue might be elsewhere in the application logic.")
    else:
        print("❌ TESTS FAILED! Issues found with Users table.")
        print("Please check the errors above for more details.")
