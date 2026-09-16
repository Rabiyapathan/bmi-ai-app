from groq import Groq
import os
import json


groq_client = Groq(
    api_key=os.getenv("GROQ_API_KEY")
)


EXPECTED_DAYS = [
    "Day 1",
    "Day 2",
    "Day 3",
    "Day 4",
    "Day 5",
    "Day 6",
    "Day 7",
]


def _fallback_meals(day_number):
    return [
        {
            "time": "Breakfast",
            "foods": ["Poha", "Fruit"],
            "note": "A simple homemade breakfast option."
        },
        {
            "time": "Lunch",
            "foods": ["Dal", "Rice", "Vegetable sabzi"],
            "note": "A balanced homemade lunch."
        },
        {
            "time": "Evening Snack",
            "foods": ["Fruit", "Nuts"],
            "note": "A simple snack option."
        },
        {
            "time": "Dinner",
            "foods": ["Roti", "Vegetable sabzi", "Dal"],
            "note": "Keep dinner simple and balanced."
        },
    ]


def _repair_day(day, day_number):
    if not isinstance(day, dict):
        day = {}

    day["day"] = f"Day {day_number}"

    if not isinstance(day.get("meals"), list) or len(day["meals"]) < 4:
        day["meals"] = _fallback_meals(day_number)

    repaired_meals = []

    meal_names = [
        "Breakfast",
        "Lunch",
        "Evening Snack",
        "Dinner",
    ]

    for index, meal_name in enumerate(meal_names):
        meal = day["meals"][index] if index < len(day["meals"]) else {}

        if not isinstance(meal, dict):
            meal = {}

        meal["time"] = meal_name

        if not isinstance(meal.get("foods"), list) or not meal["foods"]:
            fallback = _fallback_meals(day_number)[index]
            meal["foods"] = fallback["foods"]

        if not meal.get("note"):
            meal["note"] = "A practical everyday meal option."

        repaired_meals.append(meal)

    day["meals"] = repaired_meals

    if not isinstance(day.get("hydration"), list) or not day["hydration"]:
        day["hydration"] = [
            "Drink water regularly throughout the day.",
            "Drink according to thirst and your normal routine."
        ]

    if not isinstance(day.get("activities"), list) or not day["activities"]:
        day["activities"] = [
            {
                "name": "Light stretching",
                "duration": "10 minutes",
                "note": "Keep movements gentle and comfortable."
            }
        ]

    repaired_activities = []

    for activity in day["activities"]:
        if not isinstance(activity, dict):
            continue

        if not activity.get("name"):
            activity["name"] = "Light stretching"

        if not activity.get("duration"):
            activity["duration"] = "10 minutes"

        if not activity.get("note"):
            activity["note"] = "Keep the activity gentle and comfortable."

        repaired_activities.append(activity)

    if not repaired_activities:
        repaired_activities = [
            {
                "name": "Light stretching",
                "duration": "10 minutes",
                "note": "Keep movements gentle and comfortable."
            }
        ]

    day["activities"] = repaired_activities

    if not isinstance(day.get("tips"), list) or not day["tips"]:
        day["tips"] = [
            "Choose practical meals that fit your normal routine.",
            "Stay consistent rather than trying extreme changes."
        ]

    return day


def _repair_plan(plan):
    if not isinstance(plan, dict):
        plan = {}

    if not plan.get("summary"):
        plan["summary"] = (
            "A practical 7-day wellness plan with balanced meals, "
            "hydration and gentle activities."
        )

    existing_days = plan.get("days")

    if not isinstance(existing_days, list):
        existing_days = []

    repaired_days = []

    for index, expected_day in enumerate(EXPECTED_DAYS):
        matching_day = None

        # First try to find the correct day by its name.
        for day in existing_days:
            if isinstance(day, dict) and day.get("day") == expected_day:
                matching_day = day
                break

        # If the AI omitted this day, create a safe fallback.
        if matching_day is None:
            matching_day = {}

        repaired_days.append(
            _repair_day(matching_day, index + 1)
        )

    plan["days"] = repaired_days

    return plan


def generate_diet_plan(
    bmi,
    category,
    goal,
    activity_level,
    country_region,
    custom_country_region,
    food_preference,
    custom_food_preference,
    diet_type,
    allergies,
    disliked_foods,
    meal_preference,
    yoga_preference,
):

    prompt = f"""
You are a friendly general wellness assistant.

Create a personalized 7-day GENERAL WELLNESS PLAN.

USER DATA
---------

BMI: {bmi}
BMI Category: {category}

Goal: {goal}
Activity Level: {activity_level}

Country/Region: {country_region}
Custom Country/Region: {custom_country_region}

Food Preference: {food_preference}
Custom Food Preference: {custom_food_preference}

Diet Type: {diet_type}

Allergies: {allergies}

Disliked Foods: {disliked_foods}

Meal Preference: {meal_preference}

Yoga Preference: {yoga_preference}


FOOD PERSONALIZATION
--------------------

- Respect the selected country or region.
- Prefer foods commonly available in that region.
- Do not automatically recommend Western diet foods.
- For Indian users, prefer familiar Indian foods when appropriate.
- Indian examples include dal, rice, roti, chapati, sabzi, poha,
  upma, idli, dosa, khichdi, curd, fruits, nuts, sprouts and paneer.
- Biryani may also be included occasionally when appropriate for the
  user's diet type and preferences. It does not need to appear every day.
- Regional Indian foods are encouraged when suitable.
- If custom food preference is provided, use it.
- Respect allergies strictly.
- Never recommend an allergen.
- Respect disliked foods.
- Respect the selected diet type.
- Keep meals affordable, practical and familiar.
- Avoid expensive specialty ingredients unless requested.
- Use different meal combinations across the week.
- Do not repeat the exact same daily menu.
- If the user prefers homemade food, prioritize homemade-style meals.


MEALS
-----

Every day must contain exactly four meals:

Breakfast
Lunch
Evening Snack
Dinner

Every meal must contain:

"time"
"foods"
"note"

The foods field should contain realistic food items.


ACTIVITY
--------

Every day must contain beginner-friendly activities.

Possible activities include:

Walking
Light stretching
Beginner yoga
Breathing exercises
Mobility exercises
Gentle home exercises

Respect the selected yoga preference.

Do not prescribe intense exercise.

If the BMI category is Obesity, include a gentle reminder that
individualized guidance from a qualified healthcare professional
may be useful.


HYDRATION
---------

Give practical hydration suggestions.

Do not prescribe excessive water intake.


SAFETY
------

This is general wellness information, not medical advice.

Do not diagnose diseases.
Do not prescribe medication.
Do not recommend crash diets.
Do not recommend starvation.
Do not encourage meal skipping.
Do not recommend unsafe weight-loss methods.
Do not give rigid medical calorie prescriptions.

Keep recommendations practical and beginner-friendly.


OUTPUT
------

Return ONLY valid JSON.

Do not use markdown.
Do not use code fences.
Do not write anything before or after the JSON.

The JSON must contain exactly:

summary
days

The days array MUST contain:

Day 1
Day 2
Day 3
Day 4
Day 5
Day 6
Day 7

Every day MUST contain:

day
meals
hydration
activities
tips

Every day MUST contain exactly four meals:

Breakfast
Lunch
Evening Snack
Dinner

Return this structure:

{{
  "summary": "short personalized summary",
  "days": [
    {{
      "day": "Day 1",
      "meals": [
        {{
          "time": "Breakfast",
          "foods": ["food 1", "food 2"],
          "note": "short helpful note"
        }},
        {{
          "time": "Lunch",
          "foods": ["food 1", "food 2"],
          "note": "short helpful note"
        }},
        {{
          "time": "Evening Snack",
          "foods": ["food 1", "food 2"],
          "note": "short helpful note"
        }},
        {{
          "time": "Dinner",
          "foods": ["food 1", "food 2"],
          "note": "short helpful note"
        }}
      ],
      "hydration": [
        "hydration suggestion 1",
        "hydration suggestion 2"
      ],
      "activities": [
        {{
          "name": "activity name",
          "duration": "duration",
          "note": "short helpful note"
        }}
      ],
      "tips": [
        "daily wellness tip 1",
        "daily wellness tip 2"
      ]
    }},
    {{
      "day": "Day 2",
      "meals": [],
      "hydration": [],
      "activities": [],
      "tips": []
    }},
    {{
      "day": "Day 3",
      "meals": [],
      "hydration": [],
      "activities": [],
      "tips": []
    }},
    {{
      "day": "Day 4",
      "meals": [],
      "hydration": [],
      "activities": [],
      "tips": []
    }},
    {{
      "day": "Day 5",
      "meals": [],
      "hydration": [],
      "activities": [],
      "tips": []
    }},
    {{
      "day": "Day 6",
      "meals": [],
      "hydration": [],
      "activities": [],
      "tips": []
    }},
    {{
      "day": "Day 7",
      "meals": [],
      "hydration": [],
      "activities": [],
      "tips": []
    }}
  ]
}}
"""

    try:
        response = groq_client.chat.completions.create(
            model="openai/gpt-oss-120b",
            messages=[
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            response_format={
                "type": "json_object"
            },
            temperature=0.7,
        )

        content = response.choices[0].message.content

        if not content:
            raise ValueError("Groq returned an empty response.")

        plan = json.loads(content)

        if not isinstance(plan, dict):
            raise ValueError("AI response is not a JSON object.")

        # Repair incomplete AI output instead of failing.
        plan = _repair_plan(plan)

        return plan

    except json.JSONDecodeError as error:
        print("Diet plan JSON parsing error:", error)
        raise ValueError(
            "The AI returned an invalid JSON response. Please try again."
        )

    except Exception as error:
        print("Diet plan generation error:", error)
        raise