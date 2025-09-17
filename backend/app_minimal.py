"""
Minimal Flask App with Single Database Connection
Use this if regular app.py fails due to connection pool issues
"""
import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv

# Load env
load_dotenv()

# Simple Flask app
app = Flask(__name__)
CORS(app)

# Minimal config
app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY", "your_secret_key_here")
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "your_secret_key_here")

# No database connection for testing
jwt = JWTManager(app)

@app.route("/")
def home():
    return jsonify({
        "msg": "CampusNet API - Minimal Mode", 
        "status": "up",
        "note": "Database temporarily disabled due to connection limits"
    }), 200

@app.route("/test")
def test():
    return jsonify({
        "message": "Server is running without database",
        "suggestion": "Switch to Transaction Mode (port 6543) in DATABASE_URL"
    }), 200

if __name__ == "__main__":
    print("🚀 Starting CampusNet API in minimal mode...")
    print("⚠️  Database features disabled due to connection pool limits")
    print("💡 Solution: Switch DATABASE_URL to port 6543 (Transaction Mode)")
    app.run(host="0.0.0.0", port=5000, debug=True)
