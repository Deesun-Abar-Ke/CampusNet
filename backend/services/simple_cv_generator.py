"""
Simple CV Generator Service
Generates professional CV from user profile data using basic HTML/CSS
No external dependencies required for PDF conversion
"""

import os
import base64
from datetime import datetime
from typing import Dict, List, Optional
from models import Profile, Achievement

class SimpleCVGenerator:
    def __init__(self):
        self.output_dir = os.path.join('temp', 'generated_cvs')
        # Create output directory if it doesn't exist
        os.makedirs(self.output_dir, exist_ok=True)
    
    def generate_cv(self, user_id: int) -> Dict:
        """Generate CV for a user"""
        try:
            # Get user profile data
            profile = Profile.query.filter_by(user_id=user_id).first()
            if not profile:
                return {'success': False, 'message': 'Profile not found'}
            
            # Get achievements
            achievements = Achievement.query.filter_by(user_id=user_id).order_by(
                Achievement.date.desc().nullslast()
            ).all()
            
            # Generate HTML CV
            html_content = self._generate_html_cv(profile, achievements)
            
            # Save as HTML file
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"cv_{user_id}_{timestamp}.html"
            file_path = os.path.join(self.output_dir, filename)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            return {
                'success': True,
                'file_path': file_path,
                'filename': filename,
                'file_type': 'html',
                'message': 'CV generated successfully'
            }
            
        except Exception as e:
            return {'success': False, 'message': f'Error generating CV: {str(e)}'}
    
    def _generate_html_cv(self, profile, achievements: List) -> str:
        """Generate HTML CV using a simple template"""
        
        # Convert profile picture to base64 if exists
        profile_pic_data = ""
        if profile.profile_picture:
            try:
                profile_pic_data = f"data:image/jpeg;base64,{base64.b64encode(profile.profile_picture).decode()}"
            except:
                profile_pic_data = ""
        
        # Group achievements by category
        education = [a for a in achievements if a.category == 'education']
        experience = [a for a in achievements if a.category == 'experience']
        skills = [a for a in achievements if a.category == 'skills']
        projects = [a for a in achievements if a.category == 'projects']
        certifications = [a for a in achievements if a.category == 'certifications']
        other = [a for a in achievements if a.category not in ['education', 'experience', 'skills', 'projects', 'certifications']]
        
        # Get user info safely
        user_name = getattr(profile.user, 'full_name', 'User Name') or 'User Name'
        user_email = getattr(profile.user, 'email', 'email@example.com') or 'email@example.com'
        user_phone = getattr(profile.user, 'phone_number', None) or 'Not provided'
        user_student_id = getattr(profile.user, 'student_id', None) or 'Not provided'
        user_bio = profile.bio or ''
        
        # Generate HTML
        html_template = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CV - {user_name}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            color: #333;
            background: white;
            padding: 20px;
        }}
        
        .cv-container {{
            max-width: 800px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }}
        
        .header {{
            background: linear-gradient(135deg, #1976D2, #42A5F5);
            color: white;
            text-align: center;
            padding: 30px 20px;
        }}
        
        .profile-pic {{
            width: 120px;
            height: 120px;
            border-radius: 50%;
            margin: 0 auto 20px;
            object-fit: cover;
            border: 4px solid white;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }}
        
        .profile-placeholder {{
            width: 120px;
            height: 120px;
            border-radius: 50%;
            margin: 0 auto 20px;
            background: rgba(255,255,255,0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
            font-weight: bold;
            border: 4px solid white;
        }}
        
        .name {{
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 10px;
        }}
        
        .contact-info {{
            font-size: 16px;
            margin-bottom: 15px;
        }}
        
        .bio {{
            font-style: italic;
            font-size: 16px;
            max-width: 600px;
            margin: 0 auto;
        }}
        
        .content {{
            padding: 30px;
        }}
        
        .section {{
            margin-bottom: 35px;
        }}
        
        .section-title {{
            font-size: 24px;
            font-weight: bold;
            color: #1976D2;
            border-bottom: 3px solid #1976D2;
            padding-bottom: 8px;
            margin-bottom: 20px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }}
        
        .achievement-item {{
            margin-bottom: 20px;
            padding: 20px;
            background: #f8f9fa;
            border-left: 5px solid #1976D2;
            border-radius: 5px;
        }}
        
        .achievement-title {{
            font-size: 18px;
            font-weight: bold;
            color: #1976D2;
            margin-bottom: 8px;
        }}
        
        .achievement-details {{
            color: #555;
            margin-bottom: 8px;
            line-height: 1.6;
        }}
        
        .achievement-date {{
            color: #888;
            font-size: 14px;
            font-style: italic;
            text-align: right;
        }}
        
        .skills-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }}
        
        .skill-item {{
            background: linear-gradient(135deg, #e3f2fd, #bbdefb);
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            color: #1976D2;
            font-weight: 600;
            border: 2px solid #1976D2;
        }}
        
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            background: #f5f5f5;
            color: #888;
            font-size: 12px;
            border-top: 1px solid #ddd;
        }}
        
        @media print {{
            body {{ padding: 0; }}
            .cv-container {{ box-shadow: none; }}
            .footer {{ background: none; }}
        }}
        
        @media (max-width: 600px) {{
            .skills-grid {{ grid-template-columns: 1fr; }}
            .name {{ font-size: 24px; }}
            .content {{ padding: 20px; }}
        }}
    </style>
</head>
<body>
    <div class="cv-container">
        <!-- Header Section -->
        <div class="header">
            {f'<img src="{profile_pic_data}" alt="Profile Picture" class="profile-pic">' if profile_pic_data else f'<div class="profile-placeholder">{user_name[0].upper()}</div>'}
            <div class="name">{user_name}</div>
            <div class="contact-info">
                📧 {user_email} | 📱 {user_phone} | 🆔 {user_student_id}
            </div>
            {f'<div class="bio">{user_bio}</div>' if user_bio else ''}
        </div>
        
        <div class="content">
            <!-- Education Section -->
            {self._generate_section_html('Education', education) if education else ''}
            
            <!-- Experience Section -->
            {self._generate_section_html('Professional Experience', experience) if experience else ''}
            
            <!-- Skills Section -->
            {self._generate_skills_section_html(skills) if skills else ''}
            
            <!-- Projects Section -->
            {self._generate_section_html('Projects', projects) if projects else ''}
            
            <!-- Certifications Section -->
            {self._generate_section_html('Certifications', certifications) if certifications else ''}
            
            <!-- Other Achievements -->
            {self._generate_section_html('Other Achievements', other) if other else ''}
        </div>
        
        <!-- Footer -->
        <div class="footer">
            Generated on {datetime.now().strftime('%B %d, %Y')} | CampusNet CV Generator<br>
            Professional CV created automatically from your profile data
        </div>
    </div>
</body>
</html>
        """
        
        return html_template
    
    def _generate_section_html(self, title: str, achievements: List) -> str:
        """Generate HTML for a section"""
        if not achievements:
            return ""
        
        items_html = ""
        for achievement in achievements:
            date_str = achievement.date.strftime('%B %Y') if achievement.date else ''
            items_html += f"""
            <div class="achievement-item">
                <div class="achievement-title">{achievement.title}</div>
                <div class="achievement-details">{achievement.details}</div>
                {f'<div class="achievement-date">{date_str}</div>' if date_str else ''}
            </div>
            """
        
        return f"""
        <div class="section">
            <div class="section-title">{title}</div>
            {items_html}
        </div>
        """
    
    def _generate_skills_section_html(self, skills: List) -> str:
        """Generate HTML for skills section with special formatting"""
        if not skills:
            return ""
        
        skills_html = ""
        for skill in skills:
            skills_html += f'<div class="skill-item">{skill.title}</div>'
        
        return f"""
        <div class="section">
            <div class="section-title">Skills & Technologies</div>
            <div class="skills-grid">
                {skills_html}
            </div>
        </div>
        """
