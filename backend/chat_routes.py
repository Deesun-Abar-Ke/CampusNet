from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import time
import json
from datetime import datetime
import logging

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
    """Get all chat sessions for the current user with enhanced details"""
    try:
        user_id = get_jwt_identity()
        
        sessions = ChatSession.query.filter_by(
            user_id=user_id, 
            is_active=True
        ).order_by(ChatSession.updated_at.desc()).all()
        
        sessions_data = []
        for session in sessions:
            # Get last message for preview
            last_message = ChatMessage.query.filter_by(
                session_id=session.id
            ).order_by(ChatMessage.timestamp.desc()).first()
            
            # Get message count efficiently
            message_count = ChatMessage.query.filter_by(session_id=session.id).count()
            
            sessions_data.append({
                'id': session.id,
                'name': session.session_name,
                'created_at': session.created_at.isoformat(),
                'updated_at': session.updated_at.isoformat(),
                'message_count': message_count,
                'last_message': {
                    'content': last_message.content[:100] + '...' if last_message and len(last_message.content) > 100 else (last_message.content if last_message else 'No messages yet'),
                    'ai_response': last_message.ai_response[:100] + '...' if last_message and last_message.ai_response and len(last_message.ai_response) > 100 else (last_message.ai_response if last_message else None),
                    'timestamp': last_message.timestamp.isoformat() if last_message else None
                } if last_message else {'content': 'No messages yet', 'ai_response': None, 'timestamp': None},
                'has_messages': message_count > 0
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

@chat_bp.route('/sessions/<int:session_id>/messages', methods=['GET'])
@jwt_required()
def get_session_messages(session_id):
    """Get all messages for a specific session"""
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
                'error': 'Session not found'
            }), 404
        
        messages = ChatMessage.query.filter_by(
            session_id=session_id
        ).order_by(ChatMessage.timestamp.asc()).all()
        
        messages_data = []
        for msg in messages:
            messages_data.append({
                'id': msg.id,
                'content': msg.content,
                'ai_response': msg.ai_response,
                'timestamp': msg.timestamp.isoformat(),
                'message_type': msg.message_type,
                'processing_time': msg.processing_time
            })
        
        return jsonify({
            'success': True,
            'messages': messages_data,
            'session_name': session.session_name
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching messages: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to fetch messages'
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

@chat_bp.route('/sessions/<int:session_id>', methods=['DELETE'])
@jwt_required()
def delete_session(session_id):
    """Delete a chat session"""
    try:
        user_id = get_jwt_identity()
        
        session = ChatSession.query.filter_by(
            id=session_id,
            user_id=user_id
        ).first()
        
        if not session:
            return jsonify({
                'success': False,
                'error': 'Session not found'
            }), 404
        
        # Delete all messages in the session
        ChatMessage.query.filter_by(session_id=session_id).delete()
        
        # Delete the session
        db.session.delete(session)
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

@chat_bp.route('/sessions/<int:session_id>/rename', methods=['PUT'])
@jwt_required()
def rename_session(session_id):
    """Rename a chat session"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        new_name = data.get('name', '').strip()
        if not new_name:
            return jsonify({
                'success': False,
                'error': 'Session name is required'
            }), 400
        
        session = ChatSession.query.filter_by(
            id=session_id,
            user_id=user_id
        ).first()
        
        if not session:
            return jsonify({
                'success': False,
                'error': 'Session not found'
            }), 404
        
        session.session_name = new_name
        session.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'session': {
                'id': session.id,
                'name': session.session_name,
                'updated_at': session.updated_at.isoformat()
            }
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
