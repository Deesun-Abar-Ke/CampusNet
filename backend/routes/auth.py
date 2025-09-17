# routes/auth.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from models import db, Users, Profile

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/signup", methods=["POST"])
def signup():
    try:
        data = request.get_json() or {}
        name = data.get("name", "").strip()
        email = data.get("email", "").strip().lower()
        phone = data.get("phone", "").strip()
        designation = data.get("designation", "").strip()
        password = data.get("password", "").strip()

        if not name or not email or not password:
            return jsonify({"msg": "name, email, and password are required"}), 400

        # Check if user already exists
        if Users.query.filter_by(email=email).first():
            return jsonify({"msg": "Email already in use"}), 409

        # Create user (without profile for now)
        user = Users(
            name=name,
            email=email,
            phone=phone,
            designation=designation,
            password=password
        )
        
        db.session.add(user)
        db.session.commit()
        
        # Note: Profile will be created when user first visits profile page
        
        return jsonify({
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "designation": user.designation,
            "msg": "Account created successfully!"
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"Signup error: {e}")
        return jsonify({"msg": "Error creating account. Please try again."}), 500

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    email = data.get("email", "").strip().lower()
    password = data.get("password", "").strip()

    if not email or not password:
        return jsonify({"msg": "email and password are required"}), 400

    user = Users.query.filter_by(email=email).first()
    if not user or user.password != password:
        return jsonify({"msg": "Invalid credentials"}), 401

    # Create both access and refresh tokens
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))
    
    return jsonify({
        "msg": "Login successful", 
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": 86400,  # 24 hours in seconds
        "token_type": "Bearer"
    }), 200

@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    """
    Refresh endpoint to get a new access token using refresh token
    """
    try:
        current_user_id = get_jwt_identity()
        
        # Verify user still exists
        user = Users.query.get(int(current_user_id))
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        # Create new access token
        new_access_token = create_access_token(identity=str(user.id))
        
        return jsonify({
            "access_token": new_access_token,
            "expires_in": 86400,  # 24 hours in seconds
            "token_type": "Bearer"
        }), 200
        
    except Exception as e:
        print(f"Token refresh error: {e}")
        return jsonify({"error": "Failed to refresh token"}), 500

@auth_bp.route("/logout", methods=["POST"])
@jwt_required()
def logout():
    """
    Logout endpoint - mainly for client-side cleanup
    In a more advanced setup, you could implement token blacklisting here
    """
    return jsonify({"msg": "Successfully logged out"}), 200
