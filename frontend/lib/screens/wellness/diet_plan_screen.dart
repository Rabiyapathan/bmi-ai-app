import 'package:flutter/material.dart';

import '../../models/wellness_preferences.dart';
import '../../theme/app_colors.dart';

class DietPlanScreen extends StatefulWidget {
  final double bmi;
  final String category;
  final WellnessPreferences preferences;
  final Map<String, dynamic> plan;

  const DietPlanScreen({
    super.key,
    required this.bmi,
    required this.category,
    required this.preferences,
    required this.plan,
  });

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _headline {
    switch (widget.category) {
      case 'Underweight':
        return 'Your nourishing wellness plan 🌱';
      case 'Normal':
        return 'Your balanced wellness plan ✨';
      case 'Overweight':
        return 'Your healthy-habits plan 💪';
      case 'Obesity':
        return 'Your wellness plan 💚';
      default:
        return 'Your personalized wellness plan ✨';
    }
  }

  String get _summary {
    return widget.plan['summary']?.toString() ??
        'A plan designed around your preferences and everyday routine.';
  }

  List<Map<String, dynamic>> get _days {
    final rawDays = widget.plan['days'];

    if (rawDays is! List) {
      return [];
    }

    return rawDays
        .whereType<Map>()
        .map(
          (day) => Map<String, dynamic>.from(day),
        )
        .toList();
  }

  List<Map<String, dynamic>> _mealsForDay(
    Map<String, dynamic> day,
  ) {
    final rawMeals = day['meals'];

    if (rawMeals is! List) {
      return [];
    }

    return rawMeals
        .whereType<Map>()
        .map(
          (meal) => Map<String, dynamic>.from(meal),
        )
        .toList();
  }

  List<Map<String, dynamic>> _activitiesForDay(
    Map<String, dynamic> day,
  ) {
    final rawActivities = day['activities'];

    if (rawActivities is! List) {
      return [];
    }

    return rawActivities
        .whereType<Map>()
        .map(
          (activity) => Map<String, dynamic>.from(activity),
        )
        .toList();
  }

  List<String> _hydrationForDay(
    Map<String, dynamic> day,
  ) {
    final rawHydration = day['hydration'];

    if (rawHydration is! List) {
      return [];
    }

    return rawHydration
        .map((item) => item.toString())
        .toList();
  }

  List<String> _tipsForDay(
    Map<String, dynamic> day,
  ) {
    final rawTips = day['tips'];

    if (rawTips is! List) {
      return [];
    }

    return rawTips
        .map((item) => item.toString())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;

    if (days.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('My Wellness Plan'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No weekly wellness plan is available yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final safeDayIndex =
        _selectedDay.clamp(0, days.length - 1);

    final selectedDay = days[safeDayIndex];

    final meals = _mealsForDay(selectedDay);
    final hydration = _hydrationForDay(selectedDay);
    final activities = _activitiesForDay(selectedDay);
    final tips = _tipsForDay(selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Wellness Plan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimated(
                delay: 0.0,
                child: _buildHeroHeader(),
              ),

              const SizedBox(height: 22),

              _buildAnimated(
                delay: 0.08,
                child: _buildBmiCard(),
              ),

              const SizedBox(height: 28),

              _buildAnimated(
                delay: 0.14,
                child: _buildWeekSelector(days),
              ),

              const SizedBox(height: 28),

              _buildAnimated(
                delay: 0.18,
                child: _buildDayHeader(selectedDay),
              ),

              const SizedBox(height: 18),

              if (meals.isNotEmpty) ...[
                _buildAnimated(
                  delay: 0.22,
                  child: _sectionTitle(
                    'Today’s nutrition',
                    'Meal ideas personalized using your preferences.',
                  ),
                ),

                const SizedBox(height: 14),

                ...meals.asMap().entries.map(
                  (entry) => _buildAnimated(
                    delay: 0.25 + (entry.key * 0.04),
                    child: _buildMealCard(entry.value),
                  ),
                ),
              ],

              if (hydration.isNotEmpty) ...[
                const SizedBox(height: 18),

                _buildAnimated(
                  delay: 0.42,
                  child: _sectionTitle(
                    'Hydration',
                    'Simple ways to stay hydrated throughout the day.',
                  ),
                ),

                const SizedBox(height: 14),

                _buildAnimated(
                  delay: 0.46,
                  child: _buildHydrationCard(hydration),
                ),
              ],

              if (activities.isNotEmpty) ...[
                const SizedBox(height: 22),

                _buildAnimated(
                  delay: 0.50,
                  child: _sectionTitle(
                    'Movement & yoga',
                    'Activities matched to your selected preferences.',
                  ),
                ),

                const SizedBox(height: 14),

                ...activities.asMap().entries.map(
                  (entry) => _buildAnimated(
                    delay: 0.54 + (entry.key * 0.04),
                    child: _buildActivityCard(entry.value),
                  ),
                ),
              ],

              if (tips.isNotEmpty) ...[
                const SizedBox(height: 22),

                _buildAnimated(
                  delay: 0.68,
                  child: _sectionTitle(
                    'Daily wellness tips',
                    'Small habits that can make your routine better.',
                  ),
                ),

                const SizedBox(height: 14),

                _buildAnimated(
                  delay: 0.72,
                  child: _buildTipsCard(tips),
                ),
              ],

              const SizedBox(height: 24),

              _buildAnimated(
                delay: 0.80,
                child: _buildDisclaimer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimated({
    required double delay,
    required Widget child,
  }) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        delay.clamp(0.0, 0.9),
        (delay + 0.22).clamp(0.1, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              20 * (1 - animation.value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _headline,
            style: const TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _summary,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current BMI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.bmi.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(
    List<Map<String, dynamic>> days,
  ) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDay;

          final dayName =
              days[index]['day']?.toString() ??
                  'Day ${index + 1}';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = index;
              });

              _animationController
                ..reset()
                ..forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 82,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : AppColors.primary,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    dayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayHeader(
    Map<String, dynamic> day,
  ) {
    final dayName =
        day['day']?.toString() ??
            'Day ${_selectedDay + 1}';

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.today_rounded,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'Your plan for today',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(
    Map<String, dynamic> meal,
  ) {
    final time =
        meal['time']?.toString() ?? 'Meal';

    final foods = meal['foods'] is List
        ? (meal['foods'] as List)
            .map((food) => food.toString())
            .toList()
        : <String>[];

    final note =
        meal['note']?.toString() ?? '';

    final mealInfo = _mealInfo(time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.09),
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Icon(
                  mealInfo.icon,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      mealInfo.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (foods.isNotEmpty) ...[
            const SizedBox(height: 16),

            ...foods.map(
              (food) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin:
                          const EdgeInsets.only(top: 5),
                      width: 7,
                      height: 7,
                      decoration:
                          const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        food,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  _MealInfo _mealInfo(String time) {
    switch (time.toLowerCase()) {
      case 'breakfast':
        return const _MealInfo(
          icon: Icons.wb_sunny_outlined,
          subtitle:
              'Start your day with nourishing food',
        );

      case 'lunch':
        return const _MealInfo(
          icon: Icons.lunch_dining_outlined,
          subtitle:
              'A balanced midday meal',
        );

      case 'evening snack':
      case 'snack':
      case 'evening':
        return const _MealInfo(
          icon: Icons.local_cafe_outlined,
          subtitle:
              'A simple afternoon option',
        );

      case 'dinner':
        return const _MealInfo(
          icon: Icons.nightlight_outlined,
          subtitle:
              'A comfortable evening meal',
        );

      default:
        return const _MealInfo(
          icon: Icons.restaurant_outlined,
          subtitle:
              'A personalized meal idea',
        );
    }
  }

  Widget _buildHydrationCard(
    List<String> hydration,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: hydration.asMap().entries.map(
          (entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key ==
                        hydration.length - 1
                    ? 0
                    : 14,
              ),
              child: _TipRow(
                icon:
                    Icons.water_drop_outlined,
                text: entry.value,
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildActivityCard(
    Map<String, dynamic> activity,
  ) {
    final name =
        activity['name']?.toString() ??
            'Movement';

    final duration =
        activity['duration']?.toString() ??
            '';

    final note =
        activity['note']?.toString() ??
            '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.success
                  .withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: AppColors.success,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: AppColors.success,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        duration,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],

                if (note.isNotEmpty) ...[
                  const SizedBox(height: 7),

                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(
    List<String> tips,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: tips.asMap().entries.map(
          (entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    entry.key == tips.length - 1
                        ? 0
                        : 14,
              ),
              child: _TipRow(
                icon:
                    Icons.check_circle_outline_rounded,
                text: entry.value,
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            AppColors.warning.withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.warning
              .withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'BMI is a screening measure, not a diagnosis. '
              'This app provides general wellness information and '
              'is not a substitute for professional medical advice.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealInfo {
  final IconData icon;
  final String subtitle;

  const _MealInfo({
    required this.icon,
    required this.subtitle,
  });
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: AppColors.primary,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}