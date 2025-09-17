"""
Initialize Profile System
Sets up CV templates and creates initial data
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app
from models import db, CVTemplate
from datetime import datetime

def init_cv_templates():
    """Initialize CV templates in the database"""
    with app.app_context():
        # Check if templates already exist
        existing_templates = CVTemplate.query.count()
        if existing_templates > 0:
            print(f"✅ CV templates already exist ({existing_templates} templates)")
            return
        
        # Create default templates
        templates = [
            {
                'name': 'Modern Professional',
                'description': 'Clean and modern template suitable for tech professionals',
                'template_file': 'modern_template.html'
            },
            {
                'name': 'Academic',
                'description': 'Academic-focused template with emphasis on education and research',
                'template_file': 'academic_template.html'
            },
            {
                'name': 'Creative',
                'description': 'Creative template with vibrant colors and modern design',
                'template_file': 'creative_template.html'
            }
        ]
        
        for template_data in templates:
            template = CVTemplate(
                name=template_data['name'],
                description=template_data['description'],
                template_file=template_data['template_file'],
                is_active=True,
                created_at=datetime.utcnow()
            )
            db.session.add(template)
        
        try:
            db.session.commit()
            print(f"✅ Created {len(templates)} CV templates")
            
            # List created templates
            for template in templates:
                print(f"   • {template['name']}: {template['description']}")
                
        except Exception as e:
            db.session.rollback()
            print(f"❌ Error creating CV templates: {e}")

def main():
    """Main initialization function"""
    print("🚀 INITIALIZING PROFILE SYSTEM")
    print("="*50)
    
    print("\n📋 Setting up CV templates...")
    init_cv_templates()
    
    print("\n✅ Profile system initialization complete!")
    print("\nAvailable Profile API endpoints:")
    print("• GET  /api/profile/profile - Get user profile")
    print("• PUT  /api/profile/profile - Update user profile")
    print("• POST /api/profile/profile/picture - Upload profile picture")
    print("• GET  /api/profile/profile/picture - Get profile picture")
    print("• POST /api/profile/achievements - Add achievement")
    print("• PUT  /api/profile/achievements/<id> - Update achievement")
    print("• DELETE /api/profile/achievements/<id> - Delete achievement")
    print("• POST /api/profile/skills - Add skill")
    print("• PUT  /api/profile/skills/<id> - Update skill")
    print("• DELETE /api/profile/skills/<id> - Delete skill")
    print("• POST /api/profile/cv/generate - Generate CV")
    print("• GET  /api/profile/cv/templates - Get CV templates")

if __name__ == "__main__":
    main()
