import os
os.add_dll_directory(r"D:\GTK3-Runtime Win64\bin")

from weasyprint import HTML, CSS  # import AFTER add_dll_directory

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from datetime import timedelta
from dotenv import load_dotenv
from models import db
from routes.auth import auth_bp
from routes.blood import blood_bp
from routes.study_materials import study_bp
from routes.tution import tution_bp
from routes.ai import ai_bp
from routes.knowledge_base import kb_bp
from routes.chat_routes import chat_bp
from routes.profile import profile_bp
# from routes.feed import feed_bp  # Removed - functionality moved to social_routes
from routes.social_routes import social_bp
from utils.db_utils import cleanup_db_session, get_db_connection_info, force_close_connections

# Load env
load_dotenv()

#database config - Supabase PostgreSQL only
DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL and "postgresql" in DATABASE_URL:
    print(f"✅ Using DATABASE_URL from environment: {DATABASE_URL}")
else:
    print("❌ DATABASE_URL environment variable not found or invalid!")
    print("   Please set DATABASE_URL to your Supabase PostgreSQL connection string.")
    exit(1)


app = Flask(__name__)
CORS(app)

# Upload folder for study materials
UPLOAD_FOLDER = os.path.join(os.getcwd(), "static", "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# DB + JWT setup
app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "your_secret_key_here")
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "your_secret_key_here")  # For JWT token_required

# JWT Token Expiration Settings
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=24)  # 24 hours instead of default 15 minutes
app.config["JWT_REFRESH_TOKEN_EXPIRES"] = timedelta(days=30)  # 30 days for refresh token

db.init_app(app)
jwt = JWTManager(app)

# JWT Error handlers
@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return jsonify({'error': 'Token has expired'}), 401

@jwt.invalid_token_loader
def invalid_token_callback(error_message):
    return jsonify({'error': f'Invalid token: {error_message}'}), 401

@jwt.unauthorized_loader
def missing_token_callback(error_message):
    return jsonify({'error': 'Authorization token is required'}), 401

# Database connection management
@app.teardown_appcontext
def close_db_connection(error):
    """Ensure database connections are properly closed after each request"""
    cleanup_db_session()

@app.before_request
def check_db_connections():
    """Monitor database connections before each request"""
    conn_info = get_db_connection_info()
    if conn_info:
        checked_out = conn_info.get('checked_out', 0)
        if checked_out > 3:  # More than 3 connections in use
            app.logger.warning(f"High DB connection usage: {conn_info}")

# Emergency endpoint to reset connections (dev only)
@app.route("/dev/reset-db-connections", methods=['POST'])
def reset_db_connections():
    """Emergency endpoint to reset database connections"""
    if app.debug:  # Only in debug mode
        success = force_close_connections()
        return jsonify({
            'success': success,
            'message': 'Database connections reset' if success else 'Failed to reset connections'
        })
    return jsonify({'error': 'Not available in production'}), 403

# Create tables (updated for newer Flask versions)
with app.app_context():
    db.create_all()

@app.route("/")
def home():
    return jsonify({"msg": "CampusNet API", "status": "up"}), 200

# Route to serve uploaded files
@app.route("/static/uploads/<path:filename>")
def uploaded_file(filename):
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)
    return jsonify({"msg": "CampusNet AI-Powered API", "status": "up", "features": ["Blood Bank", "Study Materials", "Tuition", "AI Chatbot"]}), 200

# Disable strict slashes to avoid 308 redirects
app.url_map.strict_slashes = False

# Register blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(blood_bp)
app.register_blueprint(study_bp)
app.register_blueprint(tution_bp)
app.register_blueprint(ai_bp)
app.register_blueprint(kb_bp)  # Knowledge Base Management
app.register_blueprint(chat_bp)  # AI Chat routes
app.register_blueprint(profile_bp, url_prefix='/api/profile')  # Profile Management
# app.register_blueprint(feed_bp, url_prefix='/api')  # Social Feed routes - Removed, functionality moved to social_routes
app.register_blueprint(social_bp, url_prefix='/api/social')  # Social/Posts routes

# Error handlers
@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
