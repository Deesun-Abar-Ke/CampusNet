import os
import json
from datetime import datetime
from flask import Blueprint, request, jsonify, send_from_directory
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Users, Conversation, ConversationParticipant, Message, MessageRead
from sqlalchemy import or_, and_, desc, func
from sqlalchemy.orm import joinedload

messages_bp = Blueprint('messages', __name__, url_prefix='/api/messages')

@messages_bp.route('/conversations', methods=['GET'])
@jwt_required()
def get_conversations():
    """Get all conversations for the current user with optimized queries"""
    try:
        user_id = get_jwt_identity()
        
        # Optimized query - only get conversation and participant data, not all messages
        conversations = db.session.query(Conversation).join(
            ConversationParticipant
        ).filter(
            ConversationParticipant.user_id == user_id
        ).options(
            joinedload(Conversation.participants).joinedload(ConversationParticipant.user)
            # Removed joinedload for all messages - we'll get last message separately
        ).order_by(desc(Conversation.updated_at)).all()
        
        # Get conversation IDs for batch queries
        conv_ids = [conv.id for conv in conversations]
        
        # Batch query for last messages
        last_messages_subquery = db.session.query(
            Message.conversation_id,
            func.max(Message.sent_at).label('max_sent_at')
        ).filter(
            Message.conversation_id.in_(conv_ids),
            Message.deleted_at.is_(None)
        ).group_by(Message.conversation_id).subquery()
        
        last_messages = db.session.query(Message).join(
            last_messages_subquery,
            and_(
                Message.conversation_id == last_messages_subquery.c.conversation_id,
                Message.sent_at == last_messages_subquery.c.max_sent_at
            )
        ).options(joinedload(Message.sender)).all()
        
        # Create lookup dict for last messages
        last_message_lookup = {msg.conversation_id: msg for msg in last_messages}
        
        result = []
        for conv in conversations:
            # Get last message from lookup
            last_message = last_message_lookup.get(conv.id)
            
            # Simplified unread count - for now set to 0 for performance
            # Can be optimized later with batch queries if needed
            unread_count = 0
            
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
                    'sent_at': last_message.sent_at.isoformat(),
                    'sender_name': last_message.sender.name,
                    'message_type': last_message.message_type
                }
            
            # Add participants info
            other_participant_found = False
            for participant in conv.participants:
                if conv.type == 'individual' and participant.user_id != user_id and not other_participant_found:
                    # For individual chats, show the other person's name (only set once)
                    conv_data['name'] = participant.user.name
                    conv_data['avatar'] = '👨‍🎓'  # Default avatar for individual chats
                    other_participant_found = True
                
                conv_data['participants'].append({
                    'id': participant.user.id,
                    'name': participant.user.name,
                    'email': participant.user.email,
                    'role': participant.role,
                    'joined_at': participant.joined_at.isoformat(),
                    'is_online': False  # For now, we'll set this to False. Can be updated with real online status later
                })
            
            # For individual chats, show member count as 2
            if conv.type == 'individual':
                conv_data['member_count'] = 2
            else:
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
                    'message': 'Individual chat must have exactly one other participant'
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
                    'conversation': {
                        'id': existing_conv.id,
                        'name': existing_conv.name,
                        'type': existing_conv.type,
                        'avatar': existing_conv.avatar,
                        'created_at': existing_conv.created_at.isoformat(),
                        'updated_at': existing_conv.updated_at.isoformat(),
                    },
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
            if participant_id != user_id:  # Don't add creator twice
                participant = ConversationParticipant(
                    conversation_id=conversation.id,
                    user_id=participant_id,
                    role='member'
                )
                db.session.add(participant)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'conversation': {
                'id': conversation.id,
                'name': conversation.name,
                'type': conversation.type,
                'avatar': conversation.avatar,
                'created_at': conversation.created_at.isoformat(),
                'updated_at': conversation.updated_at.isoformat(),
            },
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
        
        # Get messages with pagination (include deleted messages to maintain conversation flow)
        messages_query = db.session.query(Message).filter(
            Message.conversation_id == conversation_id
        ).options(
            joinedload(Message.sender),
            joinedload(Message.deleter)
        ).order_by(desc(Message.sent_at))
        
        messages = messages_query.offset((page - 1) * per_page).limit(per_page).all()
        
        # Format messages
        result = []
        for msg in reversed(messages):  # Reverse to show oldest first
            # Check if message is deleted
            if msg.deleted_at:
                message_data = {
                    'id': msg.id,
                    'content': '🗑️ This message was deleted',
                    'message_type': 'deleted',
                    'sent_at': msg.sent_at.isoformat(),
                    'deleted_at': msg.deleted_at.isoformat(),
                    'sender_name': msg.sender.name,
                    'sender_id': msg.sender.id,
                    'sender_email': msg.sender.email,
                    'is_me': msg.sender_id == user_id,
                    'is_deleted': True,
                    'deleted_by': msg.deleted_by,
                    'deleted_by_name': msg.deleter.name if msg.deleter else 'Unknown'
                }
            else:
                message_data = {
                    'id': msg.id,
                    'content': msg.content,
                    'message_type': msg.message_type,
                    'sent_at': msg.sent_at.isoformat(),
                    'sender_name': msg.sender.name,
                    'sender_id': msg.sender.id,
                    'sender_email': msg.sender.email,
                    'is_me': msg.sender_id == user_id,
                    'is_deleted': False
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
                        pass
            
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
        file_url = data.get('file_url')
        file_name = data.get('file_name')
        file_type = data.get('file_type')
        
        # For file messages, content can be empty (just the file)
        if not content and message_type == 'text':
            return jsonify({
                'success': False,
                'message': 'Message content is required'
            }), 400
        
        # Create message
        message = Message(
            conversation_id=conversation_id,
            sender_id=user_id,
            content=content,
            message_type=message_type,
            file_url=file_url,
            file_name=file_name,
            file_type=file_type
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
                    'email': sender.email
                },
                'file_url': message.file_url,
                'file_name': message.file_name,
                'file_type': message.file_type,
                'is_me': True
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
                # Add new participant
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
            'message': f'{len(added_users)} participant(s) added successfully'
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
    """Search users for creating new chats"""
    try:
        current_user_id = get_jwt_identity()
        query = request.args.get('query', '').strip()
        department = request.args.get('department')
        level = request.args.get('level')
        session = request.args.get('session')
        
        # Base query (exclude current user)
        users_query = db.session.query(Users).filter(Users.id != current_user_id)
        
        # Apply search filters
        if query:
            users_query = users_query.filter(
                or_(
                    Users.name.ilike(f'%{query}%'),
                    Users.email.ilike(f'%{query}%'),
                    Users.designation.ilike(f'%{query}%')
                )
            )
        
        if department:
            users_query = users_query.filter(Users.department.ilike(f'%{department}%'))
        
        if level:
            users_query = users_query.filter(Users.level == int(level))
            
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
                'avatar': user.avatar or '👨‍🎓',
                'is_online': True  # For now, assume all users are online
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
                'designation': participant.user.designation,
                'role': participant.role,
                'joined_at': participant.joined_at.isoformat(),
                'last_seen': participant.last_seen.isoformat() if participant.last_seen else None,
                'is_online': False  # Would need real-time status tracking
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

@messages_bp.route('/upload', methods=['POST'])
@jwt_required()
def upload_file():
    """Upload a file and return the file URL"""
    try:
        user_id = get_jwt_identity()
        
        if 'file' not in request.files:
            return jsonify({
                'success': False,
                'message': 'No file provided'
            }), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({
                'success': False,
                'message': 'No file selected'
            }), 400
        
        # Check file size (100MB limit)
        file.seek(0, 2)  # Seek to end of file
        file_size = file.tell()  # Get file size in bytes
        file.seek(0)  # Reset file pointer to beginning
        
        max_size = 100 * 1024 * 1024  # 100MB in bytes
        if file_size > max_size:
            return jsonify({
                'success': False,
                'message': f'File too large. Maximum size is 100MB. Your file is {file_size / (1024*1024):.1f}MB'
            }), 400
        
        # Create uploads directory if it doesn't exist
        import os
        upload_dir = os.path.join(os.path.dirname(__file__), '..', 'uploads')
        os.makedirs(upload_dir, exist_ok=True)
        
        # Generate unique filename
        import uuid
        from werkzeug.utils import secure_filename
        
        filename = secure_filename(file.filename)
        file_extension = filename.lower().split('.')[-1] if '.' in filename else ''
        unique_filename = f"{uuid.uuid4()}_{filename}"
        file_path = os.path.join(upload_dir, unique_filename)
        
        # Save the file
        file.save(file_path)
        
        # Determine file type and get file size in readable format
        if file_extension in ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp']:
            file_type = 'image'
        elif file_extension in ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'rtf']:
            file_type = 'document'
        elif file_extension in ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm']:
            file_type = 'video'
        elif file_extension in ['mp3', 'wav', 'aac', 'flac', 'ogg']:
            file_type = 'audio'
        else:
            file_type = 'file'

        # Return file info (absolute URL)
        # Use request.host_url to build absolute URL (includes scheme and host)
        file_url = f"{request.host_url.rstrip('/')}/api/messages/uploads/{unique_filename}"

        # Format file size
        if file_size < 1024:
            size_str = f"{file_size} B"
        elif file_size < 1024 * 1024:
            size_str = f"{file_size / 1024:.1f} KB"
        else:
            size_str = f"{file_size / (1024 * 1024):.1f} MB"
        
        return jsonify({
            'success': True,
            'file_url': file_url,
            'file_name': filename,
            'file_type': file_type,
            'file_size': file_size,
            'file_size_str': size_str,
            'message': 'File uploaded successfully'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error uploading file: {str(e)}'
        }), 500

@messages_bp.route('/messages/<int:message_id>', methods=['DELETE'])
@jwt_required()
def delete_message(message_id):
    """Delete a message (soft delete)"""
    try:
        user_id_str = get_jwt_identity()
        user_id = int(user_id_str)  # Convert to int for comparison
        
        print(f"DEBUG: Delete message request - user_id: {user_id}, message_id: {message_id}")
        
        # Get the message
        message = db.session.query(Message).filter(
            Message.id == message_id,
            Message.deleted_at.is_(None)  # Only allow deleting non-deleted messages
        ).first()
        
        if not message:
            print(f"DEBUG: Message {message_id} not found or already deleted")
            return jsonify({
                'success': False,
                'message': 'Message not found or already deleted'
            }), 404
        
        print(f"DEBUG: Message found - sender_id: {message.sender_id}, user_id: {user_id}")
        
        # Check if user is authorized to delete this message
        # 1. User must be a participant in the conversation
        participant = db.session.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == message.conversation_id,
            ConversationParticipant.user_id == user_id
        ).first()
        
        if not participant:
            print(f"DEBUG: User {user_id} is not a participant in conversation {message.conversation_id}")
            return jsonify({
                'success': False,
                'message': 'You are not a participant in this conversation'
            }), 403
        
        # 2. Check deletion permissions
        can_delete = False
        
        # User can always delete their own messages
        if message.sender_id == user_id:
            can_delete = True
            print(f"DEBUG: User can delete their own message")
        
        # Admins and moderators can delete any message in group chats
        elif participant.role in ['admin', 'moderator']:
            conversation = db.session.query(Conversation).get(message.conversation_id)
            if conversation and conversation.type == 'group':
                can_delete = True
                print(f"DEBUG: Admin/moderator can delete message in group chat")
        
        if not can_delete:
            print(f"DEBUG: User {user_id} cannot delete message from sender {message.sender_id}")
            return jsonify({
                'success': False,
                'message': 'You do not have permission to delete this message'
            }), 403
        
        # Perform soft delete
        message.deleted_at = datetime.utcnow()
        message.deleted_by = user_id
        
        # For file messages, we could optionally delete the actual file
        # but keeping it for now in case of recovery needs
        
        db.session.commit()
        
        print(f"DEBUG: Message {message_id} deleted successfully by user {user_id}")
        
        return jsonify({
            'success': True,
            'message': 'Message deleted successfully',
            'message_id': message_id,
            'deleted_at': message.deleted_at.isoformat(),
            'deleted_by': user_id
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error deleting message: {str(e)}'
        }), 500

@messages_bp.route('/uploads/<filename>')
def serve_uploaded_file(filename):
    """Serve uploaded files"""
    try:
        upload_dir = os.path.join(os.path.dirname(__file__), '..', 'uploads')
        # If client requests ?download=1, send as attachment with Content-Disposition
        as_attachment = request.args.get('download') == '1'
        response = send_from_directory(upload_dir, filename, as_attachment=as_attachment)
        # When not as_attachment, set appropriate mimetype is handled by send_from_directory
        # Ensure filenames are safe; send_from_directory will raise if file not found
        if as_attachment:
            # send_from_directory already sets Content-Disposition when as_attachment=True
            return response
        return response
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'File not found: {str(e)}'
        }), 404
