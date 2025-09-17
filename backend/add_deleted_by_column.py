#!/usr/bin/env python3
"""
Migration script to add deleted_by column to messages table
"""

import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_database_url():
    """Get database URL from environment"""
    DATABASE_URL = os.getenv("DATABASE_URL")
    if DATABASE_URL:
        return DATABASE_URL
    
    # Fallback to individual components
    USER = os.getenv("user") or os.getenv("POSTGRES_USER")
    PASSWORD = os.getenv("password") or os.getenv("POSTGRES_PASSWORD")
    HOST = os.getenv("host") or os.getenv("POSTGRES_HOST") or "localhost"
    PORT = os.getenv("port") or os.getenv("POSTGRES_PORT") or "5432"
    DBNAME = os.getenv("dbname") or os.getenv("POSTGRES_DB")
    
    if USER and PASSWORD and DBNAME:
        return f"postgresql+psycopg2://{USER}:{PASSWORD}@{HOST}:{PORT}/{DBNAME}?sslmode=require"
    
    raise ValueError("Database configuration not found")

def add_deleted_by_column():
    """Add deleted_by column to messages table if it doesn't exist"""
    database_url = get_database_url()
    
    # Create engine with minimal connection pool
    engine = create_engine(
        database_url,
        pool_size=1,
        max_overflow=0,
        pool_recycle=60,
        pool_pre_ping=True,
        pool_timeout=10
    )
    
    try:
        with engine.connect() as conn:
            # Check if column already exists
            check_query = text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'messages' AND column_name = 'deleted_by'
            """)
            
            result = conn.execute(check_query)
            column_exists = result.fetchone() is not None
            
            if column_exists:
                print("✅ Column 'deleted_by' already exists in messages table")
                return True
            
            # Add the column
            print("🔄 Adding 'deleted_by' column to messages table...")
            alter_query = text("""
                ALTER TABLE messages 
                ADD COLUMN deleted_by INTEGER REFERENCES users(id)
            """)
            
            conn.execute(alter_query)
            conn.commit()
            
            print("✅ Successfully added 'deleted_by' column to messages table")
            return True
            
    except Exception as e:
        print(f"❌ Error adding deleted_by column: {e}")
        if "relation \"messages\" does not exist" in str(e):
            print("💡 Messages table doesn't exist yet - this is normal for first run")
            return False
        return False
    
    finally:
        engine.dispose()

if __name__ == "__main__":
    print("🔧 Database Migration: Adding deleted_by column")
    print("=" * 50)
    
    try:
        success = add_deleted_by_column()
        if success:
            print("🎉 Migration completed successfully!")
        else:
            print("⚠️ Migration not needed or failed")
    except Exception as e:
        print(f"💥 Migration failed: {e}")