"""
Enhanced Knowledge Base Management System
Provides web scraping functionality and knowledge base updates
"""

import requests
from bs4 import BeautifulSoup
import logging
from urllib.parse import urljoin, urlparse
from datetime import datetime
import time
import hashlib
from typing import Dict, List, Optional, Any
from models import db, InstitutionalKnowledge
from services.rag_service import get_rag_service
import sqlalchemy
from sqlalchemy import text

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class KnowledgeBaseManager:
    """Enhanced Knowledge Base Manager with web scraping capabilities"""
    
    def __init__(self):
        self.rag_service = get_rag_service()
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
    
    def scrape_url(self, url: str, category: str = 'website', subcategory: str = None) -> Dict[str, Any]:
        """
        Scrape content from a URL and add it to the knowledge base
        If URL already exists, it updates the existing entry
        """
        try:
            logger.info(f"Starting to scrape URL: {url}")
            
            # Generate content hash for duplicate detection
            url_hash = hashlib.md5(url.encode()).hexdigest()
            
            # Check if URL already exists
            existing_entry = InstitutionalKnowledge.query.filter_by(
                source_url=url
            ).first()
            
            # Fetch content
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            # Parse content
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract title
            title = soup.find('title')
            title_text = title.get_text().strip() if title else f"Content from {urlparse(url).netloc}"
            
            # Remove script and style elements
            for script in soup(["script", "style", "nav", "footer", "header"]):
                script.decompose()
            
            # Extract main content
            content = soup.get_text()
            
            # Clean up content
            lines = (line.strip() for line in content.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            content = ' '.join(chunk for chunk in chunks if chunk)
            
            # Limit content length
            content = content[:50000]  # Limit to 50k characters
            
            # Generate summary (first 500 characters)
            summary = content[:500] + "..." if len(content) > 500 else content
            
            if existing_entry:
                # Update existing entry
                logger.info(f"Updating existing knowledge base entry for URL: {url}")
                existing_entry.title = title_text
                existing_entry.content = content
                existing_entry.summary = summary
                existing_entry.category = category
                existing_entry.subcategory = subcategory
                existing_entry.last_updated = datetime.utcnow()
                existing_entry.version = self._increment_version(existing_entry.version)
                existing_entry.is_processed = False  # Mark for reprocessing
                
                knowledge_entry = existing_entry
                action = "updated"
            else:
                # Create new entry
                logger.info(f"Creating new knowledge base entry for URL: {url}")
                knowledge_entry = InstitutionalKnowledge(
                    title=title_text,
                    content_type='website',
                    source_url=url,
                    content=content,
                    summary=summary,
                    category=category,
                    subcategory=subcategory or 'general',
                    is_processed=False,
                    last_updated=datetime.utcnow(),
                    version='1.0'
                )
                db.session.add(knowledge_entry)
                action = "created"
            
            # Commit the database changes
            db.session.commit()
            
            # Process with RAG system
            try:
                logger.info("Processing content with RAG system...")
                success = self.rag_service.process_institutional_knowledge(
                    title=title_text,
                    content=content,
                    source_url=url,
                    category=category
                )
                
                if success:
                    knowledge_entry.is_processed = True
                    db.session.commit()
                    logger.info("RAG processing completed successfully")
                else:
                    logger.warning("RAG processing failed, but content saved to database")
                    
            except Exception as e:
                logger.error(f"RAG processing error: {e}")
                # Don't fail the whole operation if RAG processing fails
            
            return {
                'success': True,
                'action': action,
                'entry_id': knowledge_entry.id,
                'title': title_text,
                'content_length': len(content),
                'url': url,
                'category': category,
                'processed_by_rag': knowledge_entry.is_processed
            }
            
        except requests.RequestException as e:
            logger.error(f"HTTP error scraping {url}: {e}")
            return {
                'success': False,
                'error': f"HTTP error: {str(e)}",
                'url': url
            }
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error scraping {url}: {e}")
            return {
                'success': False,
                'error': f"Scraping error: {str(e)}",
                'url': url
            }
    
    def bulk_scrape_urls(self, urls: List[Dict[str, str]], delay: float = 1.0) -> Dict[str, Any]:
        """
        Scrape multiple URLs with delay to avoid overwhelming servers
        urls: List of dictionaries with 'url', 'category', and optional 'subcategory' keys
        """
        results = {
            'successful': [],
            'failed': [],
            'total_processed': 0,
            'summary': {}
        }
        
        for i, url_data in enumerate(urls):
            url = url_data.get('url')
            category = url_data.get('category', 'website')
            subcategory = url_data.get('subcategory')
            
            logger.info(f"Processing URL {i+1}/{len(urls)}: {url}")
            
            result = self.scrape_url(url, category, subcategory)
            results['total_processed'] += 1
            
            if result['success']:
                results['successful'].append(result)
            else:
                results['failed'].append(result)
            
            # Delay between requests
            if i < len(urls) - 1:  # Don't delay after the last URL
                time.sleep(delay)
        
        results['summary'] = {
            'total_urls': len(urls),
            'successful_count': len(results['successful']),
            'failed_count': len(results['failed']),
            'success_rate': len(results['successful']) / len(urls) * 100 if urls else 0
        }
        
        logger.info(f"Bulk scraping completed: {results['summary']}")
        return results
    
    def get_knowledge_base_status(self) -> Dict[str, Any]:
        """Get comprehensive status of the knowledge base"""
        try:
            # Get counts by category
            category_counts = db.session.execute(
                text("SELECT category, COUNT(*) as count FROM institutional_knowledge GROUP BY category")
            ).fetchall()
            
            # Get processing status
            processing_status = db.session.execute(
                text("""
                    SELECT 
                        COUNT(*) as total_entries,
                        COUNT(CASE WHEN is_processed = true THEN 1 END) as processed,
                        COUNT(CASE WHEN is_processed = false THEN 1 END) as unprocessed
                    FROM institutional_knowledge
                """)
            ).fetchone()
            
            # Get recent additions
            recent_entries = InstitutionalKnowledge.query.order_by(
                InstitutionalKnowledge.last_updated.desc()
            ).limit(5).all()
            
            return {
                'success': True,
                'total_entries': processing_status.total_entries,
                'processed_entries': processing_status.processed,
                'unprocessed_entries': processing_status.unprocessed,
                'categories': {row.category: row.count for row in category_counts},
                'recent_entries': [
                    {
                        'id': entry.id,
                        'title': entry.title,
                        'category': entry.category,
                        'last_updated': entry.last_updated.isoformat(),
                        'is_processed': entry.is_processed,
                        'source_url': entry.source_url
                    }
                    for entry in recent_entries
                ]
            }
            
        except Exception as e:
            logger.error(f"Error getting knowledge base status: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def remove_duplicate_entries(self) -> Dict[str, Any]:
        """Remove duplicate entries based on source URL and title"""
        try:
            # Find duplicates by source_url
            url_duplicates = db.session.execute(
                text("""
                    SELECT source_url, COUNT(*) as count, array_agg(id) as ids
                    FROM institutional_knowledge 
                    WHERE source_url IS NOT NULL 
                    GROUP BY source_url 
                    HAVING COUNT(*) > 1
                """)
            ).fetchall()
            
            removed_count = 0
            
            for duplicate in url_duplicates:
                ids = duplicate.ids
                # Keep the most recent one, remove others
                ids_to_remove = ids[:-1]  # All except the last one
                
                for entry_id in ids_to_remove:
                    entry = InstitutionalKnowledge.query.get(entry_id)
                    if entry:
                        db.session.delete(entry)
                        removed_count += 1
            
            db.session.commit()
            
            return {
                'success': True,
                'removed_duplicates': removed_count,
                'duplicate_groups_found': len(url_duplicates)
            }
            
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error removing duplicates: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def _increment_version(self, current_version: str) -> str:
        """Increment version number"""
        try:
            parts = current_version.split('.')
            if len(parts) == 2:
                major, minor = parts
                return f"{major}.{int(minor) + 1}"
            else:
                return f"{current_version}.1"
        except:
            return "1.1"
    
    def add_knowledge_entry(self, title: str, content: str, category: str = 'manual', 
                          content_type: str = 'text', source_url: Optional[str] = None) -> Dict[str, Any]:
        """Add a knowledge entry directly to the database"""
        try:
            # Generate content hash for duplicate detection
            content_hash = hashlib.md5(content.encode()).hexdigest()
            
            # Check for duplicates by title
            existing_entry = InstitutionalKnowledge.query.filter_by(
                title=title
            ).first()
            
            if existing_entry:
                return {
                    'success': False,
                    'message': 'Duplicate title detected',
                    'knowledge_id': existing_entry.id
                }
            
            # Create new entry
            knowledge_entry = InstitutionalKnowledge()
            knowledge_entry.title = title
            knowledge_entry.content = content
            knowledge_entry.category = category
            knowledge_entry.subcategory = content_type
            knowledge_entry.source_url = source_url or f"manual://{title}"
            knowledge_entry.content_type = content_type
            knowledge_entry.content_hash = content_hash
            knowledge_entry.version = "1.0"
            knowledge_entry.is_processed = False
            
            # Save to database
            db.session.add(knowledge_entry)
            db.session.commit()
            
            logger.info(f"Added knowledge entry: {title}")
            
            return {
                'success': True,
                'message': 'Knowledge entry added successfully',
                'knowledge_id': knowledge_entry.id,
                'title': title,
                'category': category
            }
            
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error adding knowledge entry: {e}")
            return {
                'success': False,
                'message': f'Error adding knowledge entry: {str(e)}',
                'knowledge_id': None
            }

# Global instance
knowledge_manager = None

def get_knowledge_manager():
    """Get or create knowledge base manager instance"""
    global knowledge_manager
    if knowledge_manager is None:
        knowledge_manager = KnowledgeBaseManager()
    return knowledge_manager
