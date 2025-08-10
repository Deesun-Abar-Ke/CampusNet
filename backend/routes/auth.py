# routes/auth.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from models import db, Users

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/signup", methods=["POST"])
def signup():
    data = request.get_json() or {}
    name = data.get("name", "").strip()
    email = data.get("email", "").strip().lower()
    phone = data.get("phone", "").strip()
    designation = data.get("designation", "").strip()
    password = data.get("password", "").strip()

    if not name or not email or not password:
        return jsonify({"msg": "name, email, and password are required"}), 400

    if Users.query.filter_by(email=email).first():
        return jsonify({"msg": "Email already in use"}), 409

    user = Users(
        name=name,
        email=email,
        phone=phone,
        designation=designation,
        password=password
    )
    db.session.add(user)
    db.session.commit()

    return jsonify({
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "designation": user.designation,
    }), 201

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

    access_token = create_access_token(identity=str(user.id))
    return jsonify({"msg": "Login successful", "access_token": access_token}), 200
