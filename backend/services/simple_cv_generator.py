import os
import base64
import subprocess
import tempfile
from datetime import datetime
from typing import Dict, List, Optional
from models import Profile, Achievement, Skill
from flask import current_app

class SimpleCVGenerator:
    def __init__(self):
        self.output_dir = os.path.join('temp', 'generated_cvs')
        # Create output directory if it doesn't exist
        os.makedirs(self.output_dir, exist_ok=True)

    def generate_cv(self, user_id: int) -> Dict:
        """Generate CV for a user in LaTeX format"""
        try:
            # Get user profile data
            profile = Profile.query.filter_by(user_id=user_id).first()
            if not profile:
                return {'success': False, 'message': 'Profile not found'}
            
            # Get achievements and skills using profile_id
            achievements = Achievement.query.filter_by(profile_id=profile.id).order_by(
                Achievement.start_date.desc().nullslast(),
                Achievement.created_at.desc()
            ).all()
            
            skills = Skill.query.filter_by(profile_id=profile.id).all()
            
            # Check if pdflatex is available
            if not self._check_pdflatex():
                current_app.logger.warning("pdflatex not found, generating LaTeX only")
                return self._generate_latex_only(profile, achievements, skills, user_id)
            
            # Generate LaTeX CV and compile to PDF
            return self._generate_pdf_cv(profile, achievements, skills, user_id)
            
        except Exception as e:
            current_app.logger.error(f"Error generating CV: {str(e)}")
            return {'success': False, 'message': f'Error generating CV: {str(e)}'}
    
    def _check_pdflatex(self) -> bool:
        """Check if pdflatex is available on the system"""
        try:
            result = subprocess.run(['pdflatex', '--version'], 
                                  capture_output=True, text=True, timeout=5)
            return result.returncode == 0
        except (subprocess.SubprocessError, FileNotFoundError):
            return False
    
    def _generate_latex_only(self, profile, achievements: List, skills: List, user_id: int) -> Dict:
        """Generate only LaTeX file without compilation"""
        try:
            latex_content = self._generate_latex_cv(profile, achievements, skills)
            
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"cv_{user_id}_{timestamp}.tex"
            file_path = os.path.join(self.output_dir, filename)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(latex_content)
            
            return {
                'success': True,
                'file_path': file_path,
                'filename': filename,
                'file_type': 'tex',
                'message': 'LaTeX CV generated successfully (pdflatex not available for PDF compilation)'
            }
        except Exception as e:
            return {'success': False, 'message': f'Error generating LaTeX: {str(e)}'}
    
    def _generate_pdf_cv(self, profile, achievements: List, skills: List, user_id: int) -> Dict:
        """Generate LaTeX file and compile to PDF"""
        try:
            latex_content = self._generate_latex_cv(profile, achievements, skills)
            
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            base_filename = f"cv_{user_id}_{timestamp}"
            tex_filename = f"{base_filename}.tex"
            pdf_filename = f"{base_filename}.pdf"
            
            tex_path = os.path.join(self.output_dir, tex_filename)
            pdf_path = os.path.join(self.output_dir, pdf_filename)
            
            # Save LaTeX file
            with open(tex_path, 'w', encoding='utf-8') as f:
                f.write(latex_content)
            
            # Compile to PDF using subprocess (safer than os.system)
            try:
                result = subprocess.run([
                    'pdflatex', 
                    '-output-directory', self.output_dir,
                    '-interaction=nonstopmode',  # Don't stop on errors
                    tex_path
                ], capture_output=True, text=True, timeout=30)
                
                # Check if PDF was created successfully
                if os.path.exists(pdf_path):
                    # Clean up auxiliary files
                    self._cleanup_latex_files(self.output_dir, base_filename)
                    
                    return {
                        'success': True,
                        'file_path': pdf_path,
                        'filename': pdf_filename,
                        'file_type': 'pdf',
                        'message': 'PDF CV generated successfully'
                    }
                else:
                    current_app.logger.error(f"PDF compilation failed: {result.stderr}")
                    return {
                        'success': False,
                        'message': f'PDF compilation failed: {result.stderr[:200]}'
                    }
            except subprocess.TimeoutExpired:
                return {'success': False, 'message': 'PDF compilation timed out'}
            except Exception as e:
                return {'success': False, 'message': f'PDF compilation error: {str(e)}'}
                
        except Exception as e:
            return {'success': False, 'message': f'Error generating PDF CV: {str(e)}'}
    
    def _cleanup_latex_files(self, directory: str, base_filename: str):
        """Clean up auxiliary LaTeX files"""
        extensions = ['.aux', '.log', '.out', '.toc', '.fdb_latexmk', '.fls']
        for ext in extensions:
            aux_file = os.path.join(directory, base_filename + ext)
            try:
                if os.path.exists(aux_file):
                    os.remove(aux_file)
            except Exception:
                pass  # Ignore cleanup errors
            return {'success': False, 'message': f'Error generating CV: {str(e)}'}
    
    def _generate_latex_cv(self, profile, achievements: List, skills: Optional[List] = None) -> str:
        """Generate LaTeX CV using the provided template"""
        
        # Convert profile picture to base64 if exists
        profile_pic_data = ""
        if profile.profile_picture:
            try:
                profile_pic_data = base64.b64encode(profile.profile_picture).decode()
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
        
        # LaTeX template for CV
        latex_template = f"""
\\documentclass[11pt,a4paper]{{article}}
\\usepackage[left=0.75in,top=0.6in,right=0.75in,bottom=0.6in]{{geometry}}
\\usepackage{{titlesec}}
\\usepackage{{enumitem}}
\\usepackage{{hyperref}}
\\usepackage{{xcolor}}

\\definecolor{{headingcolor}}{{RGB}}{{96,125,139}}

\\titleformat{{\\section}}{{\\Large\\bfseries\\color{{headingcolor}}}}{{}}{{0em}}{{}}
\\titlespacing*{{\\section}}{{0pt}}{{*1.5}}{{*0.5}}

\\titleformat{{\\subsection}}{{\\bfseries}}{{}}{{0em}}{{}}
\\titlespacing*{{\\subsection}}{{0pt}}{{*1}}{{*0.25}}

\\setlength{{\\parskip}}{{0.5em}}
\\pagenumbering{{gobble}}
\\setlength{{\\parindent}}{{0pt}}

\\setlist[itemize]{{leftmargin=2.8em, itemsep=0.3em, parsep=0pt}}

\\begin{{document}}

{{\\huge\\bfseries\\color{{headingcolor}} {user_name}}}

{{\\small
{user_email} • {user_phone} • {user_student_id}
}}

\\noindent{{\\color{{headingcolor}}\\rule{{\\linewidth}}{{0.4pt}}}}

\\small{{{user_bio}}}

\\section{{Professional Experience}}

{self._generate_section_latex('Professional Experience', experience)}

\\section{{Education}}

{self._generate_section_latex('Education', education)}

\\section{{Skills}}

{self._generate_skills_section_latex(skills)}

\\section{{Projects}}

{self._generate_section_latex('Projects', projects)}

\\section{{Certifications}}

{self._generate_section_latex('Certifications', certifications)}

\\section{{Other Achievements}}

{self._generate_section_latex('Other Achievements', other)}

\\end{{document}}
"""
        
        return latex_template
    
    def _generate_section_latex(self, title: str, achievements: List) -> str:
        """Generate LaTeX for a section"""
        if not achievements:
            return ""
        
        items_latex = ""
        for achievement in achievements:
            date_str = achievement.date.strftime('%B %Y') if achievement.date else ''
            items_latex += f"""
\\subsection{{{achievement.title}}}
\\begin{{itemize}}
    \\item {achievement.details}
    \\item \\textit{{{date_str}}}
\\end{{itemize}}
"""
        
        return f"""
\\section{{{title}}}
{items_latex}
"""
    
    def _generate_skills_section_latex(self, skills: List) -> str:
        """Generate LaTeX for skills section with special formatting"""
        if not skills:
            return ""
        
        skills_latex = ""
        for skill in skills:
            skills_latex += f'\\item {skill.title}\n'
        
        return f"""
\\section{{Skills & Technologies}}
\\begin{{itemize}}
{skills_latex}
\\end{{itemize}}
"""
