#!/usr/bin/env python3
"""
Test script for file upload functionality
"""
import requests
import os

# Test file upload endpoint
def test_file_upload():
    url = 'http://localhost:5000/api/messages/upload'
    
    # Create a small test file
    test_file_path = '/tmp/test_document.txt'
    with open(test_file_path, 'w') as f:
        f.write('This is a test document for file upload functionality.\n')
        f.write('File upload should work with 100MB limit.\n')
        f.write('This file is much smaller than the limit.')
    
    # You would need a valid JWT token here
    headers = {
        'Authorization': 'Bearer YOUR_JWT_TOKEN_HERE'
    }
    
    with open(test_file_path, 'rb') as f:
        files = {'file': f}
        try:
            response = requests.post(url, files=files, headers=headers)
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
        except Exception as e:
            print(f"Error: {e}")
    
    # Clean up
    os.remove(test_file_path)

def test_file_serving():
    # Test file serving endpoint (this should work without auth)
    url = 'http://localhost:5000/api/messages/uploads/test.txt'
    try:
        response = requests.get(url)
        print(f"File serving status: {response.status_code}")
    except Exception as e:
        print(f"File serving error: {e}")

if __name__ == "__main__":
    print("Testing file upload functionality...")
    test_file_serving()
    # Uncomment with valid token:
    # test_file_upload()
