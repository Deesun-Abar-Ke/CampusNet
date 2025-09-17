"""
Knowledge Base Management Routes
Provides API endpoints for web scraping and knowledge base operations
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import logging
from services.knowledge_base_manager import get_knowledge_manager
from models import db, InstitutionalKnowledge

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create blueprint
kb_bp = Blueprint('knowledge_base', __name__, url_prefix='/api/knowledge')

@kb_bp.route('/status', methods=['GET'])
@jwt_required()
def get_knowledge_base_status():
    """Get comprehensive status of the knowledge base"""
    try:
        manager = get_knowledge_manager()
        status = manager.get_knowledge_base_status()
        
        return jsonify(status), 200
        
    except Exception as e:
        logger.error(f"Error getting knowledge base status: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to get knowledge base status'
        }), 500


@kb_bp.route('/scrape', methods=['POST'])
@jwt_required()
def scrape_single_url():
    """Scrape content from a single URL and add to knowledge base"""
    try:
        data = request.get_json()
        
        url = data.get('url', '').strip()
        category = data.get('category', 'website').strip()
        subcategory = data.get('subcategory', '').strip() or None
        
        if not url:
            return jsonify({
                'success': False,
                'error': 'URL is required'
            }), 400
        
        if not url.startswith(('http://', 'https://')):
            url = 'https://' + url
        
        manager = get_knowledge_manager()
        result = manager.scrape_url(url, category, subcategory)
        
        return jsonify(result), 200 if result['success'] else 400
        
    except Exception as e:
        logger.error(f"Error scraping URL: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to scrape URL'
        }), 500


@kb_bp.route('/scrape/bulk', methods=['POST'])
@jwt_required()
def scrape_multiple_urls():
    """Scrape content from multiple URLs"""
    try:
        data = request.get_json()
        
        urls = data.get('urls', [])
        delay = data.get('delay', 1.0)  # Default 1 second delay
        
        if not urls or not isinstance(urls, list):
            return jsonify({
                'success': False,
                'error': 'URLs array is required'
            }), 400
        
        # Validate URL format
        processed_urls = []
        for url_data in urls:
            if isinstance(url_data, str):
                url_data = {'url': url_data, 'category': 'website'}
            
            url = url_data.get('url', '').strip()
            if not url:
                continue
                
            if not url.startswith(('http://', 'https://')):
                url = 'https://' + url
                url_data['url'] = url
            
            processed_urls.append(url_data)
        
        if not processed_urls:
            return jsonify({
                'success': False,
                'error': 'No valid URLs provided'
            }), 400
        
        manager = get_knowledge_manager()
        results = manager.bulk_scrape_urls(processed_urls, delay)
        
        return jsonify({
            'success': True,
            'results': results
        }), 200
        
    except Exception as e:
        logger.error(f"Error bulk scraping URLs: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to scrape URLs'
        }), 500


@kb_bp.route('/entries', methods=['GET'])
@jwt_required()
def get_knowledge_entries():
    """Get paginated list of knowledge base entries"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        category = request.args.get('category')
        search = request.args.get('search')
        
        # Build query
        query = InstitutionalKnowledge.query
        
        if category:
            query = query.filter(InstitutionalKnowledge.category == category)
        
        if search:
            query = query.filter(
                db.or_(
                    InstitutionalKnowledge.title.ilike(f'%{search}%'),
                    InstitutionalKnowledge.content.ilike(f'%{search}%')
                )
            )
        
        # Order by most recent
        query = query.order_by(InstitutionalKnowledge.last_updated.desc())
        
        # Paginate
        pagination = query.paginate(
            page=page, 
            per_page=per_page, 
            error_out=False
        )
        
        entries_data = []
        for entry in pagination.items:
            entries_data.append({
                'id': entry.id,
                'title': entry.title,
                'category': entry.category,
                'subcategory': entry.subcategory,
                'content_type': entry.content_type,
                'source_url': entry.source_url,
                'summary': entry.summary,
                'is_processed': entry.is_processed,
                'last_updated': entry.last_updated.isoformat(),
                'version': entry.version,
                'content_length': len(entry.content) if entry.content else 0
            })
        
        return jsonify({
            'success': True,
            'entries': entries_data,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total_pages': pagination.pages,
                'total_entries': pagination.total,
                'has_next': pagination.has_next,
                'has_prev': pagination.has_prev
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting knowledge entries: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to get knowledge entries'
        }), 500


@kb_bp.route('/entries/<int:entry_id>', methods=['GET'])
@jwt_required()
def get_knowledge_entry(entry_id):
    """Get detailed information about a specific knowledge base entry"""
    try:
        entry = InstitutionalKnowledge.query.get_or_404(entry_id)
        
        return jsonify({
            'success': True,
            'entry': {
                'id': entry.id,
                'title': entry.title,
                'category': entry.category,
                'subcategory': entry.subcategory,
                'content_type': entry.content_type,
                'source_url': entry.source_url,
                'summary': entry.summary,
                'content': entry.content,
                'is_processed': entry.is_processed,
                'last_updated': entry.last_updated.isoformat(),
                'version': entry.version,
                'content_length': len(entry.content) if entry.content else 0
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting knowledge entry: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to get knowledge entry'
        }), 500


@kb_bp.route('/entries/<int:entry_id>', methods=['DELETE'])
@jwt_required()
def delete_knowledge_entry(entry_id):
    """Delete a knowledge base entry"""
    try:
        entry = InstitutionalKnowledge.query.get_or_404(entry_id)
        
        db.session.delete(entry)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Knowledge entry deleted successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting knowledge entry: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to delete knowledge entry'
        }), 500


@kb_bp.route('/cleanup/duplicates', methods=['POST'])
@jwt_required()
def remove_duplicates():
    """Remove duplicate entries from the knowledge base"""
    try:
        manager = get_knowledge_manager()
        result = manager.remove_duplicate_entries()
        
        return jsonify(result), 200 if result['success'] else 500
        
    except Exception as e:
        logger.error(f"Error removing duplicates: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to remove duplicates'
        }), 500


@kb_bp.route('/categories', methods=['GET'])
@jwt_required()
def get_categories():
    """Get all available categories in the knowledge base"""
    try:
        categories = db.session.execute(
            db.text("SELECT DISTINCT category FROM institutional_knowledge ORDER BY category")
        ).fetchall()
        
        category_list = [row[0] for row in categories]
        
        return jsonify({
            'success': True,
            'categories': category_list
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting categories: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to get categories'
        }), 500
