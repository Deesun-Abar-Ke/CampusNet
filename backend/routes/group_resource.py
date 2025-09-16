# routes/group_resource.py

from flask import Blueprint, request, jsonify, send_file, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from sqlalchemy import and_, or_
from models import db, GroupFolder, GroupFile, Conversation, ConversationParticipant, Users
import os
import uuid
import hashlib
from datetime import datetime
import mimetypes

group_resource_bp = Blueprint('group_resource', __name__)

# Helper function to check if user is member of conversation
def is_conversation_member(conversation_id, user_id):
    return ConversationParticipant.query.filter_by(
        conversation_id=conversation_id,
        user_id=user_id
    ).first() is not None

# Helper function to check if user is admin of conversation
def is_conversation_admin(conversation_id, user_id):
    participant = ConversationParticipant.query.filter_by(
        conversation_id=conversation_id,
        user_id=user_id
    ).first()
    return participant and participant.role in ['admin', 'moderator']

# Helper function to get file size in human readable format
def get_human_readable_size(size_bytes):
    if size_bytes == 0:
        return "0B"
    size_names = ["B", "KB", "MB", "GB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024.0
        i += 1
    return f"{size_bytes:.1f} {size_names[i]}"

# Get folder structure for a conversation
@group_resource_bp.route('/conversations/<int:conversation_id>/folders', methods=['GET'])
@jwt_required()
def get_folders(conversation_id):
    try:
        user_id = get_jwt_identity()
        print(f"DEBUG: User ID from JWT: {user_id}")
        print(f"DEBUG: Conversation ID: {conversation_id}")
        
        if not user_id:
            print(f"DEBUG: No user ID found in JWT")
            return jsonify({'error': 'Unauthorized'}), 401
        
        # First check if conversation exists
        conversation = Conversation.query.get(conversation_id)
        print(f"DEBUG: Conversation found: {conversation is not None}")
        if conversation:
            print(f"DEBUG: Conversation details: ID={conversation.id}, Name={conversation.name}, Type={conversation.type}")
        if not conversation:
            print(f"DEBUG: No conversation found with ID {conversation_id}")
            return jsonify({'error': 'Conversation not found'}), 404
        
        # Check if user is member of conversation
        is_member = is_conversation_member(conversation_id, user_id)
        print(f"DEBUG: User is member: {is_member}")
        if not is_member:
            return jsonify({'error': 'Access denied'}), 403
        
        # Get parent folder ID from query params (null for root folders)
        parent_folder_id = request.args.get('parent_folder_id')
        if parent_folder_id == 'null' or parent_folder_id == '':
            parent_folder_id = None
        else:
            parent_folder_id = int(parent_folder_id) if parent_folder_id else None
        
        # Get folders
        folders = GroupFolder.query.filter_by(
            conversation_id=conversation_id,
            parent_folder_id=parent_folder_id
        ).order_by(GroupFolder.name).all()
        
        # Get files in current folder
        files = []
        if parent_folder_id:
            files = GroupFile.query.filter_by(
                conversation_id=conversation_id,
                folder_id=parent_folder_id
            ).order_by(GroupFile.name).all()
        
        # Format folder response
        folder_data = []
        for folder in folders:
            # Count subfolders and files
            subfolder_count = GroupFolder.query.filter_by(parent_folder_id=folder.id).count()
            file_count = GroupFile.query.filter_by(folder_id=folder.id).count()
            
            folder_data.append({
                'id': folder.id,
                'name': folder.name,
                'description': folder.description,
                'created_by': folder.creator.name,
                'created_at': folder.created_at.isoformat(),
                'item_count': subfolder_count + file_count,
                'type': 'folder'
            })
        
        # Format file response
        file_data = []
        # Get current server base URL for dynamic file URL generation
        server_base_url = current_app.config.get("SERVER_BASE_URL", "http://localhost:5000")
        
        for file in files:
            # Generate file URL dynamically using current server config
            filename = file.file_url.split('/')[-1] if file.file_url else f"{file.id}_{file.original_filename}"
            dynamic_file_url = f"{server_base_url}/files/{filename}"
            
            file_data.append({
                'id': file.id,
                'name': file.name,
                'original_filename': file.original_filename,
                'file_type': file.file_type,
                'file_size': file.file_size,
                'file_size_readable': get_human_readable_size(file.file_size),
                'file_url': dynamic_file_url,  # Dynamic URL based on current config
                'uploaded_by': file.uploader.name,
                'uploaded_at': file.uploaded_at.isoformat(),
                'description': file.description,
                'mime_type': file.mime_type,
                'type': 'file'
            })
        
        return jsonify({
            'folders': folder_data,
            'files': file_data,
            'current_folder_id': parent_folder_id
        }), 200
        
    except Exception as e:
        print(f"Error getting folders: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Create new folder
@group_resource_bp.route('/conversations/<int:conversation_id>/folders', methods=['POST'])
@jwt_required()
def create_folder(conversation_id):
    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Check if user is member of conversation
        if not is_conversation_member(conversation_id, user_id):
            return jsonify({'error': 'Access denied'}), 403
        
        data = request.get_json()
        folder_name = data.get('name', '').strip()
        parent_folder_id = data.get('parent_folder_id')
        description = data.get('description', '').strip()
        
        if not folder_name:
            return jsonify({'error': 'Folder name is required'}), 400
        
        # Check if folder name already exists in the same parent
        existing_folder = GroupFolder.query.filter_by(
            name=folder_name,
            conversation_id=conversation_id,
            parent_folder_id=parent_folder_id
        ).first()
        
        if existing_folder:
            return jsonify({'error': 'Folder with this name already exists'}), 409
        
        # Create new folder
        new_folder = GroupFolder(
            name=folder_name,
            conversation_id=conversation_id,
            parent_folder_id=parent_folder_id,
            created_by=user_id,
            description=description if description else None
        )
        
        db.session.add(new_folder)
        db.session.commit()
        
        return jsonify({
            'id': new_folder.id,
            'name': new_folder.name,
            'description': new_folder.description,
            'created_by': new_folder.creator.name,
            'created_at': new_folder.created_at.isoformat(),
            'item_count': 0,
            'type': 'folder'
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"Error creating folder: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Upload file to folder
@group_resource_bp.route('/conversations/<int:conversation_id>/folders/<int:folder_id>/upload', methods=['POST'])
@jwt_required()
def upload_file(conversation_id, folder_id):
    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Check if user is member of conversation
        if not is_conversation_member(conversation_id, user_id):
            return jsonify({'error': 'Access denied'}), 403
        
        # Check if folder exists and belongs to conversation
        folder = GroupFolder.query.filter_by(
            id=folder_id,
            conversation_id=conversation_id
        ).first()
        
        if not folder:
            return jsonify({'error': 'Folder not found'}), 404
        
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        description = request.form.get('description', '').strip()
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Generate unique filename
        original_filename = file.filename
        file_extension = os.path.splitext(original_filename)[1]
        unique_filename = f"{uuid.uuid4().hex}{file_extension}"
        
        # Create uploads directory if it doesn't exist
        upload_dir = os.path.join(current_app.root_path, 'uploads', 'group_resources')
        os.makedirs(upload_dir, exist_ok=True)
        
        # Save file
        file_path = os.path.join(upload_dir, unique_filename)
        file.save(file_path)
        
        # Get file info
        file_size = os.path.getsize(file_path)
        mime_type = mimetypes.guess_type(original_filename)[0] or 'application/octet-stream'
        file_type = file_extension.lower()[1:] if file_extension else 'unknown'
        
        # Calculate checksum
        with open(file_path, 'rb') as f:
            file_hash = hashlib.sha256(f.read()).hexdigest()
        
        # Create file URL using configured server base URL instead of request host
        server_base_url = current_app.config.get("SERVER_BASE_URL", "http://localhost:5000")
        file_url = f"{server_base_url}/files/{unique_filename}"
        
        # Check if file with same name exists in folder
        existing_file = GroupFile.query.filter_by(
            name=original_filename,
            folder_id=folder_id
        ).first()
        
        if existing_file:
            # Remove uploaded file and return error
            os.remove(file_path)
            return jsonify({'error': 'File with this name already exists in folder'}), 409
        
        # Create database record
        new_file = GroupFile(
            name=original_filename,
            original_filename=original_filename,
            file_path=file_path,
            file_url=file_url,
            file_type=file_type,
            file_size=file_size,
            conversation_id=conversation_id,
            folder_id=folder_id,
            uploaded_by=user_id,
            description=description if description else None,
            mime_type=mime_type,
            checksum=file_hash
        )
        
        db.session.add(new_file)
        db.session.commit()
        
        # Generate dynamic file URL for response
        current_server_base_url = current_app.config.get("SERVER_BASE_URL", "http://localhost:5000")
        filename = new_file.file_url.split('/')[-1]
        dynamic_file_url = f"{current_server_base_url}/files/{filename}"
        
        return jsonify({
            'id': new_file.id,
            'name': new_file.name,
            'original_filename': new_file.original_filename,
            'file_type': new_file.file_type,
            'file_size': new_file.file_size,
            'file_size_readable': get_human_readable_size(new_file.file_size),
            'file_url': dynamic_file_url,  # Dynamic URL
            'uploaded_by': new_file.uploader.name,
            'uploaded_at': new_file.uploaded_at.isoformat(),
            'description': new_file.description,
            'mime_type': new_file.mime_type,
            'type': 'file'
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"Error uploading file: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Download/serve file
@group_resource_bp.route('/files/<filename>', methods=['GET'])
@jwt_required()
def serve_file(filename):
    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Find file in database
        file_record = GroupFile.query.filter(
            GroupFile.file_url.endswith(filename)
        ).first()
        
        if not file_record:
            return jsonify({'error': 'File not found'}), 404
        
        # Check if user has access to this file's conversation
        if not is_conversation_member(file_record.conversation_id, user_id):
            return jsonify({'error': 'Access denied'}), 403
        
        # Check if force download is requested
        force_download = request.args.get('download', 'false').lower() == 'true'
        
        # Determine if file should be displayed or downloaded
        # For PDFs and images, display inline unless force download; for other files, download
        is_viewable = file_record.file_type.lower() in ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp']
        
        # Serve file
        return send_file(
            file_record.file_path,
            as_attachment=force_download or not is_viewable,  # Display inline for viewable files unless forced
            download_name=file_record.original_filename,
            mimetype=file_record.mime_type
        )
        
    except Exception as e:
        print(f"Error serving file: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Delete folder
@group_resource_bp.route('/conversations/<int:conversation_id>/folders/<int:folder_id>', methods=['DELETE'])
@jwt_required()
def delete_folder(conversation_id, folder_id):
    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Check if user is admin of conversation
        if not is_conversation_admin(conversation_id, user_id):
            return jsonify({'error': 'Admin access required'}), 403
        
        # Get folder
        folder = GroupFolder.query.filter_by(
            id=folder_id,
            conversation_id=conversation_id
        ).first()
        
        if not folder:
            return jsonify({'error': 'Folder not found'}), 404
        
        # Check if folder has subfolders or files
        has_subfolders = GroupFolder.query.filter_by(parent_folder_id=folder_id).count() > 0
        has_files = GroupFile.query.filter_by(folder_id=folder_id).count() > 0
        
        if has_subfolders or has_files:
            return jsonify({'error': 'Cannot delete non-empty folder'}), 409
        
        # Delete folder
        db.session.delete(folder)
        db.session.commit()
        
        return jsonify({'message': 'Folder deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"Error deleting folder: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Delete file
@group_resource_bp.route('/conversations/<int:conversation_id>/files/<int:file_id>', methods=['DELETE'])
@jwt_required()
def delete_file(conversation_id, file_id):
    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Get file
        file_record = GroupFile.query.filter_by(
            id=file_id,
            conversation_id=conversation_id
        ).first()
        
        if not file_record:
            return jsonify({'error': 'File not found'}), 404
        
        # Check if user is admin or file uploader
        if not (is_conversation_admin(conversation_id, user_id) or file_record.uploaded_by == user_id):
            return jsonify({'error': 'Permission denied'}), 403
        
        # Delete physical file
        try:
            if os.path.exists(file_record.file_path):
                os.remove(file_record.file_path)
        except Exception as e:
            print(f"Warning: Could not delete physical file: {str(e)}")
        
        # Delete database record
        db.session.delete(file_record)
        db.session.commit()
        
        return jsonify({'message': 'File deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"Error deleting file: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Get folder breadcrumb path
@group_resource_bp.route('/conversations/<int:conversation_id>/folders/<int:folder_id>/path', methods=['GET'])
@jwt_required()
def get_folder_path(conversation_id, folder_id):
    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Check if user is member of conversation
        if not is_conversation_member(conversation_id, user_id):
            return jsonify({'error': 'Access denied'}), 403
        
        # Build path from root to current folder
        path = []
        current_folder_id = folder_id
        
        while current_folder_id:
            folder = GroupFolder.query.get(current_folder_id)
            if not folder or folder.conversation_id != conversation_id:
                break
            
            path.insert(0, {
                'id': folder.id,
                'name': folder.name
            })
            current_folder_id = folder.parent_folder_id
        
        return jsonify({'path': path}), 200
        
    except Exception as e:
        print(f"Error getting folder path: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# Search files and folders
@group_resource_bp.route('/conversations/<int:conversation_id>/search', methods=['GET'])
@jwt_required()
def search_resources(conversation_id):
    try:
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Unauthorized'}), 401
        
        # Check if user is member of conversation
        if not is_conversation_member(conversation_id, user_id):
            return jsonify({'error': 'Access denied'}), 403
        
        query = request.args.get('q', '').strip()
        if not query:
            return jsonify({'folders': [], 'files': []}), 200
        
        # Search folders
        folders = GroupFolder.query.filter(
            and_(
                GroupFolder.conversation_id == conversation_id,
                or_(
                    GroupFolder.name.ilike(f'%{query}%'),
                    GroupFolder.description.ilike(f'%{query}%')
                )
            )
        ).limit(20).all()
        
        # Search files
        files = GroupFile.query.filter(
            and_(
                GroupFile.conversation_id == conversation_id,
                or_(
                    GroupFile.name.ilike(f'%{query}%'),
                    GroupFile.original_filename.ilike(f'%{query}%'),
                    GroupFile.description.ilike(f'%{query}%')
                )
            )
        ).limit(20).all()
        
        # Format results
        folder_results = []
        for folder in folders:
            folder_results.append({
                'id': folder.id,
                'name': folder.name,
                'description': folder.description,
                'created_by': folder.creator.name,
                'created_at': folder.created_at.isoformat(),
                'type': 'folder'
            })
        
        file_results = []
        for file in files:
            file_results.append({
                'id': file.id,
                'name': file.name,
                'original_filename': file.original_filename,
                'file_type': file.file_type,
                'file_size_readable': get_human_readable_size(file.file_size),
                'uploaded_by': file.uploader.name,
                'uploaded_at': file.uploaded_at.isoformat(),
                'type': 'file',
                'folder_name': file.folder.name
            })
        
        return jsonify({
            'folders': folder_results,
            'files': file_results
        }), 200
        
    except Exception as e:
        print(f"Error searching resources: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500
