"""
Script to set up Supabase database with pgvector extension
"""
import os
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def setup_supabase_pgvector():
    """Set up pgvector extension in Supabase"""
    try:
        # Get database URL
        db_url = os.getenv('DATABASE_URL')
        if not db_url:
            print("❌ DATABASE_URL not found in environment variables")
            return False
        
        print("🔌 Connecting to Supabase...")
        
        # Connect to database
        conn = psycopg2.connect(db_url)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cur = conn.cursor()
        
        print("✅ Connected to Supabase successfully!")
        
        # Enable pgvector extension
        print("🚀 Enabling pgvector extension...")
        try:
            cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
            print("✅ pgvector extension enabled!")
        except Exception as e:
            print(f"⚠️  pgvector extension: {e}")
            # This might fail if extension is already enabled or if user doesn't have permissions
        
        # Test vector functionality
        print("🧪 Testing vector functionality...")
        try:
            cur.execute("SELECT vector '[1,2,3]' <-> vector '[4,5,6]';")
            result = cur.fetchone()
            print(f"✅ Vector distance test successful: {result[0]}")
        except Exception as e:
            print(f"❌ Vector test failed: {e}")
            return False
        
        # Close connection
        cur.close()
        conn.close()
        
        print("🎉 Supabase setup complete!")
        return True
        
    except Exception as e:
        print(f"❌ Error setting up Supabase: {e}")
        return False

if __name__ == "__main__":
    success = setup_supabase_pgvector()
    if success:
        print("\n🚀 Ready to initialize knowledge base!")
    else:
        print("\n❌ Setup failed. Please check your Supabase credentials.")
