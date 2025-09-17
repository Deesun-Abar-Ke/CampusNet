"""
MIST Knowledge Upload Utility
Upload and manage MIST institutional knowledge for the RAG system
"""

import os
import sys
from pathlib import Path
from flask import Flask
from models import db, InstitutionalKnowledge
from config import Config
from services.rag_service import RAGService
import json
from typing import Optional

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = Config.SQLALCHEMY_DATABASE_URI
db.init_app(app)

class MISTKnowledgeUploader:
    def __init__(self):
        self.rag_service = RAGService()
        
    def upload_text_content(self, title: str, content: str, category: str = "general"):
        """Upload text content directly"""
        print(f"📝 Uploading: {title}")
        print(f"   Category: {category}")
        print(f"   Content length: {len(content)} characters")
        
        try:
            success = self.rag_service.process_institutional_knowledge(
                title=title,
                content=content,
                content_type='text'
            )
            if success:
                print(f"✅ Successfully uploaded: {title}")
                return True
            else:
                print(f"❌ Failed to upload: {title}")
                return False
        except Exception as e:
            print(f"❌ Error uploading {title}: {e}")
            return False
    
    def upload_from_file(self, file_path: str, title: Optional[str] = None, category: str = "general"):
        """Upload content from a file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if not title:
                title = Path(file_path).stem.replace('_', ' ').title()
            
            return self.upload_text_content(title, content, category)
            
        except Exception as e:
            print(f"❌ Error reading file {file_path}: {e}")
            return False
    
    def upload_multiple_files(self, directory_path: str, category: str = "general"):
        """Upload all text files from a directory"""
        directory = Path(directory_path)
        if not directory.exists():
            print(f"❌ Directory not found: {directory_path}")
            return
        
        text_files = list(directory.glob("*.txt")) + list(directory.glob("*.md"))
        
        print(f"📁 Found {len(text_files)} text files in {directory_path}")
        
        for file_path in text_files:
            self.upload_from_file(str(file_path), category=category)
    
    def list_current_knowledge(self):
        """List all current institutional knowledge"""
        knowledge_entries = InstitutionalKnowledge.query.all()
        
        print(f"\n📚 Current Knowledge Base ({len(knowledge_entries)} entries):")
        print("=" * 60)
        
        for knowledge in knowledge_entries:
            print(f"ID: {knowledge.id}")
            print(f"Title: {knowledge.title}")
            print(f"Category: {knowledge.category}")
            print(f"Content Length: {len(knowledge.content)} chars")
            print(f"Created: {knowledge.last_updated}")
            print("-" * 40)

def main():
    with app.app_context():
        uploader = MISTKnowledgeUploader()
        
        print("🎓 MIST Knowledge Upload Utility")
        print("=" * 50)
        
        while True:
            print("\nChoose an option:")
            print("1. Upload text content directly")
            print("2. Upload from file")
            print("3. Upload all files from directory")
            print("4. List current knowledge")
            print("5. Add sample MIST data")
            print("6. Exit")
            
            choice = input("\nEnter your choice (1-6): ").strip()
            
            if choice == "1":
                title = input("Enter title: ")
                category = input("Enter category (academics/facilities/general): ") or "general"
                print("Enter content (press Ctrl+Z then Enter on Windows, or Ctrl+D on Unix when done):")
                content = sys.stdin.read()
                uploader.upload_text_content(title, content, category)
                
            elif choice == "2":
                file_path = input("Enter file path: ")
                title = input("Enter title (or press Enter to auto-generate): ") or None
                category = input("Enter category (academics/facilities/general): ") or "general"
                uploader.upload_from_file(file_path, title, category)
                
            elif choice == "3":
                directory = input("Enter directory path: ")
                category = input("Enter category (academics/facilities/general): ") or "general"
                uploader.upload_multiple_files(directory, category)
                
            elif choice == "4":
                uploader.list_current_knowledge()
                
            elif choice == "5":
                add_sample_data(uploader)
                
            elif choice == "6":
                print("👋 Goodbye!")
                break
                
            else:
                print("❌ Invalid choice. Please try again.")

def add_sample_data(uploader):
    """Add comprehensive sample MIST data"""
    print("📊 Adding Sample MIST Data...")
    
    sample_data = [
        {
            "title": "MIST Admission Requirements",
            "category": "academics",
            "content": """
# MIST Admission Requirements

## Undergraduate Programs
### Eligibility:
- SSC and HSC (or equivalent) with minimum GPA requirements
- Age limit: 18-22 years for male candidates, 18-20 years for female candidates
- Physical and medical fitness as per Bangladesh Army standards

### Required Documents:
- Original SSC and HSC certificates
- Character certificate from last institution
- Medical certificate
- National ID card/Birth certificate
- Recent passport-size photographs

### Selection Process:
1. Written examination (Mathematics, Physics, Chemistry, English)
2. Viva voce (oral examination)
3. Medical examination
4. Physical fitness test

## Graduate Programs
### M.Sc. Engineering:
- B.Sc. Engineering with minimum CGPA requirement
- TOEFL/IELTS for international students

### MBA Program:
- Bachelor's degree in any discipline
- BBA graduates preferred
- Work experience advantageous

## Application Deadline:
- Usually in May-June each year
- Check MIST website for exact dates

## Fees Structure:
- Admission fee, tuition fee, and other charges as per MIST regulations
- Scholarship opportunities available for deserving students
            """
        },
        {
            "title": "MIST Research and Innovation",
            "category": "academics",
            "content": """
# Research and Innovation at MIST

## Research Areas

### Computer Science and Engineering:
- Artificial Intelligence and Machine Learning
- Computer Vision and Image Processing
- Software Engineering and Development
- Network Security and Cybersecurity
- Database Systems and Data Mining

### Electrical and Electronic Engineering:
- Power Systems Engineering
- Control Systems and Automation
- Signal Processing and Communications
- Renewable Energy Systems
- Electronics and Circuit Design

### Mechanical Engineering:
- Thermal Engineering and Energy Systems
- Manufacturing and Industrial Engineering
- Aerospace Engineering Applications
- Robotics and Automation
- Materials Science and Engineering

### Civil Engineering:
- Structural Engineering and Design
- Environmental Engineering
- Transportation Engineering
- Geotechnical Engineering
- Water Resources Engineering

### Naval Architecture and Marine Engineering:
- Ship Design and Construction
- Marine Propulsion Systems
- Offshore Engineering
- Marine Environment and Safety

## Research Facilities:
- Modern laboratories with state-of-the-art equipment
- High-performance computing facilities
- CAD/CAM and simulation software
- Research collaboration with international universities
- Industry partnerships for applied research

## Publications and Conferences:
- Regular publication in international journals
- Participation in national and international conferences
- Research funding from government and private organizations
            """
        },
        {
            "title": "MIST Campus Facilities",
            "category": "facilities",
            "content": """
# MIST Campus Facilities

## Academic Facilities

### Libraries:
- Central Library with over 50,000 books
- Digital library with online journals and databases
- Department-specific libraries
- Study rooms and group discussion areas
- 24/7 internet access for research

### Laboratories:
- Computer labs with latest software and hardware
- Engineering labs for each department
- Research laboratories for advanced studies
- Simulation and modeling facilities

### Classrooms:
- Air-conditioned lecture halls
- Smart classrooms with multimedia facilities
- Seminar rooms for small group discussions
- Video conferencing facilities

## Residential Facilities

### Student Hostels:
- Separate hostels for male and female students
- Furnished rooms with basic amenities
- Common rooms and recreational facilities
- Mess and dining facilities

### Faculty Housing:
- On-campus quarters for faculty members
- Family accommodation available
- Guest house for visiting faculty and officials

## Other Facilities

### Medical Center:
- 24/7 medical services
- Qualified medical officers and staff
- Emergency medical care
- Regular health check-ups

### Sports and Recreation:
- Football ground and cricket field
- Basketball and volleyball courts
- Gymnasium and fitness center
- Indoor games facilities
- Swimming pool

### Transportation:
- Bus service for students and staff
- Parking facilities for private vehicles
- Bicycle stands throughout campus

### Dining:
- Central cafeteria with varied menu
- Department canteens
- Guest dining facilities
- Halal food options

### Banking and Communication:
- ATM facilities on campus
- Post office services
- High-speed internet throughout campus
- Wi-Fi hotspots in all academic areas

### Security:
- 24/7 security services
- CCTV surveillance
- ID card access system
- Emergency response protocols
            """
        },
        {
            "title": "MIST Student Life and Activities",
            "category": "general",
            "content": """
# Student Life at MIST

## Academic Life
- Rigorous academic curriculum
- Project-based learning approach
- Industry visits and internships
- Guest lectures by industry experts
- Research opportunities for undergraduate students

## Student Organizations

### Technical Clubs:
- MIST Computer Club (programming, software development)
- Robotics Club (robotics competitions, workshops)
- IEEE Student Branch (technical conferences, seminars)
- Engineering Society (inter-departmental activities)

### Cultural Organizations:
- Drama and Theatre Group
- Music and Arts Society
- Photography Club
- Literary Society
- Debate Club

### Sports Clubs:
- Cricket Club
- Football Club
- Basketball Club
- Table Tennis Club
- Chess Club

## Annual Events

### Technical Events:
- MIST Tech Fest (annual technical festival)
- Inter-departmental programming contests
- Engineering design competitions
- Research symposiums
- Industrial exhibitions

### Cultural Events:
- Annual cultural program
- Inter-university cultural competitions
- Art exhibitions
- Musical concerts
- Traditional day celebrations

### Sports Events:
- Annual sports week
- Inter-departmental tournaments
- Inter-university competitions
- Marathon and athletic meets

## Student Services

### Academic Support:
- Tutorial and mentoring programs
- Study groups and peer learning
- Academic counseling services
- Career guidance and placement support

### Welfare Services:
- Student counseling center
- Financial aid and scholarships
- Health and wellness programs
- Grievance redressal mechanism

### Career Development:
- Industry internship programs
- Job placement assistance
- Career counseling sessions
- Alumni networking opportunities
- Entrepreneurship development programs

## Code of Conduct
- Military discipline and values
- Academic integrity and honesty
- Respect for diversity and inclusion
- Environmental responsibility
- Community service and social responsibility
            """
        }
    ]
    
    for data in sample_data:
        uploader.upload_text_content(
            title=data["title"],
            content=data["content"],
            category=data["category"]
        )
        print()

if __name__ == "__main__":
    main()
