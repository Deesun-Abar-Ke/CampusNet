#!/usr/bin/env python3
"""
Script to add missing columns to the users table
"""

import os
import sys
from sqlalchemy import text
from app import app, db

def add_missing_columns():
    """Add missing columns to users table if they don't exist"""
    
    with app.app_context():
        try:
            # Check which columns exist
            result = db.session.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'users' AND table_schema = 'public'
            """))
            
            existing_columns = [row[0] for row in result.fetchall()]
            print(f"Existing columns in users table: {existing_columns}")
            
            # Define the columns we need
            required_columns = {
                'department': 'VARCHAR(100)',
                'level': 'INTEGER',
                'session': 'VARCHAR(50)',
                'student_id': 'VARCHAR(50)',
                'avatar': 'VARCHAR(255)'
            }
            
            # Add missing columns
            for column_name, column_type in required_columns.items():
                if column_name not in existing_columns:
                    print(f"Adding column: {column_name}")
                    db.session.execute(text(f"""
                        ALTER TABLE users 
                        ADD COLUMN {column_name} {column_type}
                    """))
                    db.session.commit()
                    print(f"✓ Added column: {column_name}")
                else:
                    print(f"✓ Column {column_name} already exists")
            
            print("\n✅ All required columns are now present in the users table")
            
        except Exception as e:
            print(f"❌ Error adding columns: {e}")
            db.session.rollback()
            return False
    
    return True

if __name__ == "__main__":
    if add_missing_columns():
        print("Migration completed successfully!")
    else:
        print("Migration failed!")
        sys.exit(1)
