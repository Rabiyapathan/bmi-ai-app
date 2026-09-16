import os
import jwt

from flask import Flask, request
from flask_cors import CORS
from dotenv import load_dotenv
from supabase import create_client
from groq import Groq

load_dotenv()

from routes.diet_plan import diet_plan_bp

# --------------------------------------------------
# Flask app
# --------------------------------------------------

app = Flask(__name__)

CORS(app)

app.register_blueprint(diet_plan_bp)


# --------------------------------------------------
# Supabase
# --------------------------------------------------

supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)


# --------------------------------------------------
# Groq
# --------------------------------------------------

groq_client = Groq(
    api_key=os.getenv("GROQ_API_KEY")
)


# --------------------------------------------------
# Authentication helper
# --------------------------------------------------

def get_user_id():
    """
    Extract the Supabase user ID from the
    Authorization Bearer token.

    NOTE:
    Signature verification is intentionally disabled
    for the current local MVP.
    This MUST be replaced with proper JWT verification
    before production deployment.
    """

    auth_header = request.headers.get("Authorization")

    if not auth_header:
        return None

    if not auth_header.startswith("Bearer "):
        return None

    token = auth_header.split(" ", 1)[1]

    try:
        payload = jwt.decode(
            token,
            options={"verify_signature": False}
        )

        return payload.get("sub")

    except Exception:
        return None


# --------------------------------------------------
# Home / health check
# --------------------------------------------------

@app.route("/", methods=["GET"])
def home():
    return {
        "message": "BMI AI backend is running!",
        "status": "ok"
    }


# --------------------------------------------------
# BMI endpoint
# --------------------------------------------------

@app.route("/bmi", methods=["POST"])
def save_bmi():

    user_id = get_user_id()

    if not user_id:
        return {
            "error": "Unauthorized"
        }, 401

    data = request.get_json()

    if not data:
        return {
            "error": "Request body is required"
        }, 400

    if "height_cm" not in data or "weight_kg" not in data:
        return {
            "error": "height_cm and weight_kg are required"
        }, 400

    try:
        height_cm = float(data["height_cm"])
        weight_kg = float(data["weight_kg"])

    except (TypeError, ValueError):
        return {
            "error": "Height and weight must be numbers"
        }, 400

    if height_cm <= 0 or weight_kg <= 0:
        return {
            "error": "Height and weight must be greater than zero"
        }, 400

    # BMI calculation
    bmi = round(
        weight_kg / ((height_cm / 100) ** 2),
        2
    )

    # BMI category
    if bmi < 18.5:
        category = "Underweight"

    elif bmi < 25:
        category = "Normal"

    elif bmi < 30:
        category = "Overweight"

    else:
        category = "Obese"


    # --------------------------------------------------
    # Groq AI advice
    # --------------------------------------------------

    prompt = f"""
You are a friendly general wellness assistant.

A user has the following BMI information:

Height: {height_cm} cm
Weight: {weight_kg} kg
BMI: {bmi}
BMI Category: {category}

Give a short, practical lifestyle response.

Include:
- What this BMI category generally means
- 3 healthy lifestyle suggestions
- A simple reminder that BMI is only a screening measure

Do not diagnose medical conditions.
Do not prescribe medication.
Do not provide unsafe or extreme diet advice.

Keep the response clear and easy to understand.
"""

    try:

        ai_response = groq_client.chat.completions.create(
            model="openai/gpt-oss-120b",
            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )

        ai_advice = ai_response.choices[0].message.content

    except Exception as error:

        print("Groq error:", error)

        ai_advice = (
            "Your BMI result has been calculated successfully. "
            "Focus on balanced nutrition, regular movement, "
            "good hydration and adequate rest."
        )


    # --------------------------------------------------
    # Save BMI record to Supabase
    # --------------------------------------------------

    try:

        result = supabase.table("bmi_records").insert({
            "user_id": user_id,
            "height_cm": height_cm,
            "weight_kg": weight_kg,
            "bmi": bmi,
            "category": category,
            "ai_advice": ai_advice
        }).execute()

    except Exception as error:

        print("Supabase error:", error)

        return {
            "error": "BMI was calculated but could not be saved"
        }, 500


    # --------------------------------------------------
    # Response
    # --------------------------------------------------

    return {
        "message": "BMI record saved successfully!",
        "bmi": bmi,
        "category": category,
        "ai_advice": ai_advice,
        "data": result.data
    }, 201


# --------------------------------------------------
# Run server
# --------------------------------------------------

if __name__ == "__main__":

    app.run(
        debug=True,
        host="0.0.0.0",
        port=5000
    )
