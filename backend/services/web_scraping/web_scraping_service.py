"""
Web Scraping Service for MIST Knowledge Base
Uses Serper API to extract content from web pages and add to knowledge base
"""

import os
import requests
import re
from datetime import datetime
from typing import Optional, Dict, Any
from bs4 import BeautifulSoup
import logging

logger = logging.getLogger(__name__)

class WebScrapingService:
    def __init__(self):
        self.serper_api_key = os.getenv('SERPER_API_KEY')
        self.knowledge_file = "mist_knowledge_base/mist_complete_info.txt"
        
        if not self.serper_api_key:
            logger.warning("SERPER_API_KEY not found. Web scraping will use basic requests.")
    
    def scrape_with_serper(self, url: str) -> Optional[Dict[str, Any]]:
        """Use Serper API to scrape web page content"""
        if not self.serper_api_key:
            return None
        
        try:
            headers = {
                'X-API-KEY': self.serper_api_key,
                'Content-Type': 'application/json'
            }
            
            payload = {
                'url': url,
                'format': 'json'
            }
            
            response = requests.post(
                'https://scrape.serper.dev',
                headers=headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Serper API error {response.status_code}: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error using Serper API: {e}")
            return None
    
    def scrape_with_requests(self, url: str) -> Optional[str]:
        """Fallback scraping using requests and BeautifulSoup"""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
            
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Remove script and style elements
            for script in soup(["script", "style"]):
                script.decompose()
            
            # Extract text content
            text = soup.get_text()
            
            # Clean up text
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            text = '\n'.join(chunk for chunk in chunks if chunk)
            
            return text
            
        except Exception as e:
            logger.error(f"Error scraping with requests: {e}")
            return None
    
    def clean_extracted_text(self, text: str) -> str:
        """Clean and format extracted text"""
        if not text:
            return ""
        
        # Remove excessive whitespace
        text = re.sub(r'\n\s*\n', '\n\n', text)
        text = re.sub(r' +', ' ', text)
        
        # Remove common website elements
        unwanted_patterns = [
            r'Cookie Policy.*?Accept',
            r'Privacy Policy.*?Terms',
            r'Subscribe.*?Newsletter',
            r'Follow us.*?Social',
            r'Copyright.*?\d{4}',
            r'All rights reserved',
            r'Back to top',
            r'Skip to.*?content'
        ]
        
        for pattern in unwanted_patterns:
            text = re.sub(pattern, '', text, flags=re.IGNORECASE | re.DOTALL)
        
        # Limit length to avoid overwhelming the knowledge base
        if len(text) > 10000:
            text = text[:10000] + "\n\n[Content truncated for brevity]"
        
        return text.strip()
    
    def extract_page_info(self, url: str) -> Optional[Dict[str, str]]:
        """Extract information from a web page"""
        print(f"🌐 Scraping content from: {url}")
        
        # Try Serper API first
        serper_result = self.scrape_with_serper(url)
        
        if serper_result:
            print("✅ Using Serper API for extraction")
            content = serper_result.get('text', '')
            title = serper_result.get('title', 'Web Page Content')
        else:
            print("⚠️  Serper API not available, using fallback method")
            content = self.scrape_with_requests(url)
            if not content:
                return None
            
            # Extract title from URL or content
            title = url.split('/')[-1].replace('-', ' ').replace('_', ' ').title()
            if not title or len(title) < 5:
                title = "Web Page Content"
        
        # Clean the extracted content
        cleaned_content = self.clean_extracted_text(content)
        
        if not cleaned_content or len(cleaned_content) < 100:
            print("❌ Insufficient content extracted from the page")
            return None
        
        return {
            'title': title,
            'content': cleaned_content,
            'url': url,
            'scraped_at': datetime.now().isoformat()
        }
    
    def append_to_knowledge_base(self, page_info: Dict[str, str]) -> bool:
        """Append scraped content to the MIST knowledge base file"""
        try:
            # Create formatted content
            formatted_content = f"""

{'='*80}
SOURCE: {page_info['title']}
URL: {page_info['url']}
SCRAPED: {page_info['scraped_at']}
{'='*80}

{page_info['content']}

"""
            
            # Append to knowledge base file
            with open(self.knowledge_file, 'a', encoding='utf-8') as f:
                f.write(formatted_content)
            
            print(f"✅ Content appended to {self.knowledge_file}")
            print(f"📊 Added {len(page_info['content'])} characters")
            
            return True
            
        except Exception as e:
            logger.error(f"Error appending to knowledge base: {e}")
            print(f"❌ Error saving content: {e}")
            return False
    
    def scrape_and_save(self, url: str) -> bool:
        """Complete workflow: scrape URL and save to knowledge base"""
        print(f"🚀 Starting web scraping for: {url}")
        print("-" * 60)
        
        # Extract page information
        page_info = self.extract_page_info(url)
        
        if not page_info:
            print("❌ Failed to extract content from the page")
            return False
        
        print(f"📝 Extracted: {page_info['title']}")
        print(f"📊 Content length: {len(page_info['content'])} characters")
        
        # Save to knowledge base
        success = self.append_to_knowledge_base(page_info)
        
        if success:
            print("\n🎉 Successfully added web content to MIST knowledge base!")
            print(f"💡 Remember to run 'python upload_txt_knowledge.py' to update the vector database")
        
        return success

def main():
    """Interactive web scraping utility"""
    scraper = WebScrapingService()
    
    print("🌐 MIST Web Scraping Utility")
    print("=" * 50)
    print("This tool scrapes web pages and adds content to your MIST knowledge base.")
    print()
    
    while True:
        url = input("🔗 Enter a URL to scrape (or 'quit' to exit): ").strip()
        
        if url.lower() in ['quit', 'exit', 'q']:
            break
        
        if not url.startswith(('http://', 'https://')):
            print("❌ Please enter a valid URL starting with http:// or https://")
            continue
        
        try:
            success = scraper.scrape_and_save(url)
            
            if success:
                print("\n" + "="*60)
                
                # Ask if user wants to upload to vector database
                upload = input("🤖 Upload to vector database now? (y/n): ").strip().lower()
                if upload == 'y':
                    print("📤 Uploading to vector database...")
                    try:
                        from upload_txt_knowledge import upload_txt_knowledge
                        upload_txt_knowledge()
                    except Exception as e:
                        print(f"❌ Upload error: {e}")
                        print("💡 You can manually run: python upload_txt_knowledge.py")
                
                print("\n" + "="*60)
            
        except Exception as e:
            print(f"❌ Error processing URL: {e}")
        
        print()

if __name__ == "__main__":
    main()
