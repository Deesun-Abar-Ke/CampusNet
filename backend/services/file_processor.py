import os
import mimetypes
import tempfile
from typing import Optional, Tuple, Dict
import logging
from datetime import datetime
from werkzeug.utils import secure_filename
import uuid

# Import libraries for different file types
try:
    import PyPDF2
    import fitz  # PyMuPDF
    PDF_AVAILABLE = True
except ImportError:
    PDF_AVAILABLE = False

try:
    from PIL import Image
    import pytesseract
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

try:
    import speech_recognition as sr
    SPEECH_AVAILABLE = True
except ImportError:
    SPEECH_AVAILABLE = False

from config import Config

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FileProcessor:
    """
    Service for processing various file types and extracting text content
    Supports: PDF, images (OCR), audio (speech-to-text), and text files
    """
    
    def __init__(self):
        """Initialize file processor with supported formats"""
        self.upload_folder = Config.UPLOAD_FOLDER
        self.max_file_size = Config.MAX_CONTENT_LENGTH
        
        # Supported file types
        self.supported_text_formats = {'.txt', '.md', '.csv'}
        self.supported_image_formats = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff'}
        self.supported_audio_formats = {'.wav', '.mp3', '.ogg', '.flac', '.m4a'}
        self.supported_pdf_formats = {'.pdf'}
        
        # Check available libraries
        self.pdf_available = PDF_AVAILABLE
        self.ocr_available = OCR_AVAILABLE
        self.speech_available = SPEECH_AVAILABLE
        
        if not self.pdf_available:
            logger.warning("PDF processing libraries not available. Install PyPDF2 and PyMuPDF for PDF support.")
        if not self.ocr_available:
            logger.warning("OCR libraries not available. Install Pillow and pytesseract for image text extraction.")
        if not self.speech_available:
            logger.warning("Speech recognition not available. Install SpeechRecognition for audio processing.")
        
        logger.info("File processor initialized")
    
    def get_user_upload_path(self, user_id: int, file_type: str = 'documents') -> str:
        """
        Generate secure user-specific upload path
        
        Args:
            user_id: User ID
            file_type: Type of file (documents, images, audio)
            
        Returns:
            Path to user's upload directory
        """
        user_path = os.path.join(self.upload_folder, f"user_{user_id}", file_type)
        os.makedirs(user_path, exist_ok=True)
        return user_path
    
    def validate_file(self, filename: str, file_size: int) -> Tuple[bool, str, str]:
        """
        Validate uploaded file
        
        Args:
            filename: Original filename
            file_size: File size in bytes
            
        Returns:
            Tuple of (is_valid, error_message, file_type)
        """
        if not filename:
            return False, "No filename provided", ""
        
        if file_size > self.max_file_size:
            return False, f"File size ({file_size} bytes) exceeds maximum allowed size ({self.max_file_size} bytes)", ""
        
        # Get file extension
        _, ext = os.path.splitext(filename.lower())
        
        # Determine file type
        if ext in self.supported_text_formats:
            file_type = "text"
        elif ext in self.supported_image_formats:
            file_type = "image"
        elif ext in self.supported_audio_formats:
            file_type = "audio"
        elif ext in self.supported_pdf_formats:
            file_type = "pdf"
        else:
            return False, f"Unsupported file format: {ext}", ""
        
        return True, "", file_type
    
    def save_uploaded_file(self, file, user_id: int, original_filename: str) -> Tuple[bool, str, str]:
        """
        Save uploaded file to user's directory
        
        Args:
            file: Uploaded file object
            user_id: User ID
            original_filename: Original filename
            
        Returns:
            Tuple of (success, file_path, error_message)
        """
        try:
            # Validate file
            file.seek(0, 2)  # Seek to end
            file_size = file.tell()
            file.seek(0)  # Reset to beginning
            
            is_valid, error_msg, file_type = self.validate_file(original_filename, file_size)
            if not is_valid:
                return False, "", error_msg
            
            # Generate secure filename
            filename = secure_filename(original_filename)
            unique_filename = f"{uuid.uuid4().hex}_{filename}"
            
            # Get upload path
            upload_path = self.get_user_upload_path(user_id, file_type)
            file_path = os.path.join(upload_path, unique_filename)
            
            # Save file
            file.save(file_path)
            
            logger.info(f"Saved file for user {user_id}: {unique_filename}")
            return True, file_path, ""
            
        except Exception as e:
            logger.error(f"Error saving file: {e}")
            return False, "", str(e)
    
    def extract_text_from_file(self, file_path: str, file_type: str) -> Tuple[bool, str, str]:
        """
        Extract text content from various file types
        
        Args:
            file_path: Path to the file
            file_type: Type of file (text, pdf, image, audio)
            
        Returns:
            Tuple of (success, extracted_text, error_message)
        """
        try:
            if file_type == "text":
                return self._extract_from_text(file_path)
            elif file_type == "pdf":
                return self._extract_from_pdf(file_path)
            elif file_type == "image":
                return self._extract_from_image(file_path)
            elif file_type == "audio":
                return self._extract_from_audio(file_path)
            else:
                return False, "", f"Unsupported file type: {file_type}"
                
        except Exception as e:
            logger.error(f"Error extracting text from {file_path}: {e}")
            return False, "", str(e)
    
    def _extract_from_text(self, file_path: str) -> Tuple[bool, str, str]:
        """Extract text from text files"""
        try:
            encodings = ['utf-8', 'utf-16', 'latin-1', 'cp1252']
            
            for encoding in encodings:
                try:
                    with open(file_path, 'r', encoding=encoding) as f:
                        content = f.read()
                    return True, content, ""
                except UnicodeDecodeError:
                    continue
            
            return False, "", "Could not decode text file with any supported encoding"
            
        except Exception as e:
            return False, "", str(e)
    
    def _extract_from_pdf(self, file_path: str) -> Tuple[bool, str, str]:
        """Extract text from PDF files"""
        if not self.pdf_available:
            return False, "", "PDF processing libraries not available"
        
        try:
            # Try PyMuPDF first (better text extraction)
            try:
                doc = fitz.open(file_path)
                text_content = ""
                
                for page_num in range(len(doc)):
                    page = doc[page_num]
                    text_content += page.get_text()
                    text_content += "\n\n"
                
                doc.close()
                
                if text_content.strip():
                    return True, text_content, ""
                    
            except Exception as e:
                logger.warning(f"PyMuPDF extraction failed: {e}. Trying PyPDF2...")
            
            # Fallback to PyPDF2
            try:
                with open(file_path, 'rb') as file:
                    pdf_reader = PyPDF2.PdfReader(file)
                    text_content = ""
                    
                    for page_num in range(len(pdf_reader.pages)):
                        page = pdf_reader.pages[page_num]
                        text_content += page.extract_text()
                        text_content += "\n\n"
                
                if text_content.strip():
                    return True, text_content, ""
                else:
                    return False, "", "No text could be extracted from PDF"
                    
            except Exception as e:
                return False, "", f"PDF text extraction failed: {str(e)}"
                
        except Exception as e:
            return False, "", str(e)
    
    def _extract_from_image(self, file_path: str) -> Tuple[bool, str, str]:
        """Extract text from images using OCR"""
        if not self.ocr_available:
            return False, "", "OCR libraries not available. Install Pillow and pytesseract."
        
        try:
            # Open and process image
            image = Image.open(file_path)
            
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Extract text using Tesseract
            extracted_text = pytesseract.image_to_string(image)
            
            if extracted_text.strip():
                return True, extracted_text, ""
            else:
                return False, "", "No text found in image"
                
        except Exception as e:
            return False, "", f"OCR extraction failed: {str(e)}"
    
    def _extract_from_audio(self, file_path: str) -> Tuple[bool, str, str]:
        """Extract text from audio files using speech recognition"""
        if not self.speech_available:
            return False, "", "Speech recognition library not available. Install SpeechRecognition."
        
        try:
            recognizer = sr.Recognizer()
            
            # Convert audio file to WAV if necessary
            audio_file = file_path
            
            # Load audio file
            with sr.AudioFile(audio_file) as source:
                audio_data = recognizer.record(source)
            
            # Recognize speech
            try:
                # Try Google Speech Recognition (free)
                text = recognizer.recognize_google(audio_data)
                return True, text, ""
                
            except sr.UnknownValueError:
                return False, "", "Could not understand audio"
            except sr.RequestError as e:
                return False, "", f"Speech recognition service error: {str(e)}"
                
        except Exception as e:
            return False, "", f"Audio processing failed: {str(e)}"
    
    def get_file_info(self, file_path: str) -> Dict:
        """
        Get information about a file
        
        Args:
            file_path: Path to the file
            
        Returns:
            Dictionary with file information
        """
        try:
            if not os.path.exists(file_path):
                return {}
            
            stat = os.stat(file_path)
            mime_type, _ = mimetypes.guess_type(file_path)
            
            return {
                'filename': os.path.basename(file_path),
                'size': stat.st_size,
                'mime_type': mime_type,
                'created': datetime.fromtimestamp(stat.st_ctime),
                'modified': datetime.fromtimestamp(stat.st_mtime),
                'extension': os.path.splitext(file_path)[1].lower()
            }
            
        except Exception as e:
            logger.error(f"Error getting file info: {e}")
            return {}
    
    def cleanup_temp_files(self, max_age_hours: int = 24):
        """
        Clean up temporary files older than specified hours
        
        Args:
            max_age_hours: Maximum age in hours before cleanup
        """
        try:
            current_time = datetime.now()
            
            for root, dirs, files in os.walk(self.upload_folder):
                for file in files:
                    file_path = os.path.join(root, file)
                    
                    try:
                        file_stat = os.stat(file_path)
                        file_age = current_time - datetime.fromtimestamp(file_stat.st_mtime)
                        
                        if file_age.total_seconds() > (max_age_hours * 3600):
                            os.remove(file_path)
                            logger.info(f"Cleaned up old file: {file_path}")
                            
                    except Exception as e:
                        logger.warning(f"Error cleaning up file {file_path}: {e}")
                        
        except Exception as e:
            logger.error(f"Error during cleanup: {e}")
