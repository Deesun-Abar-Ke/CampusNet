"""
Test script to verify social feed API endpoints are working
"""

import requests
import json

BASE_URL = "http://127.0.0.1:5000"

def test_get_feed():
    """Test the get feed posts endpoint"""
    print("🧪 Testing GET /api/feed/posts...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/feed/posts")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Successfully retrieved {len(data.get('posts', []))} posts")
            print(f"   Pagination: page {data.get('page', 0)} of {data.get('pages', 0)}")
            print(f"   Total posts: {data.get('total', 0)}")
            
            # Display first few posts
            posts = data.get('posts', [])
            if posts:
                print("\n📝 Sample Posts:")
                for i, post in enumerate(posts[:3], 1):
                    print(f"   {i}. {post.get('title', 'No Title')} - {post.get('club_name', 'Unknown Club')}")
                    print(f"      👍 {post.get('likes_count', 0)} likes, 💬 {post.get('comments_count', 0)} comments")
        else:
            print(f"❌ Request failed: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection error: Make sure the Flask server is running on http://127.0.0.1:5000")
    except Exception as e:
        print(f"❌ Error: {e}")

def test_get_clubs():
    """Test the get clubs endpoint"""
    print("\n🧪 Testing GET /api/feed/clubs...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/feed/clubs")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            clubs = response.json()
            print(f"✅ Successfully retrieved {len(clubs)} clubs")
            
            # Display clubs
            print("\n🏛️ Available Clubs:")
            for club in clubs[:5]:  # Show first 5 clubs
                print(f"   • {club.get('name', 'Unknown')} ({club.get('category', 'No Category')})")
                print(f"     {club.get('description', 'No description')[:80]}...")
        else:
            print(f"❌ Request failed: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection error: Make sure the Flask server is running")
    except Exception as e:
        print(f"❌ Error: {e}")

def test_get_tags():
    """Test the get tags endpoint"""
    print("\n🧪 Testing GET /api/feed/tags...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/feed/tags")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            tags = response.json()
            print(f"✅ Successfully retrieved {len(tags)} tags")
            
            # Display tags
            print("\n🏷️ Available Tags:")
            for tag in tags:
                print(f"   • {tag.get('name', 'Unknown')} ({tag.get('color', '#000000')})")
        else:
            print(f"❌ Request failed: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection error: Make sure the Flask server is running")
    except Exception as e:
        print(f"❌ Error: {e}")

def main():
    print("🚀 Testing CampusNet Social Feed API\n")
    print("=" * 50)
    
    # Test basic endpoints
    test_get_feed()
    test_get_clubs() 
    test_get_tags()
    
    print("\n" + "=" * 50)
    print("🏁 API Testing Complete!")
    print("\nNext Steps:")
    print("1. Test with Flutter app integration")
    print("2. Test authenticated endpoints (create post, like, comment)")
    print("3. Test real-time notifications")

if __name__ == "__main__":
    main()
