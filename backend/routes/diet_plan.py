from flask import Blueprint, request, jsonify

from services.diet_ai_service import generate_diet_plan


diet_plan_bp = Blueprint("diet_plan", __name__)


@diet_plan_bp.route("/diet-plan", methods=["POST"])
def create_diet_plan():
    data = request.get_json()

    if not data:
        return jsonify({
            "error": "Request body is required"
        }), 400

    required_fields = [
        "bmi",
        "category",
        "goal",
        "activity_level",
        "country_region",
        "custom_country_region",
        "food_preference",
        "custom_food_preference",
        "diet_type",
        "allergies",
        "disliked_foods",
        "meal_preference",
        "yoga_preference",
    ]

    missing_fields = [
        field
        for field in required_fields
        if field not in data
    ]

    if missing_fields:
        return jsonify({
            "error": "Missing required fields",
            "fields": missing_fields,
        }), 400

    try:
        plan = generate_diet_plan(
            bmi=data["bmi"],
            category=data["category"],
            goal=data["goal"],
            activity_level=data["activity_level"],
            country_region=data["country_region"],
            custom_country_region=data["custom_country_region"],
            food_preference=data["food_preference"],
            custom_food_preference=data["custom_food_preference"],
            diet_type=data["diet_type"],
            allergies=data["allergies"],
            disliked_foods=data["disliked_foods"],
            meal_preference=data["meal_preference"],
            yoga_preference=data["yoga_preference"],
        )

        return jsonify({
            "success": True,
            "plan": plan,
        })

    except Exception as error:
        print("Diet plan generation error:", error)

        return jsonify({
            "success": False,
            "error": "Unable to generate wellness plan",
        }), 500
