"""
Fix PostgreSQL sequence for users table
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app
from models import db
from sqlalchemy import text

def fix_users_sequence():
    """Fix the users table sequence"""
    try:
        with app.app_context():
            print("🔧 FIXING USERS TABLE SEQUENCE")
            print("="*50)
            
            # Get current max ID from users table
            result = db.session.execute(text("SELECT MAX(id) FROM users")).fetchone()
            max_id = result[0] if result and result[0] else 0
            print(f"📊 Current max ID in users table: {max_id}")
            
            # Get current sequence value
            try:
                seq_result = db.session.execute(text("SELECT currval('users_id_seq')")).fetchone()
                current_seq = seq_result[0] if seq_result else 0
            except:
                # If sequence hasn't been used yet, get nextval
                seq_result = db.session.execute(text("SELECT nextval('users_id_seq')")).fetchone()
                current_seq = seq_result[0] if seq_result else 1
                
            print(f"📊 Current sequence value: {current_seq}")
            
            # Set sequence to max_id + 1
            new_seq_value = max_id + 1
            db.session.execute(text(f"SELECT setval('users_id_seq', {new_seq_value})"))
            db.session.commit()
            
            print(f"✅ Sequence updated to: {new_seq_value}")
            
            # Verify the fix
            print("\n🧪 Testing the fix...")
            test_user = {
                'name': 'Test User Fix',
                'email': 'test_fix@example.com',
                'phone': '9999999999',
                'designation': 'Test',
                'password': 'testpassword'
            }
            
            # Test insertion
            result = db.session.execute(text("""
                INSERT INTO users (name, email, phone, designation, password) 
                VALUES (:name, :email, :phone, :designation, :password) 
                RETURNING id
            """), test_user)
            
            new_user_row = result.fetchone()
            if new_user_row:
                new_user_id = new_user_row[0]
                print(f"✅ Successfully inserted test user with ID: {new_user_id}")
                
                # Clean up test user
                db.session.execute(text("DELETE FROM users WHERE id = :id"), {'id': new_user_id})
                db.session.commit()
                print("✅ Test user cleaned up")
            
            print("\n🎉 Users table sequence fixed successfully!")
            
    except Exception as e:
        print(f"❌ Error fixing sequence: {e}")
        db.session.rollback()
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    fix_users_sequence()
