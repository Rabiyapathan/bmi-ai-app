class WellnessPreferences {
  final String goal;
  final String activityLevel;
  final String countryRegion;
  final String customCountryRegion;
  final String foodPreference;
  final String customFoodPreference;
  final String dietType;
  final List<String> allergies;
  final List<String> dislikedFoods;
  final String mealPreference;
  final String yogaPreference;

  const WellnessPreferences({
    required this.goal,
    required this.activityLevel,
    required this.countryRegion,
    required this.customCountryRegion,
    required this.foodPreference,
    required this.customFoodPreference,
    required this.dietType,
    required this.allergies,
    required this.dislikedFoods,
    required this.mealPreference,
    required this.yogaPreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'activity_level': activityLevel,
      'country_region': countryRegion,
      'custom_country_region': customCountryRegion,
      'food_preference': foodPreference,
      'custom_food_preference': customFoodPreference,
      'diet_type': dietType,
      'allergies': allergies,
      'disliked_foods': dislikedFoods,
      'meal_preference': mealPreference,
      'yoga_preference': yogaPreference,
    };
  }
}