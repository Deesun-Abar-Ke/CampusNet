import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
from models import db
from routes.auth import auth_bp
from routes.blood import blood_bp
from routes.study_materials import study_bp
from routes.tution import tution_bp
from routes.knowledge_base import kb_bp
from routes.chat_routes import chat_bp
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

# Apply configuration
try:
    Config.init_app(app)
    print("✅ Using new configuration system")
except Exception as e:
    print(f"⚠️ Fallback to old configuration: {e}")
    app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "your_secret_key_here")

# Init
db.init_app(app)
jwt = JWTManager(app)

# Create tables (updated for newer Flask versions)
with app.app_context():
    db.create_all()

@app.route("/")
def home():
    return jsonify({"msg": "CampusNet AI-Powered API", "status": "up", "features": ["Blood Bank", "Study Materials", "Tuition", "AI Chatbot"]}), 200

# Register blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(blood_bp)
app.register_blueprint(study_bp)
app.register_blueprint(tution_bp)
app.register_blueprint(kb_bp)  # Knowledge Base Management
app.register_blueprint(chat_bp)  # AI Chat routes

# Error handlers
@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
