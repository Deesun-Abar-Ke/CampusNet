from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import time
import json
from datetime import datetime
import logging
from sqlalchemy import func, and_

from models import db, ChatSession, ChatMessage, Users
from services.enhanced_chatbot_service import get_enhanced_chatbot_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize services - delay until needed
enhanced_chatbot_service = None

def get_enhanced_chatbot():
    """Get or initialize Enhanced Chatbot service"""
    global enhanced_chatbot_service
    if enhanced_chatbot_service is None:
        enhanced_chatbot_service = get_enhanced_chatbot_service()
    return enhanced_chatbot_service

# Create blueprint
chat_bp = Blueprint('chat', __name__, url_prefix='/api/chat')

@chat_bp.route('/sessions', methods=['GET'])
@jwt_required()
def get_user_sessions():
    """Get all chat sessions for the current user with optimized queries"""
    try:
        user_id = get_jwt_identity()
        
        # Optimized query using a single query with aggregates
        sessions_with_stats = db.session.query(
            ChatSession,
            func.count(ChatMessage.id).label('message_count'),
            func.max(ChatMessage.timestamp).label('last_message_time')
        ).outerjoin(
            ChatMessage, ChatSession.id == ChatMessage.session_id
        ).filter(
            ChatSession.user_id == user_id,
            ChatSession.is_active == True
        ).group_by(ChatSession.id).order_by(ChatSession.updated_at.desc()).all()
        
        # Get session IDs for last message lookup
        session_ids = [session.id for session, _, _ in sessions_with_stats if _ > 0]
        
        # Batch query for last messages
        last_messages = {}
        if session_ids:
            last_message_subquery = db.session.query(
                ChatMessage.session_id,
                func.max(ChatMessage.timestamp).label('max_timestamp')
            ).filter(
                ChatMessage.session_id.in_(session_ids)
            ).group_by(ChatMessage.session_id).subquery()
            
            last_msgs = db.session.query(ChatMessage).join(
                last_message_subquery,
                and_(
                    ChatMessage.session_id == last_message_subquery.c.session_id,
                    ChatMessage.timestamp == last_message_subquery.c.max_timestamp
                )
            ).all()
            
            last_messages = {msg.session_id: msg for msg in last_msgs}
        
        sessions_data = []
        for session, message_count, last_message_time in sessions_with_stats:
            last_message = last_messages.get(session.id)
            
            sessions_data.append({
                'id': session.id,
                'name': session.session_name,
                'created_at': session.created_at.isoformat(),
                'updated_at': session.updated_at.isoformat(),
                'message_count': message_count or 0,
                'last_message': {
                    'content': last_message.content[:100] + '...' if last_message and len(last_message.content) > 100 else (last_message.content if last_message else 'No messages yet'),
                    'ai_response': last_message.ai_response[:100] + '...' if last_message and last_message.ai_response and len(last_message.ai_response) > 100 else (last_message.ai_response if last_message else None),
                    'timestamp': last_message.timestamp.isoformat() if last_message else None
                } if last_message else {'content': 'No messages yet', 'ai_response': None, 'timestamp': None},
                'has_messages': (message_count or 0) > 0
            })
        
        return jsonify({
            'success': True,
            'sessions': sessions_data,
            'total_sessions': len(sessions_data)
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching sessions: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to fetch sessions'
        }), 500

@chat_bp.route('/sessions', methods=['POST'])
@jwt_required()
def create_new_session():
    """Create a new chat session"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        session_name = data.get('name', f'New Chat {datetime.now().strftime("%Y-%m-%d %H:%M")}')
        
        # Create new session
        session = ChatSession(
            user_id=user_id,
            session_name=session_name,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        db.session.add(session)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'session': {
                'id': session.id,
                'name': session.session_name,
                'created_at': session.created_at.isoformat(),
                'updated_at': session.updated_at.isoformat(),
                'message_count': 0
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating session: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to create session'
        }), 500

@chat_bp.route('/send', methods=['POST'])
@jwt_required()
def send_message():
    """Send a message and get AI response using enhanced 4-step pipeline"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        message_content = data.get('message', '').strip()
        session_id = data.get('session_id')
        
        if not message_content:
            return jsonify({
                'success': False,
                'error': 'Message content is required'
            }), 400
        
        # Verify session exists and belongs to user
        session = ChatSession.query.filter_by(
            id=session_id,
            user_id=user_id
        ).first()
        
        if not session:
            return jsonify({
                'success': False,
                'error': 'Session not found'
            }), 404
        
        # Use Enhanced Chatbot Service with 4-step pipeline
        start_time = time.time()
        
        result = get_enhanced_chatbot().process_chat_message(
            user_message=message_content,
            user_id=user_id,
            session_id=session_id
        )
        
        processing_time = time.time() - start_time
        
        # Extract response and metadata
        ai_response = result.get('response', 'I apologize, but I encountered an error processing your request.')
        metadata = result.get('metadata', {})
        
        if not result.get('success', False):
            logger.error(f"Enhanced chatbot error: {result.get('error', 'Unknown error')}")
        
        # Log processing details
        logger.info(f"Enhanced pipeline completed in {processing_time:.2f}s with steps: {metadata.get('processing_steps', [])}")
        
        # Save message to database
        message = ChatMessage(
            session_id=session_id,
            user_id=user_id,
            message_type='text',
            content=message_content,
            ai_response=ai_response,
            context_used=str(metadata)[:500] if metadata else None,  # Store metadata as context
            processing_time=processing_time,
            timestamp=datetime.utcnow()
        )
        
        db.session.add(message)
        
        # Update session timestamp
        session.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': {
                'id': message.id,
                'content': message.content,
                'ai_response': message.ai_response,
                'timestamp': message.timestamp.isoformat(),
                'processing_time': processing_time,
                'enhanced_metadata': metadata
            }
        }), 200
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error sending message: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to send message'
        }), 500


@chat_bp.route('/sessions/<int:session_id>/messages', methods=['GET'])
@jwt_required()
def get_session_messages(session_id):
    """Get the last 10 conversation messages for a specific session to provide context"""
    try:
        user_id = get_jwt_identity()
        
        # Verify session belongs to user
        session = ChatSession.query.filter_by(
            id=session_id,
            user_id=user_id,
            is_active=True
        ).first()
        
        if not session:
            return jsonify({
                'success': False,
                'error': 'Session not found or access denied'
            }), 404
        
        # Get the last 10 messages for context
        messages = ChatMessage.query.filter_by(
            session_id=session_id
        ).order_by(ChatMessage.timestamp.desc()).limit(10).all()
        
        # Reverse to get chronological order
        messages = list(reversed(messages))
        
        messages_data = []
        for message in messages:
            messages_data.append({
                'id': message.id,
                'content': message.content,
                'ai_response': message.ai_response,
                'timestamp': message.timestamp.isoformat(),
                'processing_time': message.processing_time,
                'context_used': message.context_used
            })
        
        return jsonify({
            'success': True,
            'session_id': session_id,
            'session_name': session.session_name,
            'messages': messages_data,
            'message_count': len(messages_data)
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting session messages: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to retrieve session messages'
        }), 500


@chat_bp.route('/sessions/<int:session_id>', methods=['DELETE'])
@jwt_required()
def delete_session(session_id):
    """Delete a chat session and all its messages"""
    try:
        user_id = get_jwt_identity()
        
        # Verify session belongs to user
        session = ChatSession.query.filter_by(
            id=session_id,
            user_id=user_id
        ).first()
        
        if not session:
            return jsonify({
                'success': False,
                'error': 'Session not found or access denied'
            }), 404
        
        # Mark session as inactive instead of hard delete (for data integrity)
        session.is_active = False
        session.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Session deleted successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting session: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to delete session'
        }), 500


@chat_bp.route('/sessions/<int:session_id>/rename', methods=['PATCH'])
@jwt_required()
def rename_session(session_id):
    """Rename a chat session"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        new_name = data.get('session_name', '').strip()
        if not new_name:
            return jsonify({
                'success': False,
                'error': 'Session name is required'
            }), 400
        
        # Verify session belongs to user
        session = ChatSession.query.filter_by(
            id=session_id,
            user_id=user_id,
            is_active=True
        ).first()
        
        if not session:
            return jsonify({
                'success': False,
                'error': 'Session not found or access denied'
            }), 404
        
        session.session_name = new_name
        session.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Session renamed successfully',
            'session_name': new_name
        }), 200
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error renaming session: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to rename session'
        }), 500

@chat_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_chat_stats():
    """Get chat statistics for the current user"""
    try:
        user_id = get_jwt_identity()
        
        total_sessions = ChatSession.query.filter_by(
            user_id=user_id,
            is_active=True
        ).count()
        
        total_messages = ChatMessage.query.filter_by(user_id=user_id).count()
        
        return jsonify({
            'success': True,
            'stats': {
                'total_sessions': total_sessions,
                'total_messages': total_messages
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching stats: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to fetch statistics'
        }), 500
