"""
Test Profile API endpoints
"""
import requests
import json

# Base URL
BASE_URL = "http://192.168.0.105:5000"

def test_profile_endpoints():
    """Test if profile endpoints are accessible"""
    
    print("🧪 TESTING PROFILE ENDPOINTS")
    print("="*50)
    
    # Test signup first to get a token
    print("1. Testing signup...")
    signup_data = {
        "name": "Test Profile User",
        "email": f"test_profile_{int(__import__('time').time())}@example.com",
        "phone": "1234567890",
        "designation": "Student",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/signup", json=signup_data)
        print(f"   Signup response: {response.status_code}")
        if response.status_code != 201:
            print(f"   Error: {response.text}")
            return False
    except Exception as e:
        print(f"   Signup failed: {e}")
        return False
    
    # Test login to get token
    print("2. Testing login...")
    login_data = {
        "email": signup_data["email"],
        "password": signup_data["password"]
    }
    
    try:
        response = requests.post(f"{BASE_URL}/login", json=login_data)
        print(f"   Login response: {response.status_code}")
        if response.status_code != 200:
            print(f"   Error: {response.text}")
            return False
        
        token = response.json().get("access_token")
        if not token:
            print("   No token received")
            return False
        
        headers = {"Authorization": f"Bearer {token}"}
        print(f"   ✅ Token received: {token[:20]}...")
        
    except Exception as e:
        print(f"   Login failed: {e}")
        return False
    
    # Test profile endpoint
    print("3. Testing profile endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/api/profile", headers=headers)
        print(f"   Profile GET response: {response.status_code}")
        if response.status_code == 200:
            print(f"   ✅ Profile data: {response.json()}")
        else:
            print(f"   Error: {response.text}")
    except Exception as e:
        print(f"   Profile test failed: {e}")
    
    # Test achievements endpoint
    print("4. Testing achievements endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/api/profile/achievements", headers=headers)
        print(f"   Achievements GET response: {response.status_code}")
        if response.status_code == 200:
            print(f"   ✅ Achievements data: {response.json()}")
        else:
            print(f"   Error: {response.text}")
    except Exception as e:
        print(f"   Achievements test failed: {e}")
    
    # Test skills endpoint
    print("5. Testing skills endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/api/profile/skills", headers=headers)
        print(f"   Skills GET response: {response.status_code}")
        if response.status_code == 200:
            print(f"   ✅ Skills data: {response.json()}")
        else:
            print(f"   Error: {response.text}")
    except Exception as e:
        print(f"   Skills test failed: {e}")
    
    return True

if __name__ == "__main__":
    test_profile_endpoints()
