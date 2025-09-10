"""
Simple script to fix the users table sequence issue
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def fix_sequence():
    """Fix the users table sequence"""
    
    print("🔧 FIXING USERS TABLE SEQUENCE")
    print("="*50)
    
    try:
        from app import app
        from models import db
        
        with app.app_context():
            # Start fresh connection
            connection = db.engine.connect()
            
            try:
                # Get current max ID
                result = connection.execute(db.text("SELECT COALESCE(MAX(id), 0) FROM users"))
                max_id = result.scalar() or 0
                print(f"📊 Current max ID in users table: {max_id}")
                
                # Get current sequence value
                result = connection.execute(db.text("SELECT last_value FROM users_id_seq"))
                current_seq = result.scalar() or 0
                print(f"📊 Current sequence value: {current_seq}")
                
                # Calculate what the sequence should be
                next_id = max_id + 1
                print(f"📊 Setting sequence to: {next_id}")
                
                # Reset the sequence
                connection.execute(db.text(f"SELECT setval('users_id_seq', {next_id}, false)"))
                connection.commit()
                
                # Verify the fix
                result = connection.execute(db.text("SELECT last_value FROM users_id_seq"))
                new_seq = result.scalar()
                print(f"✅ Sequence updated to: {new_seq}")
                
                # Test by creating a user
                print("\n🧪 Testing user creation...")
                
                # Use raw SQL to test
                test_result = connection.execute(db.text("""
                    INSERT INTO users (name, email, phone, designation, password) 
                    VALUES ('Test User Fix', 'test_fix_12345@example.com', '1234567890', 'Student', 'password')
                    RETURNING id
                """))
                
                new_user_id = test_result.scalar()
                print(f"✅ Test user created with ID: {new_user_id}")
                
                # Clean up test user
                connection.execute(db.text(f"DELETE FROM users WHERE id = {new_user_id}"))
                connection.commit()
                print("✅ Test user cleaned up")
                
                print("\n🎉 SEQUENCE FIX COMPLETED SUCCESSFULLY!")
                
            except Exception as e:
                print(f"❌ Error during sequence fix: {e}")
                connection.rollback()
                return False
            finally:
                connection.close()
                
            return True
            
    except Exception as e:
        print(f"❌ Error setting up fix: {e}")
        return False

if __name__ == "__main__":
    success = fix_sequence()
    if success:
        print("\n✅ You can now try creating a new user account!")
    else:
        print("\n❌ Sequence fix failed. Please check the errors above.")
