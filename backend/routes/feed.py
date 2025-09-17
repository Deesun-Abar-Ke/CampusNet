"""
Social Feed Routes for Landing Page
Handles posts, notifications, and social interactions
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Users, Post, Tag, PostLike, PostComment, SocialNotification
from datetime import datetime, timedelta
from sqlalchemy import desc, func, or_, and_
from werkzeug.utils import secure_filename
import os
import uuid

feed_bp = Blueprint('feed', __name__)

@feed_bp.route('/feed/posts', methods=['GET'])
@jwt_required()
def get_feed_posts():
    """Get paginated feed posts with filtering by tags"""
    try:
        current_user = get_jwt_identity()
        user = Users.query.get(current_user)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Query parameters
        page = request.args.get('page', 1, type=int)
        per_page = min(request.args.get('per_page', 20, type=int), 100)
        tag_name = request.args.get('tag', None)
        
        # Build query
        query = ClubPost.query.filter(ClubPost.is_published == True)
        
        # Filter by tag if provided
        if tag_name and tag_name != 'All':
            tag = PostTag.query.filter_by(name=tag_name).first()
            if tag:
                query = query.filter(ClubPost.tag_id == tag.id)
        
        # Order by pinned posts first, then by creation date
        query = query.order_by(desc(ClubPost.is_pinned), desc(ClubPost.created_at))
        
        # Paginate
        posts = query.paginate(
            page=page, 
            per_page=per_page, 
            error_out=False
        )
        
        # Format response
        posts_data = []
        for post in posts.items:
            # Get user's like status
            user_liked = PostLike.query.filter_by(
                post_id=post.id, 
                user_id=current_user
            ).first() is not None
            
            # Calculate time ago
            time_diff = datetime.utcnow() - post.created_at
            if time_diff.days > 0:
                time_ago = f"{time_diff.days} day{'s' if time_diff.days > 1 else ''} ago"
            elif time_diff.seconds > 3600:
                hours = time_diff.seconds // 3600
                time_ago = f"{hours} hour{'s' if hours > 1 else ''} ago"
            else:
                minutes = time_diff.seconds // 60
                time_ago = f"{minutes} minute{'s' if minutes > 1 else ''} ago"
            
            post_data = {
                'id': post.id,
                'title': post.title,
                'content': post.content,
                'image_url': post.image_url,
                'club_name': post.club.name,
                'club_logo': post.club.logo_url,
                'author_name': post.author.name,
                'tag': post.tag.name if post.tag else None,
                'tag_color': post.tag.color if post.tag else None,
                'is_pinned': post.is_pinned,
                'likes_count': post.likes_count,
                'comments_count': post.comments_count,
                'shares_count': post.shares_count,
                'user_liked': user_liked,
                'time_ago': time_ago,
                'created_at': post.created_at.isoformat()
            }
            posts_data.append(post_data)
        
        return jsonify({
            'posts': posts_data,
            'pagination': {
                'page': posts.page,
                'pages': posts.pages,
                'per_page': posts.per_page,
                'total': posts.total,
                'has_next': posts.has_next,
                'has_prev': posts.has_prev
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/feed/posts', methods=['POST'])
@jwt_required()
def create_post():
    """Create a new club post"""
    try:
        current_user = get_jwt_identity()
        user = Users.query.get(current_user)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json()
        
        # Validate required fields
        if not data.get('content'):
            return jsonify({'error': 'Content is required'}), 400
        
        # Check if user is a member of any club (for now, allow any user to post)
        # In the future, you might want to restrict this to club members only
        
        # Get or create default club for individual posts
        default_club = Club.query.filter_by(name="Student Posts").first()
        if not default_club:
            default_club = Club(
                name="Student Posts",
                description="Posts by individual students",
                category="general"
            )
            db.session.add(default_club)
            db.session.flush()
        
        # Get tag if provided
        tag = None
        if data.get('tag'):
            tag = PostTag.query.filter_by(name=data['tag']).first()
        
        # Create post
        new_post = ClubPost(
            club_id=default_club.id,
            author_id=current_user,
            title=data.get('title'),
            content=data['content'],
            tag_id=tag.id if tag else None,
            image_url=data.get('image_url')  # Handle image upload separately
        )
        
        db.session.add(new_post)
        db.session.commit()
        
        return jsonify({
            'message': 'Post created successfully',
            'post_id': new_post.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/feed/posts/<int:post_id>/like', methods=['POST'])
@jwt_required()
def toggle_post_like(post_id):
    """Toggle like on a post"""
    try:
        current_user = get_jwt_identity()
        user = Users.query.get(current_user)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        post = ClubPost.query.get(post_id)
        if not post:
            return jsonify({'error': 'Post not found'}), 404
        
        # Check if user already liked the post
        existing_like = PostLike.query.filter_by(
            post_id=post_id,
            user_id=current_user
        ).first()
        
        if existing_like:
            # Unlike
            db.session.delete(existing_like)
            post.likes_count = max(0, post.likes_count - 1)
            action = 'unliked'
        else:
            # Like
            new_like = PostLike(post_id=post_id, user_id=current_user)
            db.session.add(new_like)
            post.likes_count += 1
            action = 'liked'
            
            # Create notification for post author (if not self-like)
            if post.author_id != current_user:
                notification = Notification(
                    user_id=post.author_id,
                    title="New Like",
                    message=f"{user.name} liked your post",
                    type="like",
                    related_entity_type="club_post",
                    related_entity_id=post_id
                )
                db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'action': action,
            'likes_count': post.likes_count
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/feed/posts/<int:post_id>/comments', methods=['GET'])
@jwt_required()
def get_post_comments(post_id):
    """Get comments for a post"""
    try:
        post = ClubPost.query.get(post_id)
        if not post:
            return jsonify({'error': 'Post not found'}), 404
        
        # Get top-level comments (no parent)
        comments = PostComment.query.filter_by(
            post_id=post_id,
            parent_id=None,
            is_deleted=False
        ).order_by(PostComment.created_at.asc()).all()
        
        comments_data = []
        for comment in comments:
            # Get replies for this comment
            replies = PostComment.query.filter_by(
                parent_id=comment.id,
                is_deleted=False
            ).order_by(PostComment.created_at.asc()).all()
            
            replies_data = []
            for reply in replies:
                replies_data.append({
                    'id': reply.id,
                    'content': reply.content,
                    'author_name': reply.user.name,
                    'created_at': reply.created_at.isoformat()
                })
            
            comments_data.append({
                'id': comment.id,
                'content': comment.content,
                'author_name': comment.user.name,
                'created_at': comment.created_at.isoformat(),
                'replies': replies_data,
                'replies_count': len(replies_data)
            })
        
        return jsonify({
            'comments': comments_data,
            'total_comments': len(comments_data)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/feed/posts/<int:post_id>/comments', methods=['POST'])
@jwt_required()
def add_comment(post_id):
    """Add a comment to a post"""
    try:
        current_user = get_jwt_identity()
        user = Users.query.get(current_user)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        post = ClubPost.query.get(post_id)
        if not post:
            return jsonify({'error': 'Post not found'}), 404
        
        data = request.get_json()
        content = data.get('content', '').strip()
        
        if not content:
            return jsonify({'error': 'Comment content is required'}), 400
        
        # Create comment
        new_comment = PostComment(
            post_id=post_id,
            user_id=current_user,
            content=content,
            parent_id=data.get('parent_id')  # For replies
        )
        
        db.session.add(new_comment)
        
        # Update post comments count
        post.comments_count += 1
        
        # Create notification for post author (if not self-comment)
        if post.author_id != current_user:
            notification = Notification(
                user_id=post.author_id,
                title="New Comment",
                message=f"{user.name} commented on your post",
                type="comment",
                related_entity_type="club_post",
                related_entity_id=post_id
            )
            db.session.add(notification)
        
        db.session.commit()
        
        return jsonify({
            'message': 'Comment added successfully',
            'comment': {
                'id': new_comment.id,
                'content': new_comment.content,
                'author_name': user.name,
                'created_at': new_comment.created_at.isoformat()
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/feed/tags', methods=['GET'])
def get_popular_tags():
    """Get all available tags for filtering"""
    try:
        tags = PostTag.query.filter_by(is_active=True).all()
        
        # Add "All" as the first option
        tags_data = [{'name': 'All', 'color': '#6B73FF', 'post_count': None}]
        
        for tag in tags:
            # Count posts with this tag
            post_count = ClubPost.query.filter_by(tag_id=tag.id, is_published=True).count()
            
            tags_data.append({
                'id': tag.id,
                'name': tag.name,
                'color': tag.color,
                'description': tag.description,
                'post_count': post_count
            })
        
        return jsonify({'tags': tags_data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/notifications', methods=['GET'])
@jwt_required()
def get_notifications():
    """Get user notifications"""
    try:
        current_user = get_jwt_identity()
        user = Users.query.get(current_user)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        page = request.args.get('page', 1, type=int)
        per_page = min(request.args.get('per_page', 20, type=int), 100)
        unread_only = request.args.get('unread_only', 'false').lower() == 'true'
        
        # Build query
        query = Notification.query.filter_by(
            user_id=current_user,
            is_deleted=False
        )
        
        if unread_only:
            query = query.filter_by(is_read=False)
        
        # Order by creation date (newest first)
        query = query.order_by(desc(Notification.created_at))
        
        # Paginate
        notifications = query.paginate(
            page=page,
            per_page=per_page,
            error_out=False
        )
        
        notifications_data = []
        for notification in notifications.items:
            # Calculate time ago
            time_diff = datetime.utcnow() - notification.created_at
            if time_diff.days > 0:
                time_ago = f"{time_diff.days} day{'s' if time_diff.days > 1 else ''} ago"
            elif time_diff.seconds > 3600:
                hours = time_diff.seconds // 3600
                time_ago = f"{hours} hour{'s' if hours > 1 else ''} ago"
            else:
                minutes = time_diff.seconds // 60
                time_ago = f"{minutes} minute{'s' if minutes > 1 else ''} ago"
            
            notifications_data.append({
                'id': notification.id,
                'title': notification.title,
                'message': notification.message,
                'type': notification.type,
                'is_read': notification.is_read,
                'priority': notification.priority,
                'action_url': notification.action_url,
                'time_ago': time_ago,
                'created_at': notification.created_at.isoformat()
            })
        
        # Get unread count
        unread_count = Notification.query.filter_by(
            user_id=current_user,
            is_read=False,
            is_deleted=False
        ).count()
        
        return jsonify({
            'notifications': notifications_data,
            'unread_count': unread_count,
            'pagination': {
                'page': notifications.page,
                'pages': notifications.pages,
                'per_page': notifications.per_page,
                'total': notifications.total,
                'has_next': notifications.has_next,
                'has_prev': notifications.has_prev
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/notifications/<int:notification_id>/read', methods=['PUT'])
@jwt_required()
def mark_notification_read(notification_id):
    """Mark a notification as read"""
    try:
        current_user = get_jwt_identity()
        
        notification = Notification.query.filter_by(
            id=notification_id,
            user_id=current_user
        ).first()
        
        if not notification:
            return jsonify({'error': 'Notification not found'}), 404
        
        notification.is_read = True
        notification.read_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({'message': 'Notification marked as read'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/notifications/mark-all-read', methods=['PUT'])
@jwt_required()
def mark_all_notifications_read():
    """Mark all notifications as read for the current user"""
    try:
        current_user = get_jwt_identity()
        
        Notification.query.filter_by(
            user_id=current_user,
            is_read=False
        ).update({
            'is_read': True,
            'read_at': datetime.utcnow()
        })
        
        db.session.commit()
        
        return jsonify({'message': 'All notifications marked as read'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@feed_bp.route('/clubs', methods=['GET'])
@jwt_required()
def get_clubs():
    """Get all active clubs"""
    try:
        clubs = Club.query.filter_by(is_active=True).order_by(Club.name.asc()).all()
        
        clubs_data = []
        for club in clubs:
            clubs_data.append({
                'id': club.id,
                'name': club.name,
                'description': club.description,
                'logo_url': club.logo_url,
                'category': club.category,
                'posts_count': ClubPost.query.filter_by(club_id=club.id).count()
            })
        
        return jsonify({'clubs': clubs_data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
