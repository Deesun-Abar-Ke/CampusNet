import os
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
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
from config import Config

# Load env
load_dotenv()

#database config - Updated for new config system
try:
    # Try new config system first
    DATABASE_URL = os.getenv("DATABASE_URL")
    if DATABASE_URL:
        print(f"✅ Using DATABASE_URL from environment: {DATABASE_URL}")
    else:
        print("DATABASE_URL not found, trying individual variables...")
        # Fallback to old system
        USER = os.getenv("user") or os.getenv("POSTGRES_USER")
        PASSWORD = os.getenv("password") or os.getenv("POSTGRES_PASSWORD")
        HOST = os.getenv("host") or os.getenv("POSTGRES_HOST") or "localhost"
        PORT = os.getenv("port") or os.getenv("POSTGRES_PORT") or "5432"
        DBNAME = os.getenv("dbname") or os.getenv("POSTGRES_DB")
        
        if USER and PASSWORD and DBNAME:
            DATABASE_URL = f"postgresql+psycopg2://{USER}:{PASSWORD}@{HOST}:{PORT}/{DBNAME}?sslmode=require"
            print(f"✅ Built DATABASE_URL from components: postgresql+psycopg2://{USER}:***@{HOST}:{PORT}/{DBNAME}?sslmode=require")
        else:
            print(f"❌ Missing database credentials. USER={USER}, PASSWORD={'***' if PASSWORD else None}, DBNAME={DBNAME}")
            DATABASE_URL = None
except Exception as e:
    print(f"❌ Error loading database config: {e}")
    DATABASE_URL = None


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
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "your_secret_key_here")
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "your_secret_key_here")  # For JWT token_required

db.init_app(app)
jwt = JWTManager(app)

# Create tables (updated for newer Flask versions)
with app.app_context():
    db.create_all()

@app.route("/")
def home():
    return jsonify({"msg": "CampusNet API", "status": "up"}), 200

# Route to serve uploaded files (public access)
@app.route("/static/uploads/<path:filename>")
def uploaded_file(filename):
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)
    return jsonify({"msg": "CampusNet AI-Powered API", "status": "up", "features": ["Blood Bank", "Study Materials", "Tuition", "AI Chatbot"]}), 200

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

# Error handlers
@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
