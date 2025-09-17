"""
Web Search Service for RAG Fallback
Uses Serper API to search web when knowledge base lacks information
"""

import os
import json
import requests
import logging
from typing import Dict, List, Optional, Any

logger = logging.getLogger(__name__)

class WebSearchService:
    """Service for web search using Serper API as RAG fallback"""
    
    def __init__(self):
        self.serper_api_key = os.getenv('SERPER_API_KEY', '980824be1e3ab4fb3c1ece3d275e5f7969daa950')
        self.base_url = "https://google.serper.dev/search"
        
        if not self.serper_api_key or self.serper_api_key == 'your-serper-api-key-here':
            logger.warning("SERPER_API_KEY not configured properly. Web search fallback disabled.")
    
    def search_web(self, query: str, num_results: int = 5) -> List[Dict[str, Any]]:
        """Search web using Serper API"""
        try:
            if not self.serper_api_key or self.serper_api_key == 'your-serper-api-key-here':
                logger.warning("Web search skipped - no valid API key")
                return []
            
            headers = {
                'X-API-KEY': self.serper_api_key,
                'Content-Type': 'application/json'
            }
            
            # Enhance query for MIST-related searches
            enhanced_query = self._enhance_query(query)
            
            payload = {
                'q': enhanced_query,
                'num': num_results,
                'gl': 'bd',  # Bangladesh results
                'hl': 'en',  # English language
            }
            
            logger.info(f"Searching web for: {enhanced_query}")
            
            response = requests.post(
                self.base_url,
                headers=headers,
                json=payload,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"Serper API error {response.status_code}: {response.text}")
                return []
            
            data = response.json()
            results = []
            
            # Process organic results
            for item in data.get('organic', [])[:num_results]:
                results.append({
                    'title': item.get('title', ''),
                    'snippet': item.get('snippet', ''),
                    'link': item.get('link', ''),
                    'source': 'web_search'
                })
            
            # Add knowledge graph if available
            if 'knowledgeGraph' in data:
                kg = data['knowledgeGraph']
                results.insert(0, {
                    'title': kg.get('title', ''),
                    'snippet': kg.get('description', ''),
                    'link': kg.get('website', ''),
                    'source': 'knowledge_graph'
                })
            
            logger.info(f"Found {len(results)} web search results")
            return results
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Web search request failed: {e}")
            return []
        except Exception as e:
            logger.error(f"Web search error: {e}")
            return []
    
    def _enhance_query(self, query: str) -> str:
        """Enhance query for better MIST-related results"""
        query_lower = query.lower()
        
        # Add MIST context if not present
        mist_terms = ['mist', 'military institute science technology', 'bangladesh']
        has_mist_context = any(term in query_lower for term in mist_terms)
        
        if not has_mist_context:
            # Check if it's about academic topics that should include MIST
            academic_terms = [
                'admission', 'course', 'department', 'faculty', 'program',
                'computer science', 'electrical', 'mechanical', 'civil',
                'engineering', 'university', 'college', 'student'
            ]
            
            if any(term in query_lower for term in academic_terms):
                return f"{query} MIST Bangladesh"
        
        return query
    
    def get_context_from_search(self, query: str, max_length: int = 2000) -> Optional[str]:
        """Get formatted context from web search results"""
        try:
            results = self.search_web(query, num_results=3)
            
            if not results:
                return None
            
            context_parts = []
            current_length = 0
            
            for i, result in enumerate(results):
                title = result.get('title', '')
                snippet = result.get('snippet', '')
                source = result.get('source', 'web')
                
                if not snippet:
                    continue
                
                # Format: [Source] Title: Snippet
                formatted_result = f"[Web Search - {source.title()}] {title}: {snippet}"
                
                if current_length + len(formatted_result) > max_length:
                    if current_length == 0:  # First result too long
                        available_space = max_length - len(f"[Web Search - {source.title()}] {title}: ")
                        truncated_snippet = snippet[:available_space] + "..."
                        context_parts.append(f"[Web Search - {source.title()}] {title}: {truncated_snippet}")
                    break
                
                context_parts.append(formatted_result)
                current_length += len(formatted_result) + 2
            
            if context_parts:
                context = "\n\n".join(context_parts)
                logger.info(f"Generated web search context: {len(context)} characters from {len(context_parts)} results")
                return context
            
            return None
            
        except Exception as e:
            logger.error(f"Error generating web search context: {e}")
            return None
    
    def is_available(self) -> bool:
        """Check if web search service is available"""
        return bool(self.serper_api_key and self.serper_api_key != 'your-serper-api-key-here')

# Global service instance
_web_search_service = None

def get_web_search_service():
    """Get or create web search service instance"""
    global _web_search_service
    if _web_search_service is None:
        _web_search_service = WebSearchService()
    return _web_search_service
