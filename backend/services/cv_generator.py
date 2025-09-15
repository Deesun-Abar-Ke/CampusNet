"""
CV Generator Service
Generates professional CVs from user profile data using HTML templates and WeasyPrint
"""

import os
import io
import base64
from datetime import datetime, date
from jinja2 import Template
import weasyprint
from flask import current_app
import json


class CVGenerator:
    """Service for generating CVs from profile data"""
    
    def __init__(self):
        self.templates_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'cv_templates')
        if not os.path.exists(self.templates_dir):
            os.makedirs(self.templates_dir, exist_ok=True)
    
    def generate_cv(self, user, profile, template_name='modern_template.html'):
        """Generate CV PDF from user profile data"""
        try:
            # Prepare data for template
            cv_data = self._prepare_cv_data(user, profile)
            
            # Load and render template
            html_content = self._render_template(template_name, cv_data)
            
            # Generate PDF
            pdf_buffer = self._generate_pdf(html_content)
            
            return pdf_buffer
            
        except Exception as e:
            current_app.logger.error(f"Error generating CV: {e}")
            return None
    
    def _prepare_cv_data(self, user, profile):
        """Prepare user data for CV template"""
        
        # Get achievements grouped by category
        achievements_by_category = {}
        for achievement in profile.achievements:
            category = achievement.category
            if category not in achievements_by_category:
                achievements_by_category[category] = []
            
            # Format dates
            start_date = achievement.start_date.strftime('%B %Y') if achievement.start_date else None
            end_date = 'Present' if achievement.is_current else (
                achievement.end_date.strftime('%B %Y') if achievement.end_date else None
            )
            
            achievements_by_category[category].append({
                'title': achievement.title,
                'organization': achievement.organization,
                'description': achievement.description,
                'start_date': start_date,
                'end_date': end_date,
                'duration': f"{start_date} - {end_date}" if start_date else None,
                'grade_or_result': achievement.grade_or_result,
                'location': achievement.location,
                'skills_learned': json.loads(achievement.skills_learned) if achievement.skills_learned else []
            })
        
        # Get skills grouped by category
        skills_by_category = {}
        for skill in profile.skills:
            category = skill.category
            if category not in skills_by_category:
                skills_by_category[category] = []
            
            skills_by_category[category].append({
                'name': skill.name,
                'proficiency_level': skill.proficiency_level,
                'proficiency_text': self._get_proficiency_text(skill.proficiency_level),
                'description': skill.description,
                'years_of_experience': skill.years_of_experience
            })
        
        # Prepare profile picture
        profile_picture_base64 = None
        if profile.profile_picture:
            profile_picture_base64 = base64.b64encode(profile.profile_picture).decode('utf-8')
        
        return {
            'user': {
                'name': user.name,
                'email': user.email,
                'phone': user.phone,
                'designation': user.designation
            },
            'profile': {
                'student_id': profile.student_id,
                'batch': profile.batch,
                'department': profile.department,
                'bio': profile.bio,
                'date_of_birth': profile.date_of_birth.strftime('%B %d, %Y') if profile.date_of_birth else None,
                'hometown': profile.hometown,
                'linkedin_url': profile.linkedin_url,
                'facebook_url': profile.facebook_url,
                'github_url': profile.github_url,
                'portfolio_url': profile.portfolio_url,
                'current_semester': profile.current_semester,
                'cgpa': profile.cgpa,
                'profile_picture_base64': profile_picture_base64
            },
            'achievements': achievements_by_category,
            'skills': skills_by_category,
            'generated_date': datetime.now().strftime('%B %d, %Y')
        }
    
    def _get_proficiency_text(self, level):
        """Convert proficiency level to text"""
        proficiency_map = {
            1: 'Beginner',
            2: 'Novice',
            3: 'Intermediate',
            4: 'Advanced',
            5: 'Expert'
        }
        return proficiency_map.get(level, 'Unknown')
    
    def _render_template(self, template_name, cv_data):
        """Render HTML template with CV data"""
        template_path = os.path.join(self.templates_dir, template_name)
        
        # If template doesn't exist, create a default one
        if not os.path.exists(template_path):
            self._create_default_template(template_path)
        
        with open(template_path, 'r', encoding='utf-8') as f:
            template_content = f.read()
        
        template = Template(template_content)
        return template.render(**cv_data)
    
    def _generate_pdf(self, html_content):
        """Generate PDF from HTML content"""
        try:
            # Create PDF from HTML
            pdf_bytes = weasyprint.HTML(string=html_content).write_pdf()
            
            # Return as BytesIO buffer
            pdf_buffer = io.BytesIO(pdf_bytes)
            pdf_buffer.seek(0)
            
            return pdf_buffer
            
        except Exception as e:
            current_app.logger.error(f"Error generating PDF: {e}")
            raise
    
    def _create_default_template(self, template_path):
        """Create a default CV template if none exists"""
        default_template = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ user.name }} - CV</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: white;
        }
        
        .header {
            text-align: center;
            border-bottom: 3px solid #2c3e50;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        
        .profile-picture {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            object-fit: cover;
            margin-bottom: 15px;
            border: 4px solid #2c3e50;
        }
        
        .name {
            font-size: 2.5em;
            font-weight: bold;
            color: #2c3e50;
            margin: 10px 0;
        }
        
        .designation {
            font-size: 1.2em;
            color: #7f8c8d;
            margin-bottom: 10px;
        }
        
        .contact-info {
            display: flex;
            justify-content: center;
            flex-wrap: wrap;
            gap: 20px;
            margin-top: 15px;
        }
        
        .contact-item {
            font-size: 0.9em;
            color: #34495e;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 1.5em;
            font-weight: bold;
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 5px;
            margin-bottom: 15px;
        }
        
        .bio {
            font-style: italic;
            background: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .achievement-item {
            margin-bottom: 20px;
            padding: 15px;
            border-left: 4px solid #3498db;
            background: #f8f9fa;
        }
        
        .achievement-title {
            font-weight: bold;
            font-size: 1.1em;
            color: #2c3e50;
        }
        
        .achievement-organization {
            color: #7f8c8d;
            font-style: italic;
            margin-bottom: 5px;
        }
        
        .achievement-duration {
            color: #27ae60;
            font-weight: bold;
            font-size: 0.9em;
        }
        
        .achievement-description {
            margin-top: 8px;
            line-height: 1.5;
        }
        
        .skills-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .skill-item {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            border-left: 4px solid #e74c3c;
        }
        
        .skill-name {
            font-weight: bold;
            color: #2c3e50;
        }
        
        .skill-level {
            color: #e74c3c;
            font-size: 0.9em;
        }
        
        .proficiency-bar {
            width: 100%;
            height: 6px;
            background: #ecf0f1;
            border-radius: 3px;
            margin-top: 5px;
            overflow: hidden;
        }
        
        .proficiency-fill {
            height: 100%;
            background: #e74c3c;
            border-radius: 3px;
        }
        
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ecf0f1;
            color: #7f8c8d;
            font-size: 0.9em;
        }
        
        @media print {
            body { margin: 0; padding: 10px; }
            .contact-info { flex-direction: column; align-items: center; gap: 5px; }
        }
    </style>
</head>
<body>
    <!-- Header Section -->
    <div class="header">
        {% if profile.profile_picture_base64 %}
        <img src="data:image/jpeg;base64,{{ profile.profile_picture_base64 }}" alt="Profile Picture" class="profile-picture">
        {% endif %}
        <div class="name">{{ user.name }}</div>
        {% if user.designation %}
        <div class="designation">{{ user.designation }}</div>
        {% endif %}
        
        <div class="contact-info">
            {% if user.email %}
            <div class="contact-item">📧 {{ user.email }}</div>
            {% endif %}
            {% if user.phone %}
            <div class="contact-item">📞 {{ user.phone }}</div>
            {% endif %}
            {% if profile.hometown %}
            <div class="contact-item">📍 {{ profile.hometown }}</div>
            {% endif %}
            {% if profile.linkedin_url %}
            <div class="contact-item">💼 LinkedIn</div>
            {% endif %}
        </div>
    </div>

    <!-- Bio Section -->
    {% if profile.bio %}
    <div class="section">
        <div class="section-title">About Me</div>
        <div class="bio">{{ profile.bio }}</div>
    </div>
    {% endif %}

    <!-- Academic Information -->
    {% if profile.department or profile.batch or profile.cgpa %}
    <div class="section">
        <div class="section-title">Academic Information</div>
        <div class="achievement-item">
            {% if profile.department %}
            <div class="achievement-title">{{ profile.department }}</div>
            {% endif %}
            <div class="achievement-organization">Military Institute of Science & Technology (MIST)</div>
            {% if profile.batch %}
            <div class="achievement-duration">Batch: {{ profile.batch }}</div>
            {% endif %}
            {% if profile.cgpa %}
            <div class="achievement-description">CGPA: {{ profile.cgpa }}</div>
            {% endif %}
            {% if profile.current_semester %}
            <div class="achievement-description">Current Semester: {{ profile.current_semester }}</div>
            {% endif %}
        </div>
    </div>
    {% endif %}

    <!-- Education -->
    {% if achievements.education %}
    <div class="section">
        <div class="section-title">Education</div>
        {% for achievement in achievements.education %}
        <div class="achievement-item">
            <div class="achievement-title">{{ achievement.title }}</div>
            {% if achievement.organization %}
            <div class="achievement-organization">{{ achievement.organization }}</div>
            {% endif %}
            {% if achievement.duration %}
            <div class="achievement-duration">{{ achievement.duration }}</div>
            {% endif %}
            {% if achievement.grade_or_result %}
            <div class="achievement-description"><strong>Result:</strong> {{ achievement.grade_or_result }}</div>
            {% endif %}
            {% if achievement.description %}
            <div class="achievement-description">{{ achievement.description }}</div>
            {% endif %}
        </div>
        {% endfor %}
    </div>
    {% endif %}

    <!-- Work Experience -->
    {% if achievements.work %}
    <div class="section">
        <div class="section-title">Work Experience</div>
        {% for achievement in achievements.work %}
        <div class="achievement-item">
            <div class="achievement-title">{{ achievement.title }}</div>
            {% if achievement.organization %}
            <div class="achievement-organization">{{ achievement.organization }}</div>
            {% endif %}
            {% if achievement.duration %}
            <div class="achievement-duration">{{ achievement.duration }}</div>
            {% endif %}
            {% if achievement.location %}
            <div class="achievement-description"><strong>Location:</strong> {{ achievement.location }}</div>
            {% endif %}
            {% if achievement.description %}
            <div class="achievement-description">{{ achievement.description }}</div>
            {% endif %}
        </div>
        {% endfor %}
    </div>
    {% endif %}

    <!-- Projects -->
    {% if achievements.project %}
    <div class="section">
        <div class="section-title">Projects</div>
        {% for achievement in achievements.project %}
        <div class="achievement-item">
            <div class="achievement-title">{{ achievement.title }}</div>
            {% if achievement.organization %}
            <div class="achievement-organization">{{ achievement.organization }}</div>
            {% endif %}
            {% if achievement.duration %}
            <div class="achievement-duration">{{ achievement.duration }}</div>
            {% endif %}
            {% if achievement.description %}
            <div class="achievement-description">{{ achievement.description }}</div>
            {% endif %}
            {% if achievement.skills_learned %}
            <div class="achievement-description"><strong>Technologies:</strong> {{ achievement.skills_learned | join(', ') }}</div>
            {% endif %}
        </div>
        {% endfor %}
    </div>
    {% endif %}

    <!-- Technical Skills -->
    {% if skills.technical %}
    <div class="section">
        <div class="section-title">Technical Skills</div>
        <div class="skills-grid">
            {% for skill in skills.technical %}
            <div class="skill-item">
                <div class="skill-name">{{ skill.name }}</div>
                <div class="skill-level">{{ skill.proficiency_text }}</div>
                <div class="proficiency-bar">
                    <div class="proficiency-fill" style="width: {{ (skill.proficiency_level * 20) }}%"></div>
                </div>
            </div>
            {% endfor %}
        </div>
    </div>
    {% endif %}

    <!-- Languages -->
    {% if skills.language %}
    <div class="section">
        <div class="section-title">Languages</div>
        <div class="skills-grid">
            {% for skill in skills.language %}
            <div class="skill-item">
                <div class="skill-name">{{ skill.name }}</div>
                <div class="skill-level">{{ skill.proficiency_text }}</div>
                <div class="proficiency-bar">
                    <div class="proficiency-fill" style="width: {{ (skill.proficiency_level * 20) }}%"></div>
                </div>
            </div>
            {% endfor %}
        </div>
    </div>
    {% endif %}

    <!-- Awards & Certifications -->
    {% if achievements.award or achievements.certification %}
    <div class="section">
        <div class="section-title">Awards & Certifications</div>
        {% for achievement in (achievements.award or []) + (achievements.certification or []) %}
        <div class="achievement-item">
            <div class="achievement-title">{{ achievement.title }}</div>
            {% if achievement.organization %}
            <div class="achievement-organization">{{ achievement.organization }}</div>
            {% endif %}
            {% if achievement.duration %}
            <div class="achievement-duration">{{ achievement.duration }}</div>
            {% endif %}
            {% if achievement.description %}
            <div class="achievement-description">{{ achievement.description }}</div>
            {% endif %}
        </div>
        {% endfor %}
    </div>
    {% endif %}

    <!-- Footer -->
    <div class="footer">
        CV generated on {{ generated_date }}
    </div>
</body>
</html>
        '''
        
        with open(template_path, 'w', encoding='utf-8') as f:
            f.write(default_template.strip())
