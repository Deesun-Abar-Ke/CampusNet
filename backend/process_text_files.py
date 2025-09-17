#!/usr/bin/env python3
"""
Text Files Processor for CampusNet Knowledge Base
Processes existing .txt files and adds them to institutional_knowledge table
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import logging
from datetime import datetime
from app import app, db
from models import InstitutionalKnowledge
from services.rag_service import get_rag_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TextFileProcessor:
    """Process existing text files into institutional_knowledge table"""
    
    def __init__(self):
        self.app = app
        self.db = db
        self.rag_service = get_rag_service()
        
    def process_text_files(self):
        """Process all .txt files in knowledge_base/institutional_data/"""
        print("📄 TEXT FILE PROCESSOR")
        print("=" * 50)
        
        data_dir = "knowledge_base/institutional_data"
        
        if not os.path.exists(data_dir):
            print(f"❌ Directory {data_dir} not found!")
            return False
        
        txt_files = [f for f in os.listdir(data_dir) if f.endswith('.txt')]
        
        if not txt_files:
            print(f"❌ No .txt files found in {data_dir}")
            return False
        
        print(f"📚 Found {len(txt_files)} text files to process:")
        for file in txt_files:
            print(f"   - {file}")
        
        processed_count = 0
        failed_count = 0
        
        with self.app.app_context():
            for filename in txt_files:
                filepath = os.path.join(data_dir, filename)
                
                try:
                    print(f"\n🔄 Processing: {filename}")
                    
                    # Read file content
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read().strip()
                    
                    if not content:
                        print(f"   ⚠️  File is empty, skipping")
                        continue
                    
                    # Determine category based on filename
                    category = self._determine_category(filename)
                    title = self._generate_title(filename)
                    
                    # Check if already exists
                    existing = InstitutionalKnowledge.query.filter_by(
                        title=title,
                        content_type='text'
                    ).first()
                    
                    if existing:
                        print(f"   🔄 Updating existing entry")
                        existing.content = content
                        existing.summary = content[:500] + "..." if len(content) > 500 else content
                        existing.last_updated = datetime.utcnow()
                        existing.is_processed = False  # Mark for reprocessing
                        entry = existing
                        action = "updated"
                    else:
                        print(f"   ➕ Creating new entry")
                        entry = InstitutionalKnowledge(
                            title=title,
                            content_type='text',
                            file_path=filepath,
                            content=content,
                            summary=content[:500] + "..." if len(content) > 500 else content,
                            category=category,
                            subcategory='text_file',
                            is_processed=False,
                            last_updated=datetime.utcnow(),
                            version='1.0'
                        )
                        self.db.session.add(entry)
                        action = "created"
                    
                    # Commit to database
                    self.db.session.commit()
                    
                    # Process with RAG
                    print(f"   🔍 Processing with RAG system...")
                    try:
                        success = self.rag_service.process_institutional_knowledge(
                            title=title,
                            content=content,
                            source_url=None,
                            category=category
                        )
                        
                        if success:
                            entry.is_processed = True
                            self.db.session.commit()
                            print(f"   ✅ {action.title()}: {title} ({len(content)} chars)")
                            processed_count += 1
                        else:
                            print(f"   ⚠️  RAG processing failed for {filename}")
                            processed_count += 1  # Still count as processed
                            
                    except Exception as e:
                        print(f"   ❌ RAG error: {e}")
                        processed_count += 1  # Still count as processed
                    
                except Exception as e:
                    print(f"   ❌ Error processing {filename}: {e}")
                    failed_count += 1
                    self.db.session.rollback()
        
        print(f"\n📊 PROCESSING SUMMARY:")
        print(f"   ✅ Processed: {processed_count}")
        print(f"   ❌ Failed: {failed_count}")
        print(f"   📈 Success Rate: {processed_count/(processed_count+failed_count)*100:.1f}%")
        
        return processed_count > 0
    
    def _determine_category(self, filename):
        """Determine category based on filename"""
        filename_lower = filename.lower()
        
        if 'academic' in filename_lower or 'department' in filename_lower:
            return 'academic'
        elif 'admission' in filename_lower:
            return 'admission'
        elif 'research' in filename_lower:
            return 'research'
        elif 'campus' in filename_lower:
            return 'campus'
        elif 'general' in filename_lower or 'info' in filename_lower:
            return 'institutional'
        else:
            return 'general'
    
    def _generate_title(self, filename):
        """Generate a readable title from filename"""
        # Remove extension and replace underscores/hyphens with spaces
        title = os.path.splitext(filename)[0]
        title = title.replace('_', ' ').replace('-', ' ')
        
        # Capitalize each word
        title = ' '.join(word.capitalize() for word in title.split())
        
        return title

def main():
    """Main function"""
    processor = TextFileProcessor()
    
    print("🎯 This script will process .txt files in knowledge_base/institutional_data/")
    print("   and add them to the institutional_knowledge database table.")
    
    response = input("\n❓ Continue? (y/n): ").strip().lower()
    
    if response in ['y', 'yes']:
        success = processor.process_text_files()
        if success:
            print("\n🎉 Text file processing completed!")
        else:
            print("\n❌ Text file processing failed!")
    else:
        print("\n👋 Processing cancelled")

if __name__ == "__main__":
    main()
