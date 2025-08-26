from flask import Blueprint, request, jsonify
import os
import requests
from dotenv import load_dotenv

load_dotenv()

ai_bp = Blueprint("ai", __name__)

@ai_bp.route("/ai/refine", methods=["POST"])
def refine_text():
    data = request.get_json() or {}
    text = (data.get("text") or "").strip()
    print("Received text:", text)

    if not text:
        return jsonify({"msg": "text is required"}), 400

    # Load API key
    GROQ_API_KEY = os.getenv("GROQ_API_KEY")
    if not GROQ_API_KEY:
        return jsonify({"msg": "GROQ API key not configured"}), 500

    system_prompt = (
        "You are a helpful editor. Improve the user's text by fixing grammar, spelling, punctuation, "
        "and structure. Keep the meaning the same and make it clear and professional. "
        "Return only the improved text without commentary."
    )

    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "model": "llama-3.3-70b-versatile",
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are a precise text refiner. "
                    "Your ONLY task is to improve the user’s text by fixing grammar, spelling, punctuation, and clarity. "
                    "Do NOT add greetings, explanations, or commentary. "
                    "Always return ONLY the improved version of the input text."
                )
            },
            # --- Few-shot examples ---
            {"role": "user", "content": "i am a good dedicated teacher"},
            {"role": "assistant", "content": "I am a dedicated teacher."},

            {"role": "user", "content": "i have experiece in admission students 2 year"},
            {"role": "assistant", "content": "I have 2 years of experience teaching admission students."},

            {"role": "user", "content": "now i am curretly cs student level 4"},
            {"role": "assistant", "content": "I am currently a 4th-year Computer Science student."},

            # --- Actual user text will be appended here ---
            {"role": "user", "content": text}
        ],
        "temperature": 0.2,
        "max_tokens": 512
    }


    try:
        resp = requests.post(url, headers=headers, json=body, timeout=20)
        print("Groq status:", resp.status_code)
        print("Groq response:", resp.text)

        resp.raise_for_status()
        j = resp.json()

        # ✅ Correct parsing
        refined = ""
        try:
            refined = j["choices"][0]["message"]["content"].strip()
        except Exception:
            refined = j.get("text", "")

        if not refined:
            return jsonify({"msg": "AI returned empty response", "raw": j}), 502

        return jsonify({"refined": refined}), 200

    except requests.exceptions.HTTPError as he:
        return jsonify({
            "msg": "AI request failed (http)",
            "error": str(he),
            "status": getattr(he.response, 'status_code', None),
            "body": getattr(he.response, 'text', None)
        }), 500
    except Exception as e:
        return jsonify({"msg": "AI request failed", "error": str(e)}), 500
