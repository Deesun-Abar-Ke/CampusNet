from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import Tag, Post, PostLike, PostComment, Users, db
from werkzeug.utils import secure_filename
import os
import base64
from datetime import datetime
import uuid

social_bp = Blueprint('social', __name__)

# Allowed file extensions for image upload
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Get all posts with filtering (public: no JWT required)
@social_bp.route('/posts', methods=['GET'])
def get_posts():
    try:
        # Debug: log incoming Authorization header (if present) to help diagnose 401s
        auth_header = request.headers.get('Authorization')
        current_app.logger.info(f"Authorization header present: {bool(auth_header)} - {auth_header[:40] + '...' if auth_header and len(auth_header) > 40 else auth_header}")
        try:
            current_user = get_jwt_identity()
            current_app.logger.info(f"JWT identity from request: {current_user}")
        except Exception as ji_e:
            current_app.logger.warning(f"Could not retrieve JWT identity: {ji_e}")

        tag_filter = request.args.get('tag')
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        current_app.logger.info(f"Fetching posts with tag_filter: {tag_filter}, page: {page}")
        
        query = Post.query
        
        # Filter by tag if provided  
        if tag_filter and tag_filter.lower() != 'all':
            current_app.logger.info(f"Filtering by tag: {tag_filter}")
            # Use INNER JOIN to only get posts with the specific tag
            query = query.join(Tag, Post.tag_id == Tag.id).filter(Tag.name == tag_filter)
            current_app.logger.info(f"Applied tag filter for: {tag_filter}")
        else:
            current_app.logger.info("Fetching all posts (including those without tags)")
            # For "All" or no filter, get all posts regardless of tag_id (including NULL)
        
        # Order by creation time (newest first)
        query = query.order_by(Post.created_at.desc())
        
        # Paginate
        posts = query.paginate(page=page, per_page=per_page, error_out=False)
        
        current_app.logger.info(f"Found {len(posts.items)} posts")
        
        posts_data = []
        for post in posts.items:
            # Debug image URL
            if post.image_url:
                current_app.logger.info(f"Post {post.id} has image_url (first 100 chars): {post.image_url[:100]}...")
            
            posts_data.append({
                'id': post.id,
                'title': post.title,
                'content': post.content,
                'image_url': post.image_url,
                'time_ago': post.time_ago,
                'created_at': post.created_at.isoformat(),
                'updated_at': post.updated_at.isoformat(),
                # Flatten tag data  
                'tag_id': post.tag.id if post.tag else None,
                'tag_name': post.tag.name if post.tag else None,
                'tag_color': post.tag.color if post.tag else None,
                # Flatten author data
                'author_id': post.author.id if post.author else None,
                'author_name': post.author.name if post.author else 'Unknown',
                'like_count': post.like_count,
                'comment_count': post.comment_count,
                'is_liked_by_user': False  # TODO: Implement user like checking
            })
        
        return jsonify({
            'success': True,
            'posts': posts_data,
            'pagination': {
                'page': posts.page,
                'pages': posts.pages,
                'per_page': posts.per_page,
                'total': posts.total,
                'has_next': posts.has_next,
                'has_prev': posts.has_prev
            }
        })
        
    except Exception as e:
        current_app.logger.error(f"Error getting posts: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

# Get all tags (public)
@social_bp.route('/tags', methods=['GET'])
def get_tags():
    try:
        tags = Tag.query.all()
        tags_data = [{'id': tag.id, 'name': tag.name, 'color': tag.color} for tag in tags]
        
        # Add "All" option at the beginning
        tags_data.insert(0, {'id': None, 'name': 'All', 'color': '#6B7280'})
        
        return jsonify({
            'success': True,
            'tags': tags_data
        })
        
    except Exception as e:
        current_app.logger.error(f"Error getting tags: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

# Get popular tags based on usage count (public)
@social_bp.route('/tags/popular', methods=['GET'])
def get_popular_tags():
    try:
        # Get tags from the 'tags' table ordered by usage count (number of posts)
        popular_tags = db.session.query(
            Tag.id,
            Tag.name, 
            Tag.color,
            db.func.count(Post.id).label('usage_count')
        ).outerjoin(Post).group_by(Tag.id, Tag.name, Tag.color).order_by(
            db.func.count(Post.id).desc()
        ).limit(10).all()
        
        tags_data = []
        # Add "All" option at the beginning
        tags_data.append({'id': None, 'name': 'All', 'color': '#6B7280', 'usage_count': 0})
        
        # Add popular tags
        for tag in popular_tags:
            tags_data.append({
                'id': tag.id,
                'name': tag.name,
                'color': tag.color,
                'usage_count': tag.usage_count
            })
        
        # If no popular tags exist, add default ones to the 'tags' table
        if len(tags_data) == 1:  # Only "All" exists
            default_tags = [
                {'name': 'Academic', 'color': '#28a745'},
                {'name': 'Events', 'color': '#fd7e14'},
                {'name': 'Sports', 'color': '#6f42c1'},
                {'name': 'Announcements', 'color': '#dc3545'},
                {'name': 'Career', 'color': '#6c757d'},
                {'name': 'Technology', 'color': '#17a2b8'},
            ]
            
            for default_tag in default_tags:
                # Create tag if it doesn't exist in the 'tags' table
                existing_tag = Tag.query.filter_by(name=default_tag['name']).first()
                if not existing_tag:
                    new_tag = Tag(
                        name=default_tag['name'],
                        color=default_tag['color']
                    )
                    db.session.add(new_tag)
                    db.session.flush()
                    tags_data.append({
                        'id': new_tag.id,
                        'name': new_tag.name,
                        'color': new_tag.color,
                        'usage_count': 0
                    })
                else:
                    tags_data.append({
                        'id': existing_tag.id,
                        'name': existing_tag.name,
                        'color': existing_tag.color,
                        'usage_count': 0
                    })
            
            db.session.commit()
        
        return jsonify({
            'success': True,
            'tags': tags_data
        })
    except Exception as e:
        current_app.logger.error(f"Error getting popular tags: {e}")
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

# Social post creation
@social_bp.route('/posts', methods=['POST'])
@jwt_required()
def create_post():
    try:
        current_user_id = get_jwt_identity()
        current_app.logger.info(f"Creating post for user: {current_user_id}")
        current_app.logger.info(f"Request content type: {request.content_type}")
        current_app.logger.info(f"Request files: {list(request.files.keys())}")
        
        # Handle both JSON and form data
        if request.content_type and 'application/json' in request.content_type:
            # JSON request (web with possible Base64 image)
            current_app.logger.info("Processing JSON request")
            data = request.get_json()
            title = data.get('title', '').strip()
            content = data.get('content', '').strip()
            tag_id = data.get('tag_id')
            tag_name = data.get('tag_name')  # Allow tag name instead of ID
            image_data = data.get('image_data')  # Base64 data URL from web
            image_file = None
        else:
            # Form data request (mobile with possible image file)
            current_app.logger.info("Processing form data request")
            title = request.form.get('title', '').strip()
            content = request.form.get('content', '').strip()
            tag_id = request.form.get('tag_id', type=int)
            tag_name = request.form.get('tag_name')
            image_file = request.files.get('image')
            image_data = None
        
        # Handle tag creation/retrieval from the correct 'tags' table
        final_tag_id = None
        if tag_name:
            # Find or create tag by name in the 'tags' table
            current_app.logger.info(f"Looking for tag: {tag_name}")
            tag = Tag.query.filter_by(name=tag_name).first()
            if not tag:
                # Create new tag with a random color in the 'tags' table
                colors = ['#007bff', '#28a745', '#fd7e14', '#6f42c1', '#20c997', '#dc3545', '#6c757d', '#17a2b8', '#e83e8c', '#ffc107']
                import random
                tag = Tag(
                    name=tag_name,
                    color=random.choice(colors)
                )
                db.session.add(tag)
                db.session.flush()  # Get the ID without committing
                current_app.logger.info(f"Created new tag in 'tags' table: {tag_name} with ID: {tag.id} and color: {tag.color}")
            else:
                current_app.logger.info(f"Found existing tag: {tag_name} with ID: {tag.id}")
            final_tag_id = tag.id
        elif tag_id:
            # Verify that the tag_id exists in the 'tags' table
            tag = Tag.query.get(tag_id)
            if tag:
                final_tag_id = tag_id
                current_app.logger.info(f"Using existing tag ID: {tag_id} ({tag.name})")
            else:
                current_app.logger.warning(f"Tag ID {tag_id} not found in 'tags' table")
        
        current_app.logger.info(f"Final tag ID to be used: {final_tag_id}")
        
        # Validate required fields
        if not content:
            return jsonify({'success': False, 'message': 'Content is required'}), 400
        
        # Handle image upload - save as base64 in database
        image_url = None
        
        # Handle web Base64 image data
        if image_data and image_data.startswith('data:image/'):
            current_app.logger.info("Processing Base64 image data from web")
            image_url = image_data  # Store the complete data URL
            current_app.logger.info(f"Base64 image processed, length: {len(image_url)} chars")
        
        # Handle mobile file upload
        elif image_file and image_file.filename and allowed_file(image_file.filename):
            current_app.logger.info(f"Processing image file: {image_file.filename}")
            # Read and encode the image file as base64
            image_data = image_file.read()
            image_base64 = base64.b64encode(image_data).decode('utf-8')
            
            # Get mime type
            file_extension = secure_filename(image_file.filename).rsplit('.', 1)[1].lower()
            mime_type_map = {
                'jpg': 'image/jpeg',
                'jpeg': 'image/jpeg',
                'png': 'image/png',
                'gif': 'image/gif',
                'webp': 'image/webp'
            }
            mime_type = mime_type_map.get(file_extension, 'image/jpeg')
            
            # Create data URL for frontend
            image_url = f"data:{mime_type};base64,{image_base64}"
            current_app.logger.info(f"Mobile image processed successfully, size: {len(image_base64)} chars")
        else:
            current_app.logger.info("No image provided")
        
        # Create post without club requirement
        post = Post(
            title=title,
            content=content,
            image_url=image_url,
            tag_id=final_tag_id,  # Use the resolved tag ID
            author_id=current_user_id
        )
        
        db.session.add(post)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Post created successfully',
            'post_id': post.id
        }), 201
        
    except Exception as e:
        current_app.logger.error(f"Error creating post: {e}")
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

# Like/Unlike a post
@social_bp.route('/posts/<int:post_id>/like', methods=['POST'])
@jwt_required()
def toggle_like_post(post_id):
    try:
        current_user_id = get_jwt_identity()
        
        # Check if post exists
        post = Post.query.get(post_id)
        if not post:
            return jsonify({'success': False, 'message': 'Post not found'}), 404
        
        # Check if user already liked this post
        existing_like = PostLike.query.filter_by(user_id=current_user_id, post_id=post_id).first()
        
        if existing_like:
            # Unlike the post
            db.session.delete(existing_like)
            liked = False
            message = 'Post unliked'
        else:
            # Like the post
            new_like = PostLike(user_id=current_user_id, post_id=post_id)
            db.session.add(new_like)
            liked = True
            message = 'Post liked'
        
        db.session.commit()
        
        # Get updated like count
        like_count = PostLike.query.filter_by(post_id=post_id).count()
        
        return jsonify({
            'success': True,
            'message': message,
            'liked': liked,
            'like_count': like_count
        })
        
    except Exception as e:
        current_app.logger.error(f"Error toggling like: {e}")
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

# Add comment to post
@social_bp.route('/posts/<int:post_id>/comments', methods=['POST'])
@jwt_required()
def add_comment(post_id):
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        content = data.get('content', '').strip()
        if not content:
            return jsonify({'success': False, 'message': 'Comment content is required'}), 400
        
        # Check if post exists
        post = Post.query.get(post_id)
        if not post:
            return jsonify({'success': False, 'message': 'Post not found'}), 404
        
        # Create comment
        comment = PostComment(
            content=content,
            user_id=current_user_id,
            post_id=post_id
        )
        
        db.session.add(comment)
        db.session.commit()
        
        # Get updated comment count
        comment_count = PostComment.query.filter_by(post_id=post_id).count()
        
        return jsonify({
            'success': True,
            'message': 'Comment added successfully',
            'comment_count': comment_count
        })
        
    except Exception as e:
        current_app.logger.error(f"Error adding comment: {e}")
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

# Get comments for a post
@social_bp.route('/posts/<int:post_id>/comments', methods=['GET'])
@jwt_required()
def get_comments(post_id):
    try:
        comments = PostComment.query.filter_by(post_id=post_id).order_by(PostComment.created_at.desc()).all()
        
        comments_data = []
        for comment in comments:
            # Calculate time_ago manually since property isn't working
            now = datetime.utcnow()
            diff = now - comment.created_at
            
            if diff.total_seconds() < 60:
                time_ago_str = "Just now"
            elif diff.total_seconds() < 3600:
                minutes = int(diff.total_seconds() // 60)
                time_ago_str = f"{minutes} minute{'s' if minutes != 1 else ''} ago"
            elif diff.total_seconds() < 86400:
                hours = int(diff.total_seconds() // 3600)
                time_ago_str = f"{hours} hour{'s' if hours != 1 else ''} ago"
            else:
                days = diff.days
                time_ago_str = f"{days} day{'s' if days != 1 else ''} ago"
            
            comments_data.append({
                'id': comment.id,
                'content': comment.content,
                'user_id': comment.user.id,
                'user_name': comment.user.name,
                'post_id': comment.post_id,
                'created_at': comment.created_at.isoformat(),
                'updated_at': comment.updated_at.isoformat() if hasattr(comment, 'updated_at') and comment.updated_at else comment.created_at.isoformat(),
                'time_ago': time_ago_str
            })
        
        return jsonify({
            'success': True,
            'comments': comments_data
        })
        
    except Exception as e:
        current_app.logger.error(f"Error getting comments: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

# Get user notifications

