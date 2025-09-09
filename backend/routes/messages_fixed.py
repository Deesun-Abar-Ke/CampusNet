from datetime import datetime
import json
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Users, Conversation, ConversationParticipant, Message, MessageRead
from sqlalchemy import or_, and_, desc, func
from sqlalchemy.orm import joinedload

messages_bp = Blueprint('messages', __name__, url_prefix='/api/messages')

@messages_bp.route('/conversations', methods=['GET'])
@jwt_required()
def get_conversations():
    """Get all conversations for the current user"""
    try:
        user_id = get_jwt_identity()
        
        # Get conversations where user is a participant
        conversations = db.session.query(Conversation).join(
            ConversationParticipant
        ).filter(
            ConversationParticipant.user_id == user_id
        ).options(
            joinedload(Conversation.participants).joinedload(ConversationParticipant.user),
            joinedload(Conversation.messages).joinedload(Message.sender)
        ).order_by(desc(Conversation.updated_at)).all()
        
        result = []
        for conv in conversations:
            # Get last message
            last_message = conv.messages[-1] if conv.messages else None
            
            # Get unread count for this user
            unread_count = 0
            if last_message:
                unread_messages = db.session.query(Message).filter(
                    Message.conversation_id == conv.id,
                    Message.sender_id != user_id,
                    ~Message.id.in_(
                        db.session.query(MessageRead.message_id).filter(
                            MessageRead.user_id == user_id
                        )
                    )
                ).count()
                unread_count = unread_messages
            
            # Format conversation data
            conv_data = {
                'id': conv.id,
                'name': conv.name,
                'type': conv.type,
                'avatar': conv.avatar or '👥',
                'created_at': conv.created_at.isoformat(),
                'updated_at': conv.updated_at.isoformat(),
                'course_folder': conv.course_folder,
                'unread_count': unread_count,
                'last_message': None,
                'participants': []
            }
            
            # Add last message info
            if last_message:
                conv_data['last_message'] = {
                    'id': last_message.id,
                    'content': last_message.content,
                    'sender_name': last_message.sender.name,
                    'sent_at': last_message.sent_at.isoformat(),
                    'is_me': last_message.sender_id == user_id
                }
            
            # Add participants info
            for participant in conv.participants:
                conv_data['participants'].append({
                    'id': participant.user.id,
                    'name': participant.user.name,
                    'email': participant.user.email,
                    'department': participant.user.department,
                    'level': participant.user.level,
                    'session': participant.user.session,
                    'avatar': participant.user.avatar or '👤',
                    'role': participant.role,
                    'joined_at': participant.joined_at.isoformat()
                })
            
            # Set member count
            conv_data['member_count'] = len(conv.participants)
            
            result.append(conv_data)
        
        return jsonify({
            'success': True,
            'conversations': result
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching conversations: {str(e)}'
        }), 500

@messages_bp.route('/conversations', methods=['POST'])
@jwt_required()
def create_conversation():
    """Create a new conversation (individual or group)"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        conv_type = data.get('type', 'individual')
        participant_ids = data.get('participant_ids', [])
        name = data.get('name')
        avatar = data.get('avatar')
        course_folder = data.get('course_folder')
        
        if not participant_ids:
            return jsonify({
                'success': False,
                'message': 'Participant IDs are required'
            }), 400
        
        # For individual chats, check if conversation already exists
        if conv_type == 'individual':
            if len(participant_ids) != 1:
                return jsonify({
                    'success': False,
                    'message': 'Individual chat requires exactly one other participant'
                }), 400
            
            other_user_id = participant_ids[0]
            existing_conv = db.session.query(Conversation).join(
                ConversationParticipant, Conversation.id == ConversationParticipant.conversation_id
            ).filter(
                Conversation.type == 'individual'
            ).group_by(Conversation.id).having(
                func.count(ConversationParticipant.user_id) == 2
            ).filter(
                Conversation.id.in_(
                    db.session.query(ConversationParticipant.conversation_id).filter(
                        ConversationParticipant.user_id == user_id
                    )
                )
            ).filter(
                Conversation.id.in_(
                    db.session.query(ConversationParticipant.conversation_id).filter(
                        ConversationParticipant.user_id == other_user_id
                    )
                )
            ).first()
            
            if existing_conv:
                return jsonify({
                    'success': True,
                    'conversation_id': existing_conv.id,
                    'message': 'Conversation already exists'
                }), 200
        
        # Create new conversation
        conversation = Conversation(
            name=name,
            type=conv_type,
            created_by=user_id,
            avatar=avatar,
            course_folder=course_folder
        )
        
        db.session.add(conversation)
        db.session.flush()  # Get the conversation ID
        
        # Add creator as admin (for groups) or member (for individual)
        creator_role = 'admin' if conv_type == 'group' else 'member'
        creator_participant = ConversationParticipant(
            conversation_id=conversation.id,
            user_id=user_id,
            role=creator_role
        )
        db.session.add(creator_participant)
        
        # Add other participants
        for participant_id in participant_ids:
            if participant_id != user_id:
                participant = ConversationParticipant(
                    conversation_id=conversation.id,
                    user_id=participant_id,
                    role='member'
                )
                db.session.add(participant)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'conversation_id': conversation.id,
            'message': 'Conversation created successfully'
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error creating conversation: {str(e)}'
        }), 500

@messages_bp.route('/conversations/<int:conversation_id>/messages', methods=['GET'])
@jwt_required()
def get_messages(conversation_id):
    """Get messages for a specific conversation"""
    try:
        user_id = get_jwt_identity()
        
        # Check if user is participant in this conversation
        participant = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user_id
        ).first()
        
        if not participant:
            return jsonify({
                'success': False,
                'message': 'You are not a participant in this conversation'
            }), 403
        
        # Get pagination parameters
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        
        # Get messages with pagination
        messages_query = db.session.query(Message).filter(
            Message.conversation_id == conversation_id,
            Message.deleted_at.is_(None)
        ).options(
            joinedload(Message.sender)
        ).order_by(desc(Message.sent_at))
        
        messages = messages_query.offset((page - 1) * per_page).limit(per_page).all()
        
        # Format messages
        result = []
        for msg in reversed(messages):  # Reverse to show oldest first
            message_data = {
                'id': msg.id,
                'content': msg.content,
                'message_type': msg.message_type,
                'sent_at': msg.sent_at.isoformat(),
                'sender': {
                    'id': msg.sender.id,
                    'name': msg.sender.name,
                    'email': msg.sender.email,
                    'avatar': msg.sender.avatar or '👤'
                },
                'is_me': msg.sender_id == user_id
            }
            
            # Add file info if it's a file message
            if msg.message_type in ['image', 'file']:
                message_data['file_url'] = msg.file_url
                message_data['file_name'] = msg.file_name
                message_data['file_type'] = msg.file_type
            
            # Add reference data if it's a reference message
            if msg.message_type == 'reference' and msg.reference_data:
                try:
                    message_data['reference_data'] = json.loads(msg.reference_data)
                except:
                    message_data['reference_data'] = None
            
            result.append(message_data)
        
        # Update user's last seen
        participant.last_seen = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'messages': result,
            'has_more': len(messages) == per_page
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching messages: {str(e)}'
        }), 500

@messages_bp.route('/conversations/<int:conversation_id>/messages', methods=['POST'])
@jwt_required()
def send_message(conversation_id):
    """Send a message to a conversation"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Check if user is participant in this conversation
        participant = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user_id
        ).first()
        
        if not participant:
            return jsonify({
                'success': False,
                'message': 'You are not a participant in this conversation'
            }), 403
        
        content = data.get('content', '').strip()
        message_type = data.get('message_type', 'text')
        reference_data = data.get('reference_data')
        
        if not content:
            return jsonify({
                'success': False,
                'message': 'Message content is required'
            }), 400
        
        # Create message
        message = Message(
            conversation_id=conversation_id,
            sender_id=user_id,
            content=content,
            message_type=message_type
        )
        
        # Add reference data if provided
        if reference_data:
            message.reference_data = json.dumps(reference_data)
        
        db.session.add(message)
        
        # Update conversation timestamp
        conversation = db.session.query(Conversation).get(conversation_id)
        conversation.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        # Get sender info for response
        sender = db.session.query(Users).get(user_id)
        
        return jsonify({
            'success': True,
            'message': {
                'id': message.id,
                'content': message.content,
                'message_type': message.message_type,
                'sent_at': message.sent_at.isoformat(),
                'sender': {
                    'id': sender.id,
                    'name': sender.name,
                    'email': sender.email,
                    'avatar': sender.avatar or '👤'
                }
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error sending message: {str(e)}'
        }), 500

@messages_bp.route('/conversations/<int:conversation_id>/participants', methods=['POST'])
@jwt_required()
def add_participant(conversation_id):
    """Add a participant to a group conversation"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Check if user is admin or moderator in this conversation
        current_participant = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user_id
        ).first()
        
        if not current_participant or current_participant.role not in ['admin', 'moderator']:
            return jsonify({
                'success': False,
                'message': 'You do not have permission to add participants'
            }), 403
        
        new_user_ids = data.get('user_ids', [])
        if not new_user_ids:
            return jsonify({
                'success': False,
                'message': 'User IDs are required'
            }), 400
        
        added_users = []
        for new_user_id in new_user_ids:
            # Check if user is already a participant
            existing = db.session.query(ConversationParticipant).filter(
                ConversationParticipant.conversation_id == conversation_id,
                ConversationParticipant.user_id == new_user_id
            ).first()
            
            if not existing:
                participant = ConversationParticipant(
                    conversation_id=conversation_id,
                    user_id=new_user_id,
                    role='member'
                )
                db.session.add(participant)
                
                # Get user info
                user = db.session.query(Users).get(new_user_id)
                if user:
                    added_users.append({
                        'id': user.id,
                        'name': user.name,
                        'email': user.email
                    })
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'added_users': added_users,
            'message': f'Added {len(added_users)} participants'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error adding participants: {str(e)}'
        }), 500

@messages_bp.route('/conversations/<int:conversation_id>/participants/<int:user_id>', methods=['DELETE'])
@jwt_required()
def remove_participant(conversation_id, user_id):
    """Remove a participant from a conversation"""
    try:
        current_user_id = get_jwt_identity()
        
        # Check if current user is admin or removing themselves
        current_participant = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == current_user_id
        ).first()
        
        if not current_participant:
            return jsonify({
                'success': False,
                'message': 'You are not a participant in this conversation'
            }), 403
        
        # Can remove if admin or removing self
        can_remove = (current_participant.role == 'admin' or current_user_id == user_id)
        
        if not can_remove:
            return jsonify({
                'success': False,
                'message': 'You do not have permission to remove this participant'
            }), 403
        
        # Find and remove participant
        participant = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user_id
        ).first()
        
        if participant:
            db.session.delete(participant)
            db.session.commit()
            return jsonify({
                'success': True,
                'message': 'Participant removed successfully'
            }), 200
        else:
            return jsonify({
                'success': False,
                'message': 'Participant not found'
            }), 404
            
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error removing participant: {str(e)}'
        }), 500

@messages_bp.route('/users/search', methods=['GET'])
@jwt_required()
def search_users():
    """Search users for creating new chats with filters"""
    try:
        query = request.args.get('query', '').strip()
        department = request.args.get('department')
        level = request.args.get('level')
        session = request.args.get('session')
        
        # Base query
        users_query = db.session.query(Users)
        
        # Apply search filters
        if query:
            users_query = users_query.filter(
                or_(
                    Users.name.ilike(f'%{query}%'),
                    Users.email.ilike(f'%{query}%'),
                    Users.designation.ilike(f'%{query}%')
                )
            )
        
        # Apply department filter
        if department:
            users_query = users_query.filter(Users.department.ilike(f'%{department}%'))
        
        # Apply level filter
        if level:
            users_query = users_query.filter(Users.level.ilike(f'%{level}%'))
        
        # Apply session filter
        if session:
            users_query = users_query.filter(Users.session.ilike(f'%{session}%'))
        
        # Get users (limit to prevent large responses)
        users = users_query.limit(50).all()
        
        result = []
        for user in users:
            result.append({
                'id': user.id,
                'name': user.name,
                'email': user.email,
                'designation': user.designation,
                'department': user.department,
                'level': user.level,
                'session': user.session,
                'avatar': user.avatar or '👤',
                'isOnline': True  # For now, assume all users are online
            })
        
        return jsonify({
            'success': True,
            'users': result
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error searching users: {str(e)}'
        }), 500

@messages_bp.route('/conversations/<int:conversation_id>/participants', methods=['GET'])
@jwt_required()
def get_participants(conversation_id):
    """Get all participants of a conversation"""
    try:
        user_id = get_jwt_identity()
        
        # Check if user is participant in this conversation
        participant_check = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user_id
        ).first()
        
        if not participant_check:
            return jsonify({
                'success': False,
                'message': 'You are not a participant in this conversation'
            }), 403
        
        # Get all participants
        participants = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id
        ).options(joinedload(ConversationParticipant.user)).all()
        
        result = []
        for participant in participants:
            result.append({
                'id': participant.user.id,
                'name': participant.user.name,
                'email': participant.user.email,
                'department': participant.user.department,
                'level': participant.user.level,
                'session': participant.user.session,
                'avatar': participant.user.avatar or '👤',
                'role': participant.role,
                'joined_at': participant.joined_at.isoformat(),
                'last_seen': participant.last_seen.isoformat() if participant.last_seen else None
            })
        
        return jsonify({
            'success': True,
            'participants': result
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching participants: {str(e)}'
        }), 500

@messages_bp.route('/messages/<int:message_id>/read', methods=['POST'])
@jwt_required()
def mark_message_read(message_id):
    """Mark a message as read"""
    try:
        user_id = get_jwt_identity()
        
        # Check if read record already exists
        existing_read = db.session.query(MessageRead).filter(
            MessageRead.message_id == message_id,
            MessageRead.user_id == user_id
        ).first()
        
        if not existing_read:
            message_read = MessageRead(
                message_id=message_id,
                user_id=user_id
            )
            db.session.add(message_read)
            db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Message marked as read'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error marking message as read: {str(e)}'
        }), 500
