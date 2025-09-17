"""
Comprehensive Supabase Diagnostics
"""
import os
import psycopg2
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv()

def test_supabase_status():
    """Test Supabase project status and connectivity"""
    print("🔍 Supabase Project Diagnostics")
    print("=" * 50)
    
    # Get all relevant environment variables
    database_url = os.getenv('DATABASE_URL')
    user = os.getenv('user')
    password = os.getenv('password')
    host = os.getenv('host')
    port = os.getenv('port')
    dbname = os.getenv('dbname')
    
    print(f"📊 Environment Variables:")
    print(f"   DATABASE_URL exists: {bool(database_url)}")
    print(f"   User: {user}")
    print(f"   Password: {password[:4]}****{password[-4:] if password else 'None'}")
    print(f"   Host: {host}")
    print(f"   Port: {port}")
    print(f"   DB Name: {dbname}")
    
    if database_url:
        print(f"\n📋 DATABASE_URL Analysis:")
        try:
            parsed = urlparse(database_url)
            print(f"   Scheme: {parsed.scheme}")
            print(f"   Username: {parsed.username}")
            print(f"   Password: {parsed.password[:4]}****{parsed.password[-4:] if parsed.password else 'None'}")
            print(f"   Hostname: {parsed.hostname}")
            print(f"   Port: {parsed.port}")
            print(f"   Database: {parsed.path[1:]}")  # Remove leading slash
            print(f"   Query params: {parsed.query}")
        except Exception as e:
            print(f"   ❌ URL parsing error: {e}")
    
    # Test basic network connectivity to Supabase
    print(f"\n🌐 Network Connectivity Test:")
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, int(port)))
        sock.close()
        
        if result == 0:
            print(f"   ✅ Can reach {host}:{port}")
        else:
            print(f"   ❌ Cannot reach {host}:{port} (Network issue)")
            return False
    except Exception as e:
        print(f"   ❌ Network test failed: {e}")
        return False
    
    # Test different connection methods
    print(f"\n🔗 Connection Methods Test:")
    
    # Method 1: Direct psycopg2 with individual params
    print(f"\n1️⃣ Testing individual parameters...")
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=dbname,
            sslmode='require'
        )
        conn.close()
        print(f"   ✅ Individual params work!")
        return True
    except psycopg2.OperationalError as e:
        print(f"   ❌ Individual params failed: {e}")
        if "password authentication failed" in str(e):
            print(f"      → This confirms credentials are wrong")
        elif "Tenant or user not found" in str(e):
            print(f"      → This suggests project is paused or suspended")
    
    # Method 2: DATABASE_URL direct
    print(f"\n2️⃣ Testing DATABASE_URL...")
    try:
        # Remove SQLAlchemy prefix for direct psycopg2
        clean_url = database_url.replace('postgresql+psycopg2://', 'postgresql://')
        conn = psycopg2.connect(clean_url)
        conn.close()
        print(f"   ✅ DATABASE_URL works!")
        return True
    except psycopg2.OperationalError as e:
        print(f"   ❌ DATABASE_URL failed: {e}")
    
    # Method 3: Try without pooler (direct connection)
    print(f"\n3️⃣ Testing direct connection (non-pooler)...")
    try:
        direct_host = host.replace('.pooler', '')  # Remove pooler
        conn = psycopg2.connect(
            host=direct_host,
            port=5432,
            user=user,
            password=password,
            database=dbname,
            sslmode='require'
        )
        conn.close()
        print(f"   ✅ Direct connection works!")
        print(f"   💡 Suggestion: Use direct connection instead of pooler")
        return True
    except psycopg2.OperationalError as e:
        print(f"   ❌ Direct connection failed: {e}")
    
    print(f"\n❌ All connection methods failed!")
    print(f"\n🔧 Possible Solutions:")
    print(f"   1. Check Supabase dashboard - project might be paused")
    print(f"   2. Verify credentials in Supabase Settings → Database")
    print(f"   3. Check if you have billing issues")
    print(f"   4. Try resetting database password")
    print(f"   5. Check if IP is whitelisted (if IP restrictions enabled)")
    
    return False

if __name__ == "__main__":
    test_supabase_status()
