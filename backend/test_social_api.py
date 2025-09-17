#!/usr/bin/env python3
"""
Simple test script to verify social API endpoints work
"""
import requests
import json

BASE_URL = "http://localhost:5000/api"

def test_social_endpoints():
    print("Testing Social API Endpoints...")
    
    # Test basic endpoints without authentication first
    try:
        print("\n1. Testing GET /api/social/posts (should require auth)")
        response = requests.get(f"{BASE_URL}/social/posts")
        print(f"Status: {response.status_code}")
        if response.status_code == 401:
            print("✅ Correctly requires authentication")
        else:
            print(f"Response: {response.text}")
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error - Flask server not running on localhost:5000")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    
    print("\n2. Testing GET /api/social/tags")
    try:
        response = requests.get(f"{BASE_URL}/social/tags")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\n3. Testing GET /api/social/clubs")  
    try:
        response = requests.get(f"{BASE_URL}/social/clubs")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    return True

if __name__ == "__main__":
    test_social_endpoints()
