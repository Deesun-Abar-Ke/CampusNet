from flask import Blueprint, request, jsonify, send_from_directory, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Department, Course, Note
from werkzeug.utils import secure_filename
import os

study_bp = Blueprint("study", __name__)

# -------------------- Folders --------------------
UPLOAD_FOLDER = os.path.join(os.getcwd(), "uploads", "notes")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

STATIC_FOLDER = os.path.join(os.getcwd(), "static")
DEFAULT_PDF = "note.pdf"

# -------------------- Serve Files --------------------
@study_bp.route("/notes/files/<path:filename>")
def serve_note_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename, as_attachment=False)

@study_bp.route("/notes/default")
def serve_default_note():
    default_pdf_path = os.path.join(STATIC_FOLDER, DEFAULT_PDF)
    if os.path.exists(default_pdf_path):
        return send_file(default_pdf_path, as_attachment=False)
    return jsonify({"msg": "Default PDF not found"}), 404

# -------------------- Departments --------------------
@study_bp.route("/departments", methods=["POST"])
def create_department():
    data = request.get_json() or {}
    name = (data.get("name") or "").strip()
    icon = (data.get("icon") or "").strip()
    if not name:
        return jsonify({"msg": "Department name is required"}), 400

    if Department.query.filter(Department.name.ilike(name)).first():
        return jsonify({"msg": "Department with that name already exists"}), 409

    department = Department(name=name, icon=icon or None)
    db.session.add(department)
    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        return jsonify({"msg": "Failed to create department"}), 500

    return jsonify({"id": department.id, "name": department.name, "icon": department.icon}), 201

@study_bp.route("/departments", methods=["GET"])
def get_departments():
    departments = Department.query.all()
    return jsonify([{"id": d.id, "name": d.name, "icon": d.icon} for d in departments]), 200

# -------------------- Courses --------------------
@study_bp.route("/courses", methods=["POST"])
def create_course():
    data = request.get_json() or {}
    name = (data.get("name") or "").strip()
    department_id = data.get("department_id")
    if not name or department_id is None:
        return jsonify({"msg": "Course name and department_id are required"}), 400

    try:
        department_id = int(department_id)
    except (ValueError, TypeError):
        return jsonify({"msg": "department_id must be an integer"}), 400

    if not Department.query.get(department_id):
        return jsonify({"msg": "Department not found"}), 404

    if Course.query.filter(Course.department_id == department_id, Course.name.ilike(name)).first():
        return jsonify({"msg": "Course with that name already exists in this department"}), 409

    course = Course(name=name, department_id=department_id)
    db.session.add(course)
    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        return jsonify({"msg": "Failed to create course"}), 500

    return jsonify({"id": course.id, "name": course.name, "department_id": course.department_id}), 201

@study_bp.route("/courses", methods=["GET"])
def get_courses():
    department_id = request.args.get("department_id")
    query = Course.query
    if department_id:
        try:
            query = query.filter(Course.department_id == int(department_id))
        except ValueError:
            return jsonify({"msg": "department_id must be integer"}), 400
    courses = query.all()
    return jsonify([{"id": c.id, "name": c.name, "department_id": c.department_id} for c in courses]), 200

# -------------------- Notes --------------------
@study_bp.route("/notes", methods=["GET"])
def get_notes():
    course_id = request.args.get("course_id")
    query = Note.query
    if course_id:
        try:
            query = query.filter(Note.course_id == int(course_id))
        except ValueError:
            return jsonify({"msg": "course_id must be integer"}), 400
    notes = query.order_by(Note.uploaded_at.desc()).all()

    result = []
    for n in notes:
        result.append({
            "id": n.id,
            "filename": n.filename,
            "file_url": n.file_url if n.file_url else "/study/notes/default",
            "file_type": n.file_type,
            "uploaded_at": n.uploaded_at.isoformat(),
            "uploaded_by": n.uploaded_by,
            "course_id": n.course_id
        })
    return jsonify(result), 200

@study_bp.route("/notes", methods=["POST"])
@jwt_required()
def upload_note():
    data = request.get_json() or {}
    filename = data.get("filename", "").strip()
    file_url = data.get("file_url", "").strip()
    file_type = data.get("file_type", "").strip().lower()
    course_id = data.get("course_id")

    if not filename or not file_type or not course_id:
        return jsonify({"msg": "filename, file_type, and course_id are required"}), 400

    if file_type not in ["pdf", "ppt", "pptx"]:
        return jsonify({"msg": "file_type must be one of pdf, ppt, pptx"}), 400

    try:
        course_id = int(course_id)
    except (ValueError, TypeError):
        return jsonify({"msg": "course_id must be integer"}), 400

    user_id = int(get_jwt_identity())

    note = Note(
        filename=filename,
        file_url=file_url if file_url else "/study/notes/default",
        file_type=file_type,
        course_id=course_id,
        uploaded_by=user_id
    )
    db.session.add(note)
    db.session.commit()

    return jsonify({
        "id": note.id,
        "filename": note.filename,
        "file_url": note.file_url,
        "file_type": note.file_type,
        "uploaded_at": note.uploaded_at.isoformat(),
        "uploaded_by": note.uploaded_by,
        "course_id": note.course_id
    }), 201

# -------------------- Upload File Endpoint --------------------
@study_bp.route("/notes/upload", methods=["POST"])
def upload_note_file():
    if "file" not in request.files:
        return jsonify({"msg": "No file part"}), 400
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"msg": "No selected file"}), 400

    filename = secure_filename(file.filename)
    save_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(save_path)

    return jsonify({"file_url": f"/study/notes/files/{filename}"}), 200

# -------------------- Delete Note --------------------
@study_bp.route("/notes/<int:note_id>", methods=["DELETE"])
@jwt_required()
def delete_note(note_id):
    user_id = int(get_jwt_identity())
    note = Note.query.get(note_id)
    
    if not note:
        return jsonify({"msg": "Note not found"}), 404

    # Only uploader can delete
    if note.uploaded_by != user_id:
        return jsonify({"msg": "You are not authorized to delete this note"}), 403

    # Remove file from disk if not default
    if note.file_url != "/study/notes/default":
        file_path = os.path.join(UPLOAD_FOLDER, os.path.basename(note.file_url))
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception as e:
                return jsonify({"msg": f"Failed to delete file: {str(e)}"}), 500

    db.session.delete(note)
    db.session.commit()

    return jsonify({"msg": "Note deleted successfully"}), 200
