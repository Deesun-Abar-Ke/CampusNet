import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
from models import db
from routes.auth import auth_bp
from routes.social_routes import social_bp
from routes.profile import profile_bp
from utils.db_utils import cleanup_db_session

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

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'jwt-secret-change-in-production')
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'pool_pre_ping': True,
    'pool_recycle': 300,
    'connect_args': {
        'connect_timeout': 60,
        'sslmode': 'require'
    }
}

# Initialize extensions
CORS(app, origins=['*'])
jwt = JWTManager(app)
db.init_app(app)

# Register blueprints - only essential ones for now
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(social_bp, url_prefix='/api/social')  
app.register_blueprint(profile_bp, url_prefix='/api/profile')

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)  
def internal_server_error(error):
    return jsonify({'error': 'Internal server error'}), 500

# Health check endpoint
@app.route('/health')
def health_check():
    return jsonify({
        'status': 'healthy',
        'message': 'CampusNet Backend is running!',
        'version': '1.0.0'
    })

# Cleanup on shutdown
@app.teardown_appcontext
def cleanup(error):
    cleanup_db_session()

if __name__ == '__main__':
    with app.app_context():
        try:
            print("Creating database tables...")
            db.create_all()
            print("✅ Database tables created successfully")
        except Exception as e:
            print(f"⚠️  Database table creation warning: {e}")
    
    print("🚀 Starting CampusNet Backend Server...")
    print(f"🌐 Server will be accessible at:")
    print(f"   - Local: http://127.0.0.1:5000")
    print(f"   - Network: http://10.103.133.97:5000")
    print(f"📱 Configure your Android app to use: http://10.103.133.97:5000")
    
    app.run(host='0.0.0.0', port=5000, debug=True)