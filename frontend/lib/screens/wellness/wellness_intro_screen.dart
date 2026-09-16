import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'wellness_preferences_screen.dart';

class WellnessIntroScreen extends StatelessWidget {
  final double bmi;
  final String category;

  const WellnessIntroScreen({
    super.key,
    required this.bmi,
    required this.category,
  });

  String get _title {
    switch (category) {
      case 'Underweight':
        return 'Let’s build you up 🌱';
      case 'Normal':
        return 'Let’s keep you balanced ✨';
      case 'Overweight':
        return 'Let’s build healthier habits 💪';
      case 'Obese':
        return 'Let’s focus on your wellbeing 💚';
      default:
        return 'Let’s create your wellness plan ✨';
    }
  }

  String get _description {
    switch (category) {
      case 'Underweight':
        return 'We’ll create a nourishing wellness plan focused on balanced meals, healthy habits and gentle activity.';
      case 'Normal':
        return 'We’ll create a balanced plan to help you maintain healthy habits, nutrition and activity.';
      case 'Overweight':
        return 'We’ll create a practical wellness plan focused on balanced nutrition, movement and sustainable habits.';
      case 'Obese':
        return 'We’ll create a gentle wellness plan around balanced nutrition and daily movement. For personalized medical or weight-management advice, consider speaking with a qualified healthcare professional.';
      default:
        return 'Tell us a little about your lifestyle so we can create a wellness plan for you.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Wellness Plan'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.spa_rounded,
                            size: 76,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.monitor_heart_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your current BMI',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${bmi.toStringAsFixed(1)} • $category',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Your plan can include',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const _FeatureRow(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'Personalized meal ideas',
                      ),
                      const _FeatureRow(
                        icon: Icons.self_improvement_rounded,
                        title: 'Yoga & activity suggestions',
                      ),
                      const _FeatureRow(
                        icon: Icons.water_drop_outlined,
                        title: 'Hydration & daily wellness tips',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WellnessPreferencesScreen(
                          bmi: bmi,
                          category: category,
                        ),
                      ),
                    );
                  },
                  child: const Text('Create My Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureRow({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 21,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Icon(
            icon,
            size: 21,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
