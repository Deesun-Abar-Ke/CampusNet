"""
Professional PDF CV Generator using ReportLab
Generates beautiful PDF CVs from user profile data without external dependencies
"""

import io
import base64
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY, TA_RIGHT
from flask import current_app
from models import Profile, Achievement, Skill, Users

class ReportLabCVGenerator:
    """Service for generating professional PDF CVs using ReportLab"""
    
    def __init__(self):
        self.styles = getSampleStyleSheet()
        self._create_custom_styles()
    
    def _create_custom_styles(self):
        """Create custom styles for the CV"""
        self.styles.add(ParagraphStyle(
            name='CVTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            spaceAfter=12,
            alignment=TA_CENTER,
            textColor=colors.Color(0.17, 0.24, 0.31)  # Dark blue-gray
        ))
        
        self.styles.add(ParagraphStyle(
            name='CVSubTitle',
            parent=self.styles['Heading2'],
            fontSize=16,
            spaceAfter=6,
            spaceBefore=12,
            textColor=colors.Color(0.20, 0.61, 0.86),  # Blue
            borderWidth=1,
            borderColor=colors.Color(0.20, 0.61, 0.86),
            borderPadding=5
        ))
        
        self.styles.add(ParagraphStyle(
            name='ContactInfo',
            parent=self.styles['Normal'],
            fontSize=10,
            alignment=TA_CENTER,
            spaceAfter=6
        ))
        
        self.styles.add(ParagraphStyle(
            name='SectionContent',
            parent=self.styles['Normal'],
            fontSize=10,
            spaceAfter=6,
            alignment=TA_JUSTIFY
        ))
        
        self.styles.add(ParagraphStyle(
            name='ItemTitle',
            parent=self.styles['Normal'],
            fontSize=11,
            spaceAfter=3,
            textColor=colors.Color(0.17, 0.24, 0.31),
            fontName='Helvetica-Bold'
        ))
        
        self.styles.add(ParagraphStyle(
            name='ItemOrg',
            parent=self.styles['Normal'],
            fontSize=10,
            spaceAfter=3,
            textColor=colors.Color(0.20, 0.61, 0.86),
            fontName='Helvetica-Oblique'
        ))
    
    def generate_cv_pdf(self, user_id: int) -> dict:
        """Generate professional PDF CV from user profile data"""
        try:
            # Get user and profile data
            user = Users.query.get(user_id)
            profile = Profile.query.filter_by(user_id=user_id).first()
            
            if not user:
                return {'success': False, 'message': 'User not found'}
            
            if not profile:
                return {'success': False, 'message': 'Profile not found'}
            
            # Get achievements and skills through profile
            achievements = Achievement.query.filter_by(profile_id=profile.id).all()
            skills = Skill.query.filter_by(profile_id=profile.id).all()
            
            # Create PDF
            pdf_buffer = io.BytesIO()
            doc = SimpleDocTemplate(
                pdf_buffer,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=18
            )
            
            # Build the document
            story = []
            story.extend(self._build_header(user, profile))
            story.extend(self._build_personal_info(profile))
            story.extend(self._build_bio_section(profile))
            story.extend(self._build_achievements_sections(achievements))
            story.extend(self._build_skills_section(skills))
            story.extend(self._build_footer())
            
            # Build PDF
            doc.build(story)
            
            # Get PDF bytes
            pdf_bytes = pdf_buffer.getvalue()
            pdf_buffer.close()
            
            return {
                'success': True,
                'pdf_bytes': pdf_bytes,
                'filename': f"CV_{user.name.replace(' ', '_')}_{datetime.now().strftime('%Y%m%d')}.pdf",
                'message': 'CV generated successfully'
            }
            
        except Exception as e:
            current_app.logger.error(f"Error generating CV: {e}")
            return {'success': False, 'message': f'Error generating CV: {str(e)}'}
    
    def _build_header(self, user, profile):
        """Build the header section with name and profile picture"""
        elements = []
        
        # Profile picture (if available)
        if profile.profile_picture:
            try:
                # Create image from profile picture
                img_data = io.BytesIO(profile.profile_picture)
                img = Image(img_data)
                img.drawHeight = 100
                img.drawWidth = 100
                img.hAlign = 'CENTER'
                elements.append(img)
                elements.append(Spacer(1, 12))
            except Exception as e:
                current_app.logger.warning(f"Could not process profile picture: {e}")
        
        # Name
        name = user.name or "User Name"
        elements.append(Paragraph(name, self.styles['CVTitle']))
        
        # Contact information
        contact_info = []
        if user.email:
            contact_info.append(f"Email: {user.email}")
        if hasattr(user, 'phone_number') and user.phone_number:
            contact_info.append(f"Phone: {user.phone_number}")
        if hasattr(user, 'student_id') and user.student_id:
            contact_info.append(f"Student ID: {user.student_id}")
        
        if contact_info:
            elements.append(Paragraph(" | ".join(contact_info), self.styles['ContactInfo']))
        
        # Department and academic info
        academic_info = []
        if profile.department:
            academic_info.append(f"Department: {profile.department}")
        if profile.batch:
            academic_info.append(f"Batch: {profile.batch}")
        if profile.current_semester:
            academic_info.append(f"Semester: {profile.current_semester}")
        if profile.cgpa:
            academic_info.append(f"CGPA: {profile.cgpa}")
        
        if academic_info:
            elements.append(Paragraph(" | ".join(academic_info), self.styles['ContactInfo']))
        
        # Links
        links = []
        if profile.github_url:
            links.append(f"GitHub: {profile.github_url}")
        if profile.linkedin_url:
            links.append(f"LinkedIn: {profile.linkedin_url}")
        if profile.portfolio_url:
            links.append(f"Portfolio: {profile.portfolio_url}")
        
        if links:
            elements.append(Paragraph(" | ".join(links), self.styles['ContactInfo']))
        
        elements.append(Spacer(1, 20))
        return elements
    
    def _build_personal_info(self, profile):
        """Build personal information section"""
        elements = []
        
        # Create a table for personal information
        data = []
        if profile.department:
            data.append(['Department:', profile.department])
        if profile.batch:
            data.append(['Batch:', profile.batch])
        if profile.current_semester:
            data.append(['Current Semester:', str(profile.current_semester)])
        if profile.cgpa:
            data.append(['CGPA:', str(profile.cgpa)])
        
        if data:
            elements.append(Paragraph("Personal Information", self.styles['CVSubTitle']))
            
            table = Table(data, colWidths=[2*inch, 4*inch])
            table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
                ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 0), (-1, -1), 10),
                ('ROWBACKGROUNDS', (0, 0), (-1, -1), [colors.white, colors.Color(0.97, 0.98, 0.99)]),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.lightgrey)
            ]))
            
            elements.append(table)
            elements.append(Spacer(1, 12))
        
        return elements
    
    def _build_bio_section(self, profile):
        """Build bio/about me section"""
        elements = []
        
        if profile.bio:
            elements.append(Paragraph("About Me", self.styles['CVSubTitle']))
            elements.append(Paragraph(profile.bio, self.styles['SectionContent']))
            elements.append(Spacer(1, 12))
        
        return elements
    
    def _build_achievements_sections(self, achievements):
        """Build achievements sections grouped by category"""
        elements = []
        
        # Group achievements by category
        achievements_by_category = {}
        for achievement in achievements:
            category = achievement.category or 'other'
            if category not in achievements_by_category:
                achievements_by_category[category] = []
            achievements_by_category[category].append(achievement)
        
        # Define section order and titles
        section_order = {
            'education': 'Education',
            'experience': 'Work Experience',
            'projects': 'Projects',
            'certifications': 'Certifications',
            'awards': 'Awards & Recognition',
            'other': 'Other Achievements'
        }
        
        for category in section_order:
            if category in achievements_by_category:
                achievements_list = achievements_by_category[category]
                section_title = section_order[category]
                
                elements.append(Paragraph(section_title, self.styles['CVSubTitle']))
                
                for achievement in achievements_list:
                    # Achievement title
                    if achievement.title:
                        elements.append(Paragraph(achievement.title, self.styles['ItemTitle']))
                    
                    # Organization and date
                    org_date = []
                    if achievement.organization:
                        org_date.append(achievement.organization)
                    
                    # Handle date fields properly
                    if achievement.start_date:
                        if achievement.is_current:
                            date_str = f"{achievement.start_date.strftime('%B %Y')} - Present"
                        elif achievement.end_date:
                            date_str = f"{achievement.start_date.strftime('%B %Y')} - {achievement.end_date.strftime('%B %Y')}"
                        else:
                            date_str = achievement.start_date.strftime('%B %Y')
                        org_date.append(date_str)
                    elif achievement.end_date:
                        org_date.append(achievement.end_date.strftime('%B %Y'))
                    
                    if org_date:
                        elements.append(Paragraph(" - ".join(org_date), self.styles['ItemOrg']))
                    
                    # Grade
                    if achievement.grade_or_result:
                        elements.append(Paragraph(f"Grade: {achievement.grade_or_result}", self.styles['SectionContent']))
                    
                    # Location
                    if achievement.location:
                        elements.append(Paragraph(f"Location: {achievement.location}", self.styles['SectionContent']))
                    
                    # Description
                    if achievement.description:
                        elements.append(Paragraph(achievement.description, self.styles['SectionContent']))
                    
                    elements.append(Spacer(1, 8))
                
                elements.append(Spacer(1, 12))
        
        return elements
    
    def _build_skills_section(self, skills):
        """Build skills section"""
        elements = []
        
        if not skills:
            return elements
        
        elements.append(Paragraph("Skills", self.styles['CVSubTitle']))
        
        # Group skills by category
        skills_by_category = {}
        for skill in skills:
            category = skill.category or 'other'
            if category not in skills_by_category:
                skills_by_category[category] = []
            skills_by_category[category].append(skill)
        
        # Create table data for skills
        for category, category_skills in skills_by_category.items():
            if category_skills:
                elements.append(Paragraph(f"{category.title()} Skills:", self.styles['ItemTitle']))
                
                skill_data = []
                for skill in category_skills:
                    skill_info = [skill.name]
                    
                    # Add proficiency level
                    if skill.proficiency_level:
                        proficiency_text = self._get_proficiency_text(skill.proficiency_level)
                        skill_info.append(proficiency_text)
                    
                    # Add years of experience
                    if skill.years_of_experience:
                        skill_info.append(f"{skill.years_of_experience} years")
                    
                    skill_data.append([" - ".join(skill_info)])
                
                if skill_data:
                    skill_table = Table(skill_data, colWidths=[6*inch])
                    skill_table.setStyle(TableStyle([
                        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
                        ('FONTSIZE', (0, 0), (-1, -1), 10),
                        ('ROWBACKGROUNDS', (0, 0), (-1, -1), [colors.white, colors.Color(0.97, 0.98, 0.99)]),
                    ]))
                    
                    elements.append(skill_table)
                    elements.append(Spacer(1, 8))
        
        return elements
    
    def _get_proficiency_text(self, level):
        """Convert numeric proficiency level to text"""
        if level is None:
            return 'Not specified'
        
        level_map = {
            1: 'Beginner',
            2: 'Basic', 
            3: 'Intermediate',
            4: 'Advanced',
            5: 'Expert'
        }
        return level_map.get(int(level), 'Not specified')
    
    def _build_footer(self):
        """Build footer section"""
        elements = []
        
        elements.append(Spacer(1, 20))
        elements.append(Paragraph(
            f"CV generated on {datetime.now().strftime('%B %d, %Y')} | CampusNet Professional CV Generator",
            self.styles['ContactInfo']
        ))
        
        return elements
