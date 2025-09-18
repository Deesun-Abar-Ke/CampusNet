import os
os.add_dll_directory(r"D:\GTK3-Runtime Win64\bin")

from weasyprint import HTML, CSS  # import AFTER add_dll_directory

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from datetime import timedelta
from dotenv import load_dotenv

# Load env
load_dotenv()

# Import models and routes
from models import db
from routes.auth import auth_bp
from routes.blood import blood_bp
from routes.study_materials import study_bp
from routes.tution import tution_bp
from routes.ai import ai_bp
from routes.messages import messages_bp
from routes.group_resource import group_resource_bp
from routes.knowledge_base import kb_bp
from routes.chat_routes import chat_bp
from routes.profile import profile_bp
# from routes.feed import feed_bp  # Removed - functionality moved to social_routes
from routes.social_routes import social_bp
from utils.db_utils import cleanup_db_session, get_db_connection_info, force_close_connections

#database config - Supabase PostgreSQL only
DATABASE_URL = os.getenv("DATABASE_URL")
if DATABASE_URL and "postgresql" in DATABASE_URL:
    print(f"✅ Using DATABASE_URL from environment: {DATABASE_URL}")
else:
    print("❌ DATABASE_URL environment variable not found or invalid!")
    print("   Please set DATABASE_URL to your Supabase PostgreSQL connection string.")
    exit(1)


app = Flask(__name__)
CORS(app, 
     origins=["*"], 
     supports_credentials=True,
     allow_headers=["Content-Type", "Authorization"],
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])

# Upload folder for study materials
UPLOAD_FOLDER = os.path.join(os.getcwd(), "static", "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# DB + JWT setup
if not DATABASE_URL:
    print("❌ ERROR: No database configuration found!")
    print("Please set up your database configuration in one of the following ways:")
    print("1. Set DATABASE_URL environment variable")
    print("2. Set individual variables: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, etc.")
    print("3. Create a .env file based on .env.example")
    exit(1)

app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
# Optimize database connection pool for Supabase (very conservative for free tier)
app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
    "pool_size": 5,          # Small pool size for Supabase free tier
    "max_overflow": 0,       # No overflow connections
    "pool_recycle": 60,      # Recycle connections every 1 minute to free them up quickly
    "pool_pre_ping": True,   # Verify connections before use
    "pool_timeout": 10,      # Timeout after 10 seconds if no connection available
}
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "your_secret_key_here")
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "your_secret_key_here")  # For JWT token_required
app.config["SERVER_BASE_URL"] = os.environ.get("SERVER_BASE_URL", "http://192.168.0.101:5000")  # Updated to match frontend

# JWT Token Expiration Settings
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=24)  # 24 hours instead of default 15 minutes
app.config["JWT_REFRESH_TOKEN_EXPIRES"] = timedelta(days=30)  # 30 days for refresh token

# Initialize database and JWT
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

print(f"🔧 SERVER_BASE_URL is set to: {app.config['SERVER_BASE_URL']}")
print(f"🔧 Database pool configured: pool_size=5, max_overflow=0, pool_recycle=60s")

# Create/update database tables (important for new fields like deleted_by)
try:
    with app.app_context():
        print("🔄 Creating/updating database tables...")
        db.create_all()
        print("✅ Database tables created/updated successfully")
        print("📝 This includes the new deleted_by field for message deletion feature")
except Exception as e:
    print(f"⚠️ Database table creation failed: {e}")
    if "MaxClientsInSessionMode" in str(e) or "max clients reached" in str(e):
        print("💡 Connection pool issue - tables may already exist")
        print("🔄 Server will continue, but new features may not work properly")
    else:
        print("❌ Unexpected database error - please check your connection")
        print("💡 This may affect functionality, especially new features")

@app.route("/")
def home():
    return jsonify({"msg": "CampusNet API", "status": "up"}), 200

# Route to serve uploaded files (public access)
@app.route("/static/uploads/<path:filename>")
def uploaded_file(filename):
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)

# Disable strict slashes to avoid 308 redirects
app.url_map.strict_slashes = False

# Route to serve group resource files (public access for viewing)
@app.route("/files/<path:filename>")
def serve_group_file(filename):
    # First try group resources directory
    group_resources_folder = os.path.join(app.root_path, "uploads", "group_resources")
    group_resources_path = os.path.join(group_resources_folder, filename)
    
    if os.path.isfile(group_resources_path):
        return send_from_directory(group_resources_folder, filename)
    
    # Fallback to static uploads folder
    upload_folder = app.config.get("UPLOAD_FOLDER", os.path.join(os.getcwd(), "static", "uploads"))
    static_path = os.path.join(upload_folder, filename)
    
    if os.path.isfile(static_path):
        return send_from_directory(upload_folder, filename)
    
    return jsonify({"error": "File not found"}), 404

# Register blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(blood_bp)
app.register_blueprint(study_bp)
app.register_blueprint(tution_bp)
app.register_blueprint(ai_bp)
app.register_blueprint(messages_bp)
app.register_blueprint(group_resource_bp, url_prefix='/api')
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
