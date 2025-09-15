# models.py

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from pgvector.sqlalchemy import Vector

db = SQLAlchemy()

VALID_BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
VALID_REQUEST_STATUSES = ['pending', 'fulfilled', 'cancelled']

class Users(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), nullable=False, unique=True)
    phone = db.Column(db.String(50), nullable=True)
    designation = db.Column(db.String(100), nullable=True)
    password = db.Column(db.String(120), nullable=False)
    
    # New filter fields for messaging
    department = db.Column(db.String(100), nullable=True)
    level = db.Column(db.Integer, nullable=True)  # e.g., 1, 2, 3, 4 for year levels
    session = db.Column(db.String(50), nullable=True)  # e.g., "Spring 2023", "Fall 2022", etc.
    student_id = db.Column(db.String(50), nullable=True)
    avatar = db.Column(db.String(255), nullable=True)  # Avatar image path
    
    donors = db.relationship('Donor', backref='user')
    blood_requests = db.relationship('BloodRequest', backref='user')

class Donor(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    blood_group = db.Column(db.String(5), nullable=False)
    last_donation_date = db.Column(db.Date, nullable=True)
    address = db.Column(db.String(255), nullable=False)
    contact = db.Column(db.String(50), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    donation_histories = db.relationship('DonationHistory', backref='donor')

class BloodRequest(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    blood_group = db.Column(db.String(5), nullable=False)
    amount = db.Column(db.Integer, nullable=False)
    location = db.Column(db.String(255), nullable=False)
    contact = db.Column(db.String(100), nullable=False)
    note = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    needed_at = db.Column(db.DateTime, nullable=True)
    status = db.Column(db.String(50), default="pending")
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    donation_histories = db.relationship('DonationHistory', backref='request')

class DonationHistory(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    donor_id = db.Column(db.Integer, db.ForeignKey('donor.id'), nullable=False)
    donation_date = db.Column(db.Date, nullable=False)
    request_id = db.Column(db.Integer, db.ForeignKey('blood_request.id'), nullable=False)

class Department(db.Model):
    __tablename__ = "departments"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False, unique=True)
    icon = db.Column(db.String(50), nullable=True)
    courses = db.relationship("Course", backref="department", lazy=True)

class Course(db.Model):
    __tablename__ = "courses"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    department_id = db.Column(db.Integer, db.ForeignKey("departments.id"), nullable=False)
    notes = db.relationship("Note", backref="course", lazy=True)

class Note(db.Model):
    __tablename__ = "notes"
    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(255), nullable=False)
    file_url = db.Column(db.String(500), nullable=False)
    file_type = db.Column(db.String(10), nullable=False)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    uploaded_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey("courses.id"), nullable=False)


class Tution(db.Model):
    __tablename__ = "tutions"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    post_id = db.Column(db.String(120), nullable=False, unique=True)
    subject = db.Column(db.String(255), nullable=False)
    class_level = db.Column(db.String(100), nullable=True)
    location = db.Column(db.String(255), nullable=True)
    remuneration = db.Column(db.Integer, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(50), default="open")
    description = db.Column(db.Text, nullable=True)
    req_type = db.Column(db.String(100), nullable=True)


# Messaging Models
class Conversation(db.Model):
    __tablename__ = "conversations"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=True)  # Group name, null for individual chats
    type = db.Column(db.String(20), nullable=False, default="individual")  # individual or group
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    avatar = db.Column(db.String(10), nullable=True)  # Group avatar emoji
    course_folder = db.Column(db.String(500), nullable=True)  # For group course associations
    
    # Relationships
    creator = db.relationship("Users", backref="created_conversations")
    participants = db.relationship("ConversationParticipant", backref="conversation", cascade="all, delete-orphan")
    messages = db.relationship("Message", backref="conversation", cascade="all, delete-orphan", order_by="Message.sent_at")

class ConversationParticipant(db.Model):
    __tablename__ = "conversation_participants"
    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey("conversations.id"), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    role = db.Column(db.String(20), default="member")  # admin, moderator, member
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_seen = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    user = db.relationship("Users", backref="conversation_participations")
    
    # Unique constraint to prevent duplicate participations
    __table_args__ = (db.UniqueConstraint('conversation_id', 'user_id', name='unique_conversation_participant'),)

class Message(db.Model):
    __tablename__ = "messages"
    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey("conversations.id"), nullable=False)
    sender_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    content = db.Column(db.Text, nullable=False)
    message_type = db.Column(db.String(20), default="text")  # text, image, file, reference
    sent_at = db.Column(db.DateTime, default=datetime.utcnow)
    edited_at = db.Column(db.DateTime, nullable=True)
    deleted_at = db.Column(db.DateTime, nullable=True)
    
    # For file/image messages
    file_url = db.Column(db.String(500), nullable=True)
    file_name = db.Column(db.String(255), nullable=True)
    file_type = db.Column(db.String(50), nullable=True)
    
    # For reference messages (group resources)
    reference_data = db.Column(db.Text, nullable=True)  # JSON data for references
    
    # Relationships
    sender = db.relationship("Users", backref="sent_messages")
    reads = db.relationship("MessageRead", backref="message", cascade="all, delete-orphan")

class MessageRead(db.Model):
    __tablename__ = "message_reads"
    id = db.Column(db.Integer, primary_key=True)
    message_id = db.Column(db.Integer, db.ForeignKey("messages.id"), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    read_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    user = db.relationship("Users", backref="message_reads")
    
    # Unique constraint to prevent duplicate reads
    __table_args__ = (db.UniqueConstraint('message_id', 'user_id', name='unique_message_read'),)

# Group Resource Models
class GroupFolder(db.Model):
    __tablename__ = "group_folders"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey("conversations.id"), nullable=False)
    parent_folder_id = db.Column(db.Integer, db.ForeignKey("group_folders.id"), nullable=True)
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    conversation = db.relationship("Conversation", backref="folders")
    creator = db.relationship("Users", backref="created_folders")
    parent_folder = db.relationship("GroupFolder", remote_side=[id], backref="subfolders")
    files = db.relationship("GroupFile", backref="folder", cascade="all, delete-orphan")
    
    # Unique constraint: folder name must be unique within parent folder and conversation
    __table_args__ = (db.UniqueConstraint('name', 'conversation_id', 'parent_folder_id', name='unique_folder_name'),)

class GroupFile(db.Model):
    __tablename__ = "group_files"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)  # Display name
    original_filename = db.Column(db.String(255), nullable=False)  # Original uploaded filename
    file_path = db.Column(db.String(500), nullable=False)  # Server file path
    file_url = db.Column(db.String(500), nullable=False)  # URL to access file
    file_type = db.Column(db.String(50), nullable=False)  # Extension (pdf, jpg, etc.)
    file_size = db.Column(db.BigInteger, nullable=False)  # File size in bytes
    mime_type = db.Column(db.String(100), nullable=True)  # MIME type
    checksum = db.Column(db.String(128), nullable=True)  # SHA256 checksum for integrity
    
    conversation_id = db.Column(db.Integer, db.ForeignKey("conversations.id"), nullable=False)
    folder_id = db.Column(db.Integer, db.ForeignKey("group_folders.id"), nullable=False)
    uploaded_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    description = db.Column(db.Text, nullable=True)
    
    # Relationships
    conversation = db.relationship("Conversation", backref="files")
    uploader = db.relationship("Users", backref="uploaded_files")
    
    # Unique constraint: file name must be unique within folder
    __table_args__ = (db.UniqueConstraint('name', 'folder_id', name='unique_file_name'),)


# RAG Chatbot Models
class ChatSession(db.Model):
    __tablename__ = "chat_sessions"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    session_name = db.Column(db.String(255), default="New Chat")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    messages = db.relationship("ChatMessage", backref="session", lazy=True, cascade="all, delete-orphan")
    user = db.relationship("Users", backref="chat_sessions")


class ChatMessage(db.Model):
    __tablename__ = "chat_messages"
    id = db.Column(db.Integer, primary_key=True)
    session_id = db.Column(db.Integer, db.ForeignKey("chat_sessions.id"), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    
    # Message Content
    message_type = db.Column(db.String(20), nullable=False)  # 'text', 'image', 'audio', 'file'
    content = db.Column(db.Text, nullable=True)  # Text content or file description
    file_path = db.Column(db.String(500), nullable=True)  # Path to uploaded files
    file_name = db.Column(db.String(255), nullable=True)  # Original filename
    
    # AI Response
    ai_response = db.Column(db.Text, nullable=True)
    context_used = db.Column(db.Text, nullable=True)  # RAG context sources
    
    # Metadata
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    processing_time = db.Column(db.Float, nullable=True)  # Response time in seconds
    
    # User Relationship
    user = db.relationship("Users", backref="chat_messages")


class UserDocument(db.Model):
    """User-specific documents for personalized RAG"""
    __tablename__ = "user_documents"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    
    # Document Info
    filename = db.Column(db.String(255), nullable=False)
    file_path = db.Column(db.String(500), nullable=False)
    file_type = db.Column(db.String(50), nullable=False)  # 'pdf', 'image', 'text'
    file_size = db.Column(db.Integer, nullable=False)
    
    # Processing Status
    is_processed = db.Column(db.Boolean, default=False)
    processing_status = db.Column(db.String(50), default='pending')  # 'pending', 'processing', 'completed', 'failed'
    
    # Metadata
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    processed_at = db.Column(db.DateTime, nullable=True)
    
    # Content extracted from the document
    extracted_text = db.Column(db.Text, nullable=True)
    
    # Relationships
    user = db.relationship("Users", backref="documents")
    embeddings = db.relationship("DocumentEmbedding", backref="document", cascade="all, delete-orphan")


class DocumentEmbedding(db.Model):
    """Vector embeddings for user documents and institutional knowledge"""
    __tablename__ = "document_embeddings"
    id = db.Column(db.Integer, primary_key=True)
    
    # Source Information
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)  # NULL for institutional docs
    document_id = db.Column(db.Integer, db.ForeignKey("user_documents.id"), nullable=True)  # NULL for institutional docs
    institutional_knowledge_id = db.Column(db.Integer, db.ForeignKey("institutional_knowledge.id"), nullable=True)  # For institutional docs
    
    # Content
    content_chunk = db.Column(db.Text, nullable=False)
    chunk_index = db.Column(db.Integer, nullable=False)
    
    # Embedding Data (using pgvector)
    embedding_vector = db.Column(Vector(384))  # 384 dimensions for sentence-transformers all-MiniLM-L6-v2
    
    # Source Type
    source_type = db.Column(db.String(20), nullable=False)  # 'institutional', 'user_document'
    source_metadata = db.Column(db.Text, nullable=True)  # JSON metadata
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    user = db.relationship("Users", backref="embeddings")
    institutional_knowledge = db.relationship("InstitutionalKnowledge", backref="embeddings")


class InstitutionalKnowledge(db.Model):
    """MIST-specific institutional knowledge base"""
    __tablename__ = "institutional_knowledge"
    id = db.Column(db.Integer, primary_key=True)
    
    # Document Information
    title = db.Column(db.String(255), nullable=False)
    content_type = db.Column(db.String(50), nullable=False)  # 'website', 'pdf', 'manual'
    source_url = db.Column(db.String(500), nullable=True)
    file_path = db.Column(db.String(500), nullable=True)
    
    # Content
    content = db.Column(db.Text, nullable=False)
    summary = db.Column(db.Text, nullable=True)
    content_hash = db.Column(db.String(32), nullable=True)  # MD5 hash for duplicate detection
    
    # Categories for MIST
    category = db.Column(db.String(100), nullable=False)  # 'academic', 'admission', 'campus', 'research'
    subcategory = db.Column(db.String(100), nullable=True)
    
    # Processing
    is_processed = db.Column(db.Boolean, default=False)
    last_updated = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Version Control
    version = db.Column(db.String(50), default='1.0')


# Enhanced Profile System
class Profile(db.Model):
    """Enhanced user profile with comprehensive information"""
    __tablename__ = "profiles"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, unique=True)
    
    # Basic Information
    student_id = db.Column(db.String(20), nullable=True)
    batch = db.Column(db.String(10), nullable=True)
    department = db.Column(db.String(100), nullable=True)
    bio = db.Column(db.Text, nullable=True)
    date_of_birth = db.Column(db.Date, nullable=True)
    hometown = db.Column(db.String(100), nullable=True)
    
    # Profile Picture (stored as binary in database)
    profile_picture = db.Column(db.LargeBinary, nullable=True)
    profile_picture_mime_type = db.Column(db.String(50), nullable=True)
    
    # Social Links
    linkedin_url = db.Column(db.String(200), nullable=True)
    facebook_url = db.Column(db.String(200), nullable=True)
    github_url = db.Column(db.String(200), nullable=True)
    portfolio_url = db.Column(db.String(200), nullable=True)
    
    # Academic Info
    current_semester = db.Column(db.String(10), nullable=True)
    cgpa = db.Column(db.Float, nullable=True)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship("Users", backref=db.backref("profile", uselist=False))
    achievements = db.relationship("Achievement", backref="profile", lazy=True, cascade="all, delete-orphan")
    skills = db.relationship("Skill", backref="profile", lazy=True, cascade="all, delete-orphan")


class Achievement(db.Model):
    """User achievements with different categories"""
    __tablename__ = "achievements"
    id = db.Column(db.Integer, primary_key=True)
    profile_id = db.Column(db.Integer, db.ForeignKey("profiles.id"), nullable=False)
    
    # Achievement Details
    category = db.Column(db.String(50), nullable=False)  # 'education', 'work', 'project', 'award', 'certification'
    title = db.Column(db.String(255), nullable=False)
    organization = db.Column(db.String(255), nullable=True)
    description = db.Column(db.Text, nullable=True)
    
    # Timeline
    start_date = db.Column(db.Date, nullable=True)
    end_date = db.Column(db.Date, nullable=True)
    is_current = db.Column(db.Boolean, default=False)
    
    # Additional Info
    grade_or_result = db.Column(db.String(50), nullable=True)  # GPA, Grade, Result
    location = db.Column(db.String(100), nullable=True)
    skills_learned = db.Column(db.Text, nullable=True)  # JSON array of skills
    
    # Display Order
    display_order = db.Column(db.Integer, default=0)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Skill(db.Model):
    """User skills with proficiency levels"""
    __tablename__ = "skills"
    id = db.Column(db.Integer, primary_key=True)
    profile_id = db.Column(db.Integer, db.ForeignKey("profiles.id"), nullable=False)
    
    # Skill Details
    name = db.Column(db.String(100), nullable=False)
    category = db.Column(db.String(50), nullable=False)  # 'technical', 'language', 'soft_skill'
    proficiency_level = db.Column(db.Integer, nullable=False)  # 1-5 scale
    
    # Additional Info
    description = db.Column(db.Text, nullable=True)
    years_of_experience = db.Column(db.Integer, nullable=True)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class CVTemplate(db.Model):
    """CV Templates for different formats"""
    __tablename__ = "cv_templates"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    template_file = db.Column(db.String(255), nullable=False)  # HTML template file path
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
