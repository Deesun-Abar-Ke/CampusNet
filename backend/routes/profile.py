"""
Enhanced Profile Management Routes
Handles user profiles, achievements, skills, and CV generation
"""

from flask import Blueprint, request, jsonify, current_app, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
from functools import wraps
import base64
from datetime import datetime, date
import io
import json
from werkzeug.utils import secure_filename
from PIL import Image
import os

from models import db, Users, Profile, Achievement, Skill
from services.simple_cv_generator import SimpleCVGenerator

profile_bp = Blueprint('profile', __name__)

def serialize_date(obj):
    """JSON serializer for date objects"""
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")

@profile_bp.route('/', methods=['GET'])
@jwt_required()
def get_profile():
    """Get user profile with all related data"""
    try:
        current_user_id = get_jwt_identity()
        
        # Get user and profile
        user = Users.query.get(current_user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        
        # If no profile exists, create a basic one
        if not profile:
            profile = Profile()
            profile.user_id = current_user_id
            db.session.add(profile)
            db.session.commit()
        
        # Get achievements grouped by category
        achievements = Achievement.query.filter_by(profile_id=profile.id).order_by(
            Achievement.category, Achievement.display_order, Achievement.start_date.desc()
        ).all()
        
        # Group achievements by category
        achievements_by_category = {}
        for achievement in achievements:
            category = achievement.category
            if category not in achievements_by_category:
                achievements_by_category[category] = []
            
            achievements_by_category[category].append({
                'id': achievement.id,
                'title': achievement.title,
                'organization': achievement.organization,
                'description': achievement.description,
                'start_date': achievement.start_date.isoformat() if achievement.start_date else None,
                'end_date': achievement.end_date.isoformat() if achievement.end_date else None,
                'is_current': achievement.is_current,
                'grade_or_result': achievement.grade_or_result,
                'location': achievement.location,
                'skills_learned': json.loads(achievement.skills_learned) if achievement.skills_learned else [],
                'display_order': achievement.display_order,
                'created_at': achievement.created_at.isoformat(),
                'updated_at': achievement.updated_at.isoformat()
            })
        
        # Get skills grouped by category
        skills = Skill.query.filter_by(profile_id=profile.id).order_by(
            Skill.category, Skill.proficiency_level.desc(), Skill.name
        ).all()
        
        skills_by_category = {}
        for skill in skills:
            category = skill.category
            if category not in skills_by_category:
                skills_by_category[category] = []
            
            skills_by_category[category].append({
                'id': skill.id,
                'name': skill.name,
                'proficiency_level': skill.proficiency_level,
                'description': skill.description,
                'years_of_experience': skill.years_of_experience,
                'created_at': skill.created_at.isoformat(),
                'updated_at': skill.updated_at.isoformat()
            })
        
        # Prepare profile picture
        profile_picture_data = None
        if profile.profile_picture:
            profile_picture_data = {
                'data': base64.b64encode(profile.profile_picture).decode('utf-8'),
                'mime_type': profile.profile_picture_mime_type
            }
        
        # Prepare response
        profile_data = {
            'user': {
                'id': user.id,
                'name': user.name,
                'email': user.email,
                'phone': user.phone,
                'designation': user.designation
            },
            'profile': {
                'id': profile.id,
                'student_id': profile.student_id,
                'batch': profile.batch,
                'department': profile.department,
                'bio': profile.bio,
                'date_of_birth': profile.date_of_birth.isoformat() if profile.date_of_birth else None,
                'hometown': profile.hometown,
                'linkedin_url': profile.linkedin_url,
                'facebook_url': profile.facebook_url,
                'github_url': profile.github_url,
                'portfolio_url': profile.portfolio_url,
                'current_semester': profile.current_semester,
                'cgpa': profile.cgpa,
                'created_at': profile.created_at.isoformat(),
                'updated_at': profile.updated_at.isoformat(),
                'profile_picture': profile_picture_data
            },
            'achievements': achievements_by_category,
            'skills': skills_by_category
        }
        
        return jsonify({
            'success': True,
            'data': profile_data
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error getting profile: {e}")
        return jsonify({'error': 'Failed to get profile'}), 500

@profile_bp.route('/', methods=['PUT'])
@jwt_required()
def update_profile():
    """Update user profile information"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        if not profile:
            profile = Profile()
            profile.user_id = current_user_id
            db.session.add(profile)
        
        # Update profile fields
        if 'student_id' in data:
            profile.student_id = data['student_id']
        if 'batch' in data:
            profile.batch = data['batch']
        if 'department' in data:
            profile.department = data['department']
        if 'bio' in data:
            profile.bio = data['bio']
        if 'date_of_birth' in data and data['date_of_birth']:
            profile.date_of_birth = datetime.strptime(data['date_of_birth'], '%Y-%m-%d').date()
        if 'hometown' in data:
            profile.hometown = data['hometown']
        if 'linkedin_url' in data:
            profile.linkedin_url = data['linkedin_url']
        if 'facebook_url' in data:
            profile.facebook_url = data['facebook_url']
        if 'github_url' in data:
            profile.github_url = data['github_url']
        if 'portfolio_url' in data:
            profile.portfolio_url = data['portfolio_url']
        if 'current_semester' in data:
            profile.current_semester = data['current_semester']
        if 'cgpa' in data:
            profile.cgpa = data['cgpa']
        
        profile.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating profile: {e}")
        return jsonify({'error': 'Failed to update profile'}), 500

@profile_bp.route('/picture', methods=['POST'])
@jwt_required()
def upload_profile_picture():
    """Upload and update profile picture"""
    try:
        current_user_id = get_jwt_identity()
        
        if 'profile_picture' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['profile_picture']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Validate file type
        allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'}
        if file.filename:
            file_extension = file.filename.rsplit('.', 1)[1].lower()
            if file_extension not in allowed_extensions:
                return jsonify({'error': 'Invalid file type'}), 400
        
        # Process image
        image = Image.open(file.stream)
        
        # Resize image to a reasonable size (max 500x500)
        if image.width > 500 or image.height > 500:
            image.thumbnail((500, 500), Image.Resampling.LANCZOS)
        
        # Convert to RGB if necessary
        if image.mode in ('RGBA', 'P'):
            image = image.convert('RGB')
        
        # Save to bytes
        img_io = io.BytesIO()
        image.save(img_io, format='JPEG', quality=85)
        img_data = img_io.getvalue()
        
        # Update profile
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        if not profile:
            profile = Profile()
            profile.user_id = current_user_id
            db.session.add(profile)
        
        profile.profile_picture = img_data
        profile.profile_picture_mime_type = 'image/jpeg'
        profile.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Profile picture updated successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error uploading profile picture: {e}")
        return jsonify({'error': 'Failed to upload profile picture'}), 500

@profile_bp.route('/picture', methods=['GET'])
@jwt_required()
def get_profile_picture():
    """Get user's profile picture"""
    try:
        current_user_id = get_jwt_identity()
        
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        
        if not profile or not profile.profile_picture:
            return jsonify({'error': 'No profile picture found'}), 404
        
        return send_file(
            io.BytesIO(profile.profile_picture),
            mimetype=profile.profile_picture_mime_type or 'image/jpeg',
            as_attachment=False
        )
        
    except Exception as e:
        current_app.logger.error(f"Error getting profile picture: {e}")
        return jsonify({'error': 'Failed to get profile picture'}), 500

@profile_bp.route('/achievements', methods=['GET'])
@jwt_required()
def get_achievements():
    """Get user achievements"""
    try:
        current_user_id = get_jwt_identity()
        
        # Get user profile
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        if not profile:
            return jsonify([]), 200
        
        # Get achievements
        achievements = Achievement.query.filter_by(profile_id=profile.id).all()
        
        achievements_data = []
        for achievement in achievements:
            achievements_data.append({
                'id': achievement.id,
                'title': achievement.title,
                'details': achievement.description,  # Map description to details
                'date': achievement.end_date.isoformat() if achievement.end_date else None,
                'created_at': achievement.created_at.isoformat() if achievement.created_at else None
            })
        
        return jsonify(achievements_data), 200
        
    except Exception as e:
        current_app.logger.error(f"Error getting achievements: {e}")
        return jsonify({'error': 'Failed to get achievements'}), 500

@profile_bp.route('/achievements', methods=['POST'])
@jwt_required()
def add_achievement():
    """Add new achievement"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        # Get or create profile
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        if not profile:
            profile = Profile()
            profile.user_id = current_user_id
            db.session.add(profile)
            db.session.flush()  # To get the profile ID
        
        # Create achievement
        achievement = Achievement()
        achievement.profile_id = profile.id
        achievement.category = data.get('category', 'general')
        achievement.title = data['title']
        achievement.organization = data.get('organization')
        achievement.description = data.get('description')
        achievement.grade_or_result = data.get('grade_or_result')
        achievement.location = data.get('location')
        achievement.is_current = data.get('is_current', False)
        achievement.display_order = data.get('display_order', 0)
        
        # Handle dates
        if data.get('start_date'):
            achievement.start_date = datetime.strptime(data['start_date'], '%Y-%m-%d').date()
        if data.get('end_date') and not data.get('is_current'):
            achievement.end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date()
        
        # Handle skills learned
        if data.get('skills_learned'):
            achievement.skills_learned = json.dumps(data['skills_learned'])
        
        db.session.add(achievement)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Achievement added successfully',
            'achievement_id': achievement.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error adding achievement: {e}")
        return jsonify({'error': 'Failed to add achievement'}), 500

@profile_bp.route('/achievements/<int:achievement_id>', methods=['PUT'])
@jwt_required()
def update_achievement(achievement_id):
    """Update an achievement"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        # Get achievement and verify ownership
        achievement = Achievement.query.join(Profile).filter(
            Achievement.id == achievement_id,
            Profile.user_id == current_user_id
        ).first()
        
        if not achievement:
            return jsonify({'error': 'Achievement not found'}), 404
        
        # Update fields
        if 'category' in data:
            achievement.category = data['category']
        if 'title' in data:
            achievement.title = data['title']
        if 'organization' in data:
            achievement.organization = data['organization']
        if 'description' in data:
            achievement.description = data['description']
        if 'grade_or_result' in data:
            achievement.grade_or_result = data['grade_or_result']
        if 'location' in data:
            achievement.location = data['location']
        if 'is_current' in data:
            achievement.is_current = data['is_current']
        if 'display_order' in data:
            achievement.display_order = data['display_order']
        
        # Handle dates
        if 'start_date' in data and data['start_date']:
            achievement.start_date = datetime.strptime(data['start_date'], '%Y-%m-%d').date()
        if 'end_date' in data:
            if data['end_date'] and not data.get('is_current'):
                achievement.end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date()
            else:
                achievement.end_date = None
        
        # Handle skills learned
        if 'skills_learned' in data:
            achievement.skills_learned = json.dumps(data['skills_learned'])
        
        achievement.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Achievement updated successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating achievement: {e}")
        return jsonify({'error': 'Failed to update achievement'}), 500

@profile_bp.route('/achievements/<int:achievement_id>', methods=['DELETE'])
@jwt_required()
def delete_achievement(achievement_id):
    """Delete an achievement"""
    try:
        current_user_id = get_jwt_identity()
        # Get achievement and verify ownership
        achievement = Achievement.query.join(Profile).filter(
            Achievement.id == achievement_id,
            Profile.user_id == current_user_id
        ).first()
        
        if not achievement:
            return jsonify({'error': 'Achievement not found'}), 404
        
        db.session.delete(achievement)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Achievement deleted successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error deleting achievement: {e}")
        return jsonify({'error': 'Failed to delete achievement'}), 500

@profile_bp.route('/skills', methods=['GET'])
@jwt_required()
def get_skills():
    """Get user skills"""
    try:
        current_user_id = get_jwt_identity()
        
        # Get user profile
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        if not profile:
            return jsonify([]), 200
        
        # Get skills
        skills = Skill.query.filter_by(profile_id=profile.id).all()
        
        skills_data = []
        for skill in skills:
            skills_data.append({
                'id': skill.id,
                'name': skill.name,
                'category': skill.category,
                'proficiency_level': skill.proficiency_level,
                'description': skill.description,
                'years_of_experience': skill.years_of_experience,
                'created_at': skill.created_at.isoformat() if skill.created_at else None
            })
        
        return jsonify(skills_data), 200
        
    except Exception as e:
        current_app.logger.error(f"Error getting skills: {e}")
        return jsonify({'error': 'Failed to get skills'}), 500

@profile_bp.route('/skills', methods=['POST'])
@jwt_required()
def add_skill():
    """Add new skill"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        # Get or create profile
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        if not profile:
            profile = Profile()
            db.session.add(profile)
            db.session.flush()
        
        # Create skill
        skill = Skill()
        skill.profile_id = profile.id
        skill.name = data['name']
        skill.category = data.get('category', 'technical')
        skill.proficiency_level = data.get('proficiency_level', 3)
        skill.description = data.get('description')
        skill.years_of_experience = data.get('years_of_experience')
        
        db.session.add(skill)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Skill added successfully',
            'skill_id': skill.id
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error adding skill: {e}")
        return jsonify({'error': 'Failed to add skill'}), 500

@profile_bp.route('/skills/<int:skill_id>', methods=['PUT'])
@jwt_required()
def update_skill(skill_id):
    """Update a skill"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        # Get skill and verify ownership
        skill = Skill.query.join(Profile).filter(
            Skill.id == skill_id,
            Profile.user_id == current_user_id
        ).first()
        
        if not skill:
            return jsonify({'error': 'Skill not found'}), 404
        
        # Update fields
        if 'name' in data:
            skill.name = data['name']
        if 'category' in data:
            skill.category = data['category']
        if 'proficiency_level' in data:
            skill.proficiency_level = data['proficiency_level']
        if 'description' in data:
            skill.description = data['description']
        if 'years_of_experience' in data:
            skill.years_of_experience = data['years_of_experience']
        
        skill.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Skill updated successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating skill: {e}")
        return jsonify({'error': 'Failed to update skill'}), 500

@profile_bp.route('/skills/<int:skill_id>', methods=['DELETE'])
@jwt_required()
def delete_skill(skill_id):
    """Delete a skill"""
    try:
        current_user_id = get_jwt_identity()
        
        # Get skill and verify ownership
        skill = Skill.query.join(Profile).filter(
            Skill.id == skill_id,
            Profile.user_id == current_user_id
        ).first()
        
        if not skill:
            return jsonify({'error': 'Skill not found'}), 404
        
        db.session.delete(skill)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Skill deleted successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error deleting skill: {e}")
        return jsonify({'error': 'Failed to delete skill'}), 500

@profile_bp.route('/cv/generate', methods=['POST'])
@jwt_required()
def generate_cv():
    """Generate CV from profile data"""
    try:
        current_user_id = get_jwt_identity()
        
        # Get user profile data
        user = Users.query.get(current_user_id)
        profile = Profile.query.filter_by(user_id=current_user_id).first()
        
        if not user or not profile:
            return jsonify({'error': 'Profile not found'}), 404
        
        # Generate CV
        cv_generator = SimpleCVGenerator()
        result = cv_generator.generate_cv(current_user_id)
        
        if not result['success']:
            return jsonify({'error': result['message']}), 500
        
        # Return HTML file
        return send_file(
            result['file_path'],
            mimetype='text/html',
            as_attachment=True,
            download_name=f"{user.name.replace(' ', '_')}_CV.html" if user.name else "CV.html"
        )
        
    except Exception as e:
        current_app.logger.error(f"Error generating CV: {e}")
        return jsonify({'error': 'Failed to generate CV'}), 500

# Also add the route the frontend expects
@profile_bp.route('/generate-cv', methods=['POST'])
@jwt_required()
def generate_cv_alt():
    """Generate CV from profile data (alternative route for frontend compatibility)"""
    return generate_cv()

@profile_bp.route('/cv/templates', methods=['GET'])
def get_cv_templates():
    """Get available CV templates"""
    try:
        # Return simple template info since we only have one template
        return jsonify({
            'success': True,
            'templates': [
                {
                    'id': 1,
                    'name': 'Professional Modern',
                    'description': 'A clean, modern CV template suitable for professional use',
                    'is_default': True
                }
            ]
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error getting CV templates: {e}")
        return jsonify({'error': 'Failed to get CV templates'}), 500


@profile_bp.route('/generate-cv', methods=['POST'])
@jwt_required()
def generate_cv_frontend():
    """CV generation endpoint for frontend compatibility"""
    return generate_cv()
