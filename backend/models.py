# models.py

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

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
    
    # Additional name fields
    first_name = db.Column(db.String(50), nullable=True)
    last_name = db.Column(db.String(50), nullable=True)
    
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




