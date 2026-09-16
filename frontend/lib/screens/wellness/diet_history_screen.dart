import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/wellness_preferences.dart';
import '../../theme/app_colors.dart';

import 'diet_plan_screen.dart';

class DietHistoryScreen extends StatefulWidget {
  const DietHistoryScreen({super.key});

  @override
  State<DietHistoryScreen> createState() => _DietHistoryScreenState();
}

class _DietHistoryScreenState extends State<DietHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadDietHistory();
  }

  Future<void> _loadDietHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('You must be logged in to view diet history.');
      }

      final response = await _supabase
          .from('wellness_plans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _plans = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    final date = DateTime.tryParse(dateString);

    if (date == null) return 'Unknown date';

    final localDate = date.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return Colors.blue;
      case 'normal':
        return Colors.green;
      case 'overweight':
        return Colors.orange;
      case 'obesity':
      case 'obese':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _openPlan(Map<String, dynamic> plan) async {
  final savedPreferences =
      Map<String, dynamic>.from(plan['preferences'] ?? {});

  final planJson =
      Map<String, dynamic>.from(plan['plan_json'] ?? {});

  final preferences = WellnessPreferences(
    goal: savedPreferences['goal']?.toString() ?? '',
    activityLevel:
        savedPreferences['activity_level']?.toString() ?? '',
    countryRegion:
        savedPreferences['country_region']?.toString() ?? '',
    customCountryRegion:
        savedPreferences['custom_country_region']?.toString() ?? '',
    foodPreference:
        savedPreferences['food_preference']?.toString() ?? '',
    customFoodPreference:
        savedPreferences['custom_food_preference']?.toString() ?? '',
    dietType:
        savedPreferences['diet_type']?.toString() ?? '',
    allergies: List<String>.from(
      savedPreferences['allergies'] ?? [],
    ),
    dislikedFoods: List<String>.from(
      savedPreferences['disliked_foods'] ?? [],
    ),
    mealPreference:
        savedPreferences['meal_preference']?.toString() ?? '',
    yogaPreference:
        savedPreferences['yoga_preference']?.toString() ?? '',
  );

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DietPlanScreen(
        bmi: (plan['bmi'] as num).toDouble(),
        category: plan['category']?.toString() ?? 'Normal',
        preferences: preferences,
        plan: planJson,
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Diet History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDietHistory,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Could not load your diet history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadDietHistory,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_plans.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.restaurant_menu_rounded,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            'No diet plans yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first personalized wellness plan and it will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];

        final bmi = (plan['bmi'] as num?)?.toDouble() ?? 0;
        final category = plan['category']?.toString() ?? 'Normal';
        final createdAt = plan['created_at']?.toString();

        final summary =
            (plan['plan_json']?['summary'] ?? '').toString();

        return _buildPlanCard(
          plan: plan,
          bmi: bmi,
          category: category,
          createdAt: createdAt,
          summary: summary,
          isLatest: index == 0,
        );
      },
    );
  }

  Widget _buildPlanCard({
    required Map<String, dynamic> plan,
    required double bmi,
    required String category,
    required String? createdAt,
    required String summary,
    required bool isLatest,
  }) {
    final categoryColor = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.07),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLatest
                            ? 'Latest Wellness Plan'
                            : 'Wellness Plan',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Latest',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _infoBox(
                    icon: Icons.monitor_weight_outlined,
                    title: 'BMI',
                    value: bmi.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoBox(
                    icon: Icons.favorite_outline,
                    title: 'Category',
                    value: category,
                    valueColor: categoryColor,
                  ),
                ),
              ],
            ),

            if (summary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1.5,
                  color: Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPlan(plan),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Full Plan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}