"""
Database Connection Reset Script
Use this to force close all idle database connections before starting the server
"""
import os
import psycopg2
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv()

def reset_database_connections():
    """Force close all idle database connections"""
    try:
        db_url = os.environ.get('DATABASE_URL')
        if not db_url:
            print("❌ DATABASE_URL not found in environment")
            return False
        
        # Parse the database URL
        parsed = urlparse(db_url)
        
        # Connect directly with psycopg2
        conn_params = {
            'host': parsed.hostname,
            'port': parsed.port,
            'database': parsed.path[1:],  # Remove leading slash
            'user': parsed.username,
            'password': parsed.password,
            'sslmode': 'require'
        }
        
        print(f"🔗 Connecting to database: {parsed.hostname}")
        
        # Connect to database
        conn = psycopg2.connect(**conn_params)
        cur = conn.cursor()
        
        # Get current connection count
        cur.execute("""
            SELECT count(*) 
            FROM pg_stat_activity 
            WHERE datname = current_database()
            AND pid != pg_backend_pid()
        """)
        
        current_connections = cur.fetchone()[0]
        print(f"📊 Current active connections: {current_connections}")
        
        # Terminate idle connections older than 1 minute
        cur.execute("""
            SELECT pg_terminate_backend(pid), pid, state, query_start
            FROM pg_stat_activity 
            WHERE datname = current_database()
            AND pid != pg_backend_pid()
            AND state = 'idle'
            AND query_start < NOW() - INTERVAL '1 minute'
        """)
        
        terminated = cur.fetchall()
        print(f"🔄 Terminated {len(terminated)} idle connections")
        
        # Get remaining connection count
        cur.execute("""
            SELECT count(*) 
            FROM pg_stat_activity 
            WHERE datname = current_database()
            AND pid != pg_backend_pid()
        """)
        
        remaining_connections = cur.fetchone()[0]
        print(f"📊 Remaining active connections: {remaining_connections}")
        
        conn.commit()
        cur.close()
        conn.close()
        
        print("✅ Database connection cleanup completed successfully")
        return True
        
    except Exception as e:
        print(f"❌ Error during database cleanup: {e}")
        return False

if __name__ == "__main__":
    print("🧹 Starting database connection cleanup...")
    success = reset_database_connections()
    
    if success:
        print("\n🚀 Safe to start the backend server now!")
    else:
        print("\n⚠️  Cleanup failed, but you can still try starting the server.")
