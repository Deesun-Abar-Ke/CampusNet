"""
Test the signup functionality
"""
import requests
import json

def test_signup():
    url = "http://192.168.0.105:5000/signup"
    
    test_user = {
        "name": "Aunindya Prosad Saha",
        "email": "aps2025@gmail.com",
        "phone": "1234567890",
        "designation": "Student",
        "password": "aps2025@gmail.com"
    }
    
    try:
        response = requests.post(url, json=test_user, timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        
        if response.status_code == 201:
            print("✅ Signup successful!")
            return True
        elif response.status_code == 409:
            print("⚠️ User already exists (this is expected if running multiple times)")
            return True
        else:
            print("❌ Signup failed")
            return False
            
    except Exception as e:
        print(f"❌ Error testing signup: {e}")
        return False

if __name__ == "__main__":
    print("Testing signup functionality...")
    test_signup()
