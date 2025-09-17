from extensions import db
from datetime import datetime
from sqlalchemy.orm import relationship

class Club(db.Model):
    __tablename__ = 'clubs'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    avatar_url = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    posts = relationship("Post", back_populates="club", cascade="all, delete-orphan")

class Tag(db.Model):
    __tablename__ = 'tags'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)
    color = db.Column(db.String(7), default='#007bff')  # Hex color
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    posts = relationship("Post", back_populates="tag")

class Post(db.Model):
    __tablename__ = 'posts'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200))
    content = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.Text)  # Changed from String(255) to Text for Base64 data URLs
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Foreign Keys
    club_id = db.Column(db.Integer, db.ForeignKey('clubs.id'), nullable=True)
    tag_id = db.Column(db.Integer, db.ForeignKey('tags.id'))
    author_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # Relationships
    club = relationship("Club", back_populates="posts")
    tag = relationship("Tag", back_populates="posts")
    author = relationship("Users", backref="posts")
    likes = relationship("PostLike", back_populates="post", cascade="all, delete-orphan")
    comments = relationship("PostComment", back_populates="post", cascade="all, delete-orphan")
    
    @property
    def like_count(self):
        return len(self.likes)
    
    @property
    def comment_count(self):
        return len(self.comments)
    
    @property
    def time_ago(self):
        now = datetime.utcnow()
        diff = now - self.created_at
        
        if diff.seconds < 60:
            return "Just now"
        elif diff.seconds < 3600:
            minutes = diff.seconds // 60
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        elif diff.seconds < 86400:
            hours = diff.seconds // 3600
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        else:
            days = diff.days
            return f"{days} day{'s' if days != 1 else ''} ago"

class PostLike(db.Model):
    __tablename__ = 'post_likes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    post_id = db.Column(db.Integer, db.ForeignKey('posts.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("Users", backref="likes")
    post = relationship("Post", back_populates="likes")
    
    # Unique constraint
    __table_args__ = (db.UniqueConstraint('user_id', 'post_id', name='unique_user_post_like'),)

class PostComment(db.Model):
    __tablename__ = 'post_comments'
    
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.Text, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    post_id = db.Column(db.Integer, db.ForeignKey('posts.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("Users", backref="comments")
    post = relationship("Post", back_populates="comments")
    
    @property
    def time_ago(self):
        now = datetime.utcnow()
        diff = now - self.created_at
        
        if diff.seconds < 60:
            return "Just now"
        elif diff.seconds < 3600:
            minutes = diff.seconds // 60
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        elif diff.seconds < 86400:
            hours = diff.seconds // 3600
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        else:
            days = diff.days
            return f"{days} day{'s' if days != 1 else ''} ago"

class Notification(db.Model):
    __tablename__ = 'notifications'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    type = db.Column(db.String(50), nullable=False)  # 'like', 'comment', 'post', 'mention'
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text, nullable=False)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Optional references
    post_id = db.Column(db.Integer, db.ForeignKey('posts.id'))
    from_user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    
    # Relationships
    user = relationship("Users", foreign_keys=[user_id], backref="notifications")
    from_user = relationship("Users", foreign_keys=[from_user_id])
    post = relationship("Post", backref="notifications")
    
    @property
    def time_ago(self):
        now = datetime.utcnow()
        diff = now - self.created_at
        
        if diff.seconds < 60:
            return "Just now"
        elif diff.seconds < 3600:
            minutes = diff.seconds // 60
            return f"{minutes}m ago"
        elif diff.seconds < 86400:
            hours = diff.seconds // 3600
            return f"{hours}h ago"
        else:
            days = diff.days
            if days == 1:
                return "Yesterday"
            elif days < 7:
                return f"{days}d ago"
            else:
                return f"{days // 7}w ago"
