"""
Enhanced Web Scraper with Serper API
Scrapes web content and adds to MIST knowledge base WITHOUT clearing existing content
"""

import http.client
import json
import re
from datetime import datetime
from urllib.parse import quote

def scrape_with_serper(url, api_key="980824be1e3ab4fb3c1ece3d275e5f7969daa950"):
    """Scrape content using Serper API"""
    try:
        print(f"🌐 Scraping with Serper API: {url}")
        
        conn = http.client.HTTPSConnection("scrape.serper.dev")
        
        # Encode the URL properly
        encoded_url = quote(url, safe=':/?#[]@!$&\'()*+,;=')
        request_path = f"/?url={encoded_url}&apiKey={api_key}"
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        conn.request("GET", request_path, '', headers)
        res = conn.getresponse()
        data = res.read()
        
        if res.status == 200:
            # Try to parse as JSON first
            try:
                result = json.loads(data.decode("utf-8"))
                return result
            except json.JSONDecodeError:
                # If not JSON, treat as plain text
                return {"text": data.decode("utf-8")}
        else:
            print(f"❌ Serper API error: {res.status} - {data.decode('utf-8')}")
            return None
            
    except Exception as e:
        print(f"❌ Error with Serper API: {e}")
        return None
    finally:
        try:
            conn.close()
        except:
            pass

def clean_scraped_content(content):
    """Clean and format scraped content"""
    if not content:
        return ""
    
    # Remove excessive whitespace
    content = re.sub(r'\n\s*\n', '\n\n', content)
    content = re.sub(r' +', ' ', content)
    
    # Remove common unwanted patterns
    unwanted_patterns = [
        r'Cookie.*?Accept.*?\n',
        r'Privacy Policy.*?\n',
        r'Terms.*?Service.*?\n',
        r'Subscribe.*?Newsletter.*?\n',
        r'Follow us.*?\n',
        r'Copyright.*?\d{4}.*?\n',
        r'All rights reserved.*?\n',
        r'Back to top.*?\n'
    ]
    
    for pattern in unwanted_patterns:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE)
    
    # Limit length to avoid overwhelming
    if len(content) > 8000:
        content = content[:8000] + "\n\n[Content truncated for length]"
    
    return content.strip()

def extract_title_from_url(url):
    """Extract a reasonable title from URL"""
    try:
        # Remove protocol and www
        clean_url = url.replace('https://', '').replace('http://', '').replace('www.', '')
        
        # Get domain and path
        parts = clean_url.split('/')
        domain = parts[0].replace('.com', '').replace('.org', '').replace('.edu', '')
        
        if len(parts) > 1:
            path = parts[-1].replace('-', ' ').replace('_', ' ')
            title = f"{domain.title()} - {path.title()}"
        else:
            title = domain.title()
        
        return title
    except:
        return "Web Page Content"

def append_to_knowledge_file(title, content, url):
    """Append scraped content to the knowledge base file"""
    knowledge_file = "mist_knowledge_base/mist_complete_info.txt"
    
    try:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        formatted_content = f"""

{'='*70}
WEB SCRAPED: {title}
SOURCE URL: {url}
SCRAPED ON: {timestamp}
{'='*70}

{content}

"""
        
        # Append to the knowledge file
        with open(knowledge_file, 'a', encoding='utf-8') as f:
            f.write(formatted_content)
        
        print(f"✅ Content appended to {knowledge_file}")
        print(f"📊 Added {len(content)} characters")
        return True
        
    except Exception as e:
        print(f"❌ Error saving to file: {e}")
        return False

def main():
    """Main scraping function"""
    print("🌐 MIST Web Scraper with Serper API")
    print("=" * 45)
    print("This will scrape a webpage and ADD it to your existing knowledge base")
    print("(It will NOT clear existing content)")
    print()
    
    # Get URL from user
    url = input("🔗 Enter the URL to scrape: ").strip()
    
    if not url:
        print("❌ No URL provided")
        return
    
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
        print(f"🔧 Added protocol: {url}")
    
    # Scrape with Serper
    scraped_data = scrape_with_serper(url)
    
    if not scraped_data:
        print("❌ Failed to scrape content from the URL")
        return
    
    # Extract content and title
    if isinstance(scraped_data, dict):
        content = scraped_data.get('text', str(scraped_data))
        title = scraped_data.get('title', extract_title_from_url(url))
    else:
        content = str(scraped_data)
        title = extract_title_from_url(url)
    
    # Clean the content
    clean_content = clean_scraped_content(content)
    
    if len(clean_content) < 100:
        print("❌ Insufficient content extracted from the page")
        print(f"Raw content preview: {content[:200]}...")
        return
    
    # Show preview
    print(f"\n📝 Title: {title}")
    print(f"📊 Content length: {len(clean_content)} characters")
    print(f"📄 Preview: {clean_content[:300]}...")
    
    # Confirm before saving
    confirm = input("\n💾 Add this content to MIST knowledge base? (y/n): ").strip().lower()
    
    if confirm != 'y':
        print("❌ Content not saved")
        return
    
    # Save to knowledge file
    if append_to_knowledge_file(title, clean_content, url):
        print("\n🎉 Content successfully added to knowledge base!")
        
        # Ask about uploading to vector database
        upload = input("🤖 Upload to vector database now? (y/n): ").strip().lower()
        if upload == 'y':
            print("📤 Uploading to vector database...")
            try:
                import subprocess
                subprocess.run(['python', 'upload_txt_knowledge.py'], input='2\n', text=True, check=True)
                print("✅ Vector database updated!")
            except Exception as e:
                print(f"❌ Upload error: {e}")
                print("💡 You can manually run: python upload_txt_knowledge.py")
        
        print("\n💡 Your chatbot can now answer questions about this content!")
    else:
        print("❌ Failed to save content")

if __name__ == "__main__":
    main()
