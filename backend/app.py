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
    print(f"✅ Using DATABASE_URL from environment: {DATABASE_URL}")
except:
    # Fallback to old system
    USER = os.getenv("user")
    PASSWORD = os.getenv("password")
    HOST = os.getenv("host")
    PORT = os.getenv("port")
    DBNAME = os.getenv("dbname")
    DATABASE_URL = f"postgresql+psycopg2://{USER}:{PASSWORD}@{HOST}:{PORT}/{DBNAME}?sslmode=require"


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

db.init_app(app)
jwt = JWTManager(app)

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

# Error handlers
@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
