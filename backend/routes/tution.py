from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Tution, Users

tution_bp = Blueprint("tution", __name__)


@tution_bp.route("/tutions", methods=["POST"])
@jwt_required()
def create_tution():
    data = request.get_json() or {}
    post_id = (data.get("post_id") or "").strip()
    subject = (data.get("subject") or "").strip()
    class_level = (data.get("class") or "").strip()
    location = (data.get("location") or "").strip()
    remuneration = (data.get("renumeration") or "").strip()
    status = (data.get("status") or "open").strip()
    description = (data.get("description") or "").strip()
    req_type = (data.get("req_type") or "").strip()

    if not post_id or not subject:
        return jsonify({"msg": "post_id and subject are required"}), 400

    existing = Tution.query.filter(Tution.post_id == post_id).first()
    if existing:
        return jsonify({"msg": "post_id already exists"}), 409

    try:
        user_id = int(get_jwt_identity())
    except (TypeError, ValueError):
        return jsonify({"msg": "Invalid JWT identity"}), 400

    # confirm user exists (optional)
    user = Users.query.get(user_id)
    if not user:
        return jsonify({"msg": "User not found"}), 404

    t = Tution(
        user_id=user_id,
        post_id=post_id,
        subject=subject,
        class_level=class_level or None,
        location=location or None,
        remuneration=remuneration or None,
        status=status,
        description=description or None,
        req_type=req_type or None
    )
    print(t)
    db.session.add(t)
    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        return jsonify({"msg": "Failed to create tution post"}), 500

    return jsonify({
        "id": t.id,
        "user_id": t.user_id,
        "post_id": t.post_id,
        "subject": t.subject,
        "class": t.class_level,
        "location": t.location,
        "renumeration": t.remuneration,
        "created_at": t.created_at.isoformat(),
        "status": t.status,
        "description": t.description,
        "req_type": t.req_type
    }), 201


@tution_bp.route("/tutions", methods=["GET"])
def list_tutions():
    query = Tution.query.order_by(Tution.created_at.desc())
    tutions = query.all()
    return jsonify([
        {
            "id": t.id,
            "user_id": t.user_id,
            "post_id": t.post_id,
            "subject": t.subject,
            "class": t.class_level,
            "location": t.location,
            "renumeration": t.remuneration,
            "created_at": t.created_at.isoformat(),
            "status": t.status,
            "description": t.description,
            "req_type": t.req_type
        }
        for t in tutions
    ]), 200
