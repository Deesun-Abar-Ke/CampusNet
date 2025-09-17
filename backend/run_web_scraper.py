#!/usr/bin/env python3
"""
CampusNet Web Scraper - Automated Knowledge Base Builder
This script scrapes URLs from the configuration file and populates the knowledge base
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import json
import logging
from datetime import datetime
from app import app, db
from services.knowledge_base_manager import get_knowledge_manager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('web_scraping.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class CampusNetWebScraper:
    """Automated web scraper for CampusNet knowledge base"""
    
    def __init__(self):
        self.app = app
        self.db = db
        self.kb_manager = get_knowledge_manager()
        self.config_file = "knowledge_base/urls_to_scrape_complete.json"
        
    def load_urls_config(self):
        """Load URLs configuration from JSON file"""
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            urls = config.get('mist_urls', [])
            scraping_config = config.get('scraping_config', {})
            
            logger.info(f"Loaded {len(urls)} URLs from configuration")
            return urls, scraping_config
            
        except FileNotFoundError:
            logger.error(f"Configuration file {self.config_file} not found!")
            return [], {}
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in configuration file: {e}")
            return [], {}
    
    def scrape_all_urls(self):
        """Scrape all URLs from the configuration file"""
        print("🚀 CAMPUSNET WEB SCRAPER")
        print("=" * 50)
        
        urls, config = self.load_urls_config()
        
        if not urls:
            print("❌ No URLs found in configuration file")
            return False
        
        delay = config.get('delay_between_requests', 2.0)
        
        with self.app.app_context():
            print(f"📚 Starting scraping of {len(urls)} URLs...")
            print(f"⏱️  Delay between requests: {delay} seconds")
            print("-" * 50)
            
            # Use bulk scraping from knowledge base manager
            results = self.kb_manager.bulk_scrape_urls(urls, delay)
            
            # Display results
            summary = results.get('summary', {})
            print(f"\n📊 SCRAPING RESULTS:")
            print(f"   Total URLs: {summary.get('total_urls', 0)}")
            print(f"   ✅ Successful: {summary.get('successful_count', 0)}")
            print(f"   ❌ Failed: {summary.get('failed_count', 0)}")
            print(f"   📈 Success Rate: {summary.get('success_rate', 0):.1f}%")
            
            # Show successful scrapes
            if results.get('successful'):
                print(f"\n✅ SUCCESSFUL SCRAPES:")
                for result in results['successful']:
                    action = result.get('action', 'processed')
                    title = result.get('title', 'Unknown')[:50]
                    length = result.get('content_length', 0)
                    print(f"   {action.upper()}: {title}... ({length} chars)")
            
            # Show failed scrapes
            if results.get('failed'):
                print(f"\n❌ FAILED SCRAPES:")
                for result in results['failed']:
                    url = result.get('url', 'Unknown')
                    error = result.get('error', 'Unknown error')
                    print(f"   {url}: {error}")
            
            print(f"\n🎯 Scraping completed at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            
            return summary.get('success_rate', 0) > 50  # Success if >50% scraped
    
    def show_knowledge_base_status(self):
        """Display current knowledge base status"""
        print("\n📊 KNOWLEDGE BASE STATUS")
        print("=" * 50)
        
        with self.app.app_context():
            status = self.kb_manager.get_knowledge_base_status()
            
            if status.get('success'):
                print(f"📖 Total Entries: {status['total_entries']}")
                print(f"✅ Processed: {status['processed_entries']}")
                print(f"⏳ Unprocessed: {status['unprocessed_entries']}")
                
                print(f"\n📂 CATEGORIES:")
                for category, count in status.get('categories', {}).items():
                    print(f"   - {category}: {count} entries")
                
                print(f"\n🕒 RECENT ENTRIES:")
                for entry in status.get('recent_entries', [])[:5]:
                    print(f"   - {entry['title'][:60]}...")
            else:
                print(f"❌ Error: {status.get('error')}")

def main():
    """Main function"""
    print("🌐 CampusNet Knowledge Base Web Scraper")
    print("=" * 50)
    
    scraper = CampusNetWebScraper()
    
    # Show initial status
    scraper.show_knowledge_base_status()
    
    # Ask user confirmation
    print(f"\n❓ Do you want to scrape URLs from '{scraper.config_file}'? (y/n): ", end="")
    response = input().strip().lower()
    
    if response in ['y', 'yes']:
        # Perform scraping
        success = scraper.scrape_all_urls()
        
        # Show final status
        scraper.show_knowledge_base_status()
        
        if success:
            print("\n🎉 Web scraping completed successfully!")
        else:
            print("\n⚠️  Web scraping completed with some issues")
    else:
        print("\n👋 Scraping cancelled by user")

if __name__ == "__main__":
    main()
