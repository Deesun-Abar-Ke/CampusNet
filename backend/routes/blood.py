# routes/blood.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from models import db, Donor, BloodRequest, DonationHistory, VALID_BLOOD_GROUPS, VALID_REQUEST_STATUSES

blood_bp = Blueprint("blood", __name__)

@blood_bp.route("/donors", methods=["POST"])
@jwt_required()
def register_donor():
    data = request.get_json() or {}
    name = data.get("name", "").strip()
    blood_group = data.get("blood_group", "").upper()
    last_donation_date = data.get("last_donation_date", "").strip()
    address = data.get("address", "").strip()
    contact = data.get("contact", "").strip()

    if not name or not blood_group or not address or not contact:
        return jsonify({"msg": "name, blood_group, address, contact are required"}), 400

    if blood_group not in VALID_BLOOD_GROUPS:
        return jsonify({"msg": "invalid blood_group"}), 400

    last_donation = None
    if last_donation_date:
        try:
            last_donation = datetime.strptime(last_donation_date, "%Y-%m-%d")
        except ValueError:
            return jsonify({"msg": "last_donation_date must be YYYY-MM-DD"}), 400

    try:
        user_id = int(get_jwt_identity())
    except (TypeError, ValueError):
        return jsonify({"msg": "Invalid JWT identity"}), 400

    donor = Donor(
        name=name,
        blood_group=blood_group,
        last_donation_date=last_donation,
        address=address,
        contact=contact,
        user_id=user_id
    )
    db.session.add(donor)
    db.session.commit()

    return jsonify({
        "id": donor.id,
        "name": donor.name,
        "blood_group": donor.blood_group,
        "last_donation_date": donor.last_donation_date.isoformat() if donor.last_donation_date else None,
        "address": donor.address,
        "contact": donor.contact,
        "user_id": donor.user_id
    }), 201

@blood_bp.route("/donors", methods=["GET"])
@jwt_required()
def list_donors():
    blood_group = request.args.get("blood_group")
    location = request.args.get("location")
    query = Donor.query
    if blood_group:
        query = query.filter(Donor.blood_group == blood_group.upper())
    if location:
        query = query.filter(Donor.address.ilike(f"%{location}%"))
    donors = query.order_by(Donor.created_at.desc()).all()
    result = []
    for d in donors:
        result.append({
            "id": d.id,
            "name": d.name,
            "blood_group": d.blood_group,
            "last_donation_date": d.last_donation_date.isoformat() if d.last_donation_date else None,
            "address": d.address,
            "contact": d.contact,
        })
    return jsonify(result), 200

@blood_bp.route("/blood_requests", methods=["POST"])
@jwt_required()
def create_blood_request():
    data = request.get_json() or {}
    blood_group = data.get("blood_group", "").strip().upper()
    amount = data.get("amount")
    location = data.get("location", "").strip()
    contact = data.get("contact", "").strip()
    note = data.get("note", "").strip() if data.get("note") else None
    needed_at_raw = data.get("needed_at", "").strip() if data.get("needed_at") else ""
    status = data.get("status", "pending").strip().lower()

    if not blood_group or amount is None or not location or not contact:
        return jsonify({"msg": "blood_group, amount, location, and contact are required"}), 400

    if blood_group not in VALID_BLOOD_GROUPS:
        return jsonify({"msg": "invalid blood_group"}), 400

    try:
        amount = int(amount)
        if amount <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        return jsonify({"msg": "amount must be a positive integer"}), 400

    if status not in VALID_REQUEST_STATUSES:
        return jsonify({"msg": "invalid status"}), 400

    needed_at = None
    if needed_at_raw:
        try:
            needed_at = datetime.strptime(needed_at_raw, "%Y-%m-%dT%H:%M:%S")
        except ValueError:
            return jsonify({"msg": "needed_at must be ISO format YYYY-MM-DDTHH:MM:SS"}), 400

    try:
        user_id = int(get_jwt_identity())
    except (TypeError, ValueError):
        return jsonify({"msg": "Invalid JWT identity"}), 400

    br = BloodRequest(
        blood_group=blood_group,
        amount=amount,
        location=location,
        contact=contact,
        note=note,
        needed_at=needed_at,
        status=status,
        user_id=user_id
    )
    db.session.add(br)
    db.session.commit()

    return jsonify({
        "id": br.id,
        "blood_group": br.blood_group,
        "amount": br.amount,
        "location": br.location,
        "contact": br.contact,
        "note": br.note,
        "created_at": br.created_at.isoformat(),
        "needed_at": br.needed_at.isoformat() if br.needed_at else None,
        "status": br.status,
        "user_id": br.user_id
    }), 201

@blood_bp.route("/blood_requests", methods=["GET"])
@jwt_required()
def list_blood_requests():
    blood_group = request.args.get("blood_group")
    status = request.args.get("status")
    location = request.args.get("location")
    user_id_filter = request.args.get("user_id")
    query = BloodRequest.query

    if blood_group:
        query = query.filter(BloodRequest.blood_group == blood_group.upper())
    if status:
        query = query.filter(BloodRequest.status == status.lower())
    if location:
        query = query.filter(BloodRequest.location.ilike(f"%{location}%"))
    if user_id_filter:
        try:
            uid = int(user_id_filter)
            query = query.filter(BloodRequest.user_id == uid)
        except ValueError:
            return jsonify({"msg": "user_id must be integer"}), 400

    requests_list = query.order_by(BloodRequest.created_at.desc()).all()
    result = []
    for br in requests_list:
        result.append({
            "id": br.id,
            "blood_group": br.blood_group,
            "amount": br.amount,
            "location": br.location,
            "contact": br.contact,
            "note": br.note,
            "created_at": br.created_at.isoformat(),
            "needed_at": br.needed_at.isoformat() if br.needed_at else None,
            "status": br.status,
            "user_id": br.user_id
        })
    return jsonify(result), 200

@blood_bp.route("/blood_requests/<int:request_id>", methods=["GET"])
@jwt_required()
def get_blood_request(request_id):
    br = BloodRequest.query.get_or_404(request_id)
    return jsonify({
        "id": br.id,
        "blood_group": br.blood_group,
        "amount": br.amount,
        "location": br.location,
        "contact": br.contact,
        "note": br.note,
        "created_at": br.created_at.isoformat(),
        "needed_at": br.needed_at.isoformat() if br.needed_at else None,
        "status": br.status,
        "user_id": br.user_id
    }), 200

@blood_bp.route("/blood_requests/<int:request_id>/status", methods=["PATCH"])
@jwt_required()
def update_blood_request_status(request_id):
    br = BloodRequest.query.get_or_404(request_id)
    data = request.get_json() or {}
    new_status = data.get("status", "").strip().lower()
    if new_status not in VALID_REQUEST_STATUSES:
        return jsonify({"msg": "invalid status"}), 400
    br.status = new_status
    db.session.commit()
    return jsonify({"id": br.id, "status": br.status}), 200

@blood_bp.route("/donation_history", methods=["POST"])
@jwt_required()
def create_donation_history():
    data = request.get_json() or {}
    donor_id = data.get("donor_id")
    request_id = data.get("request_id")
    donation_date_raw = data.get("donation_date", "").strip()

    if donor_id is None or request_id is None or not donation_date_raw:
        return jsonify({"msg": "donor_id, request_id, and donation_date are required"}), 400

    try:
        donor_id = int(donor_id)
        request_id = int(request_id)
    except (ValueError, TypeError):
        return jsonify({"msg": "donor_id and request_id must be integers"}), 400

    try:
        donation_date = datetime.strptime(donation_date_raw, "%Y-%m-%d").date()
    except ValueError:
        return jsonify({"msg": "donation_date must be YYYY-MM-DD"}), 400

    donor = Donor.query.get(donor_id)
    br = BloodRequest.query.get(request_id)
    if not donor or not br:
        return jsonify({"msg": "donor or blood request not found"}), 404

    dh = DonationHistory(
        donor_id=donor.id,
        request_id=br.id,
        donation_date=donation_date
    )
    db.session.add(dh)
    db.session.commit()

    return jsonify({
        "id": dh.id,
        "donor_id": dh.donor_id,
        "request_id": dh.request_id,
        "donation_date": dh.donation_date.isoformat()
    }), 201

@blood_bp.route("/donation_history", methods=["GET"])
@jwt_required()
def list_donation_history():
    donor_id = request.args.get("donor_id")
    request_id = request.args.get("request_id")
    query = DonationHistory.query

    if donor_id:
        try:
            query = query.filter(DonationHistory.donor_id == int(donor_id))
        except ValueError:
            return jsonify({"msg": "donor_id must be integer"}), 400
    if request_id:
        try:
            query = query.filter(DonationHistory.request_id == int(request_id))
        except ValueError:
            return jsonify({"msg": "request_id must be integer"}), 400

    histories = query.order_by(DonationHistory.donation_date.desc()).all()
    result = []
    for h in histories:
        result.append({
            "id": h.id,
            "donor_id": h.donor_id,
            "request_id": h.request_id,
            "donation_date": h.donation_date.isoformat()
        })
    return jsonify(result), 200
