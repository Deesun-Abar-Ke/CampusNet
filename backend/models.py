# models.py

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from pgvector.sqlalchemy import Vector

db = SQLAlchemy()

VALID_BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
VALID_REQUEST_STATUSES = ['pending', 'fulfilled', 'cancelled']

class Users(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), nullable=False, unique=True)
    phone = db.Column(db.String(50), nullable=True)
    designation = db.Column(db.String(100), nullable=True)
    password = db.Column(db.String(120), nullable=False)
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
