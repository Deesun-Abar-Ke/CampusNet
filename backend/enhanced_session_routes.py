@chat_bp.route('/sessions/<int:session_id>/messages', methods=['GET'])
@jwt_required()
def get_session_messages():
    """Get the last 10 conversation messages for a specific session to provide context"""
    try:
        user_id = get_jwt_identity()
        session_id = request.view_args['session_id']
        
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
def delete_session():
    """Delete a chat session and all its messages"""
    try:
        user_id = get_jwt_identity()
        session_id = request.view_args['session_id']
        
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
def rename_session():
    """Rename a chat session"""
    try:
        user_id = get_jwt_identity()
        session_id = request.view_args['session_id']
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
