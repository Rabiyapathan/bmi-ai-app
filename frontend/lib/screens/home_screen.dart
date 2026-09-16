import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wellness_preferences.dart';
import '../theme/app_colors.dart';

import 'bmi_calculator_screen.dart';
import 'bmi_history_screen.dart';
import 'profile_screen.dart';
import 'daily_checkin_screen.dart';

import 'wellness/diet_history_screen.dart';
import 'wellness/diet_plan_screen.dart';
import 'wellness/wellness_intro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _userName = 'there';

  double? _latestBmi;
  String? _latestCategory;
  bool _loadingBmi = true;

  Map<String, dynamic>? _latestWellnessPlan;
  bool _loadingPlan = true;

  int _todayCompletedCount = 0;
  int _todayCompletionPercentage = 0;
  bool _loadingTodayProgress = true;

  int _currentStreak = 0;
  bool _loadingStreak = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _loadUserName();

    await Future.wait([
      _loadLatestBmi(),
      _loadLatestWellnessPlan(),
      _loadTodayProgress(),
      _loadStreak(),
    ]);
  }

  void _loadUserName() {
    final user = _supabase.auth.currentUser;
    final metadata = user?.userMetadata;

    final name = metadata?['full_name']?.toString().trim();

    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _loadLatestBmi() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingBmi = false;
        });
      }
      return;
    }

    try {
      final data = await _supabase
          .from('bmi_records')
          .select('bmi, category, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          _latestBmi = (data['bmi'] as num?)?.toDouble();
          _latestCategory = data['category']?.toString();
          _loadingBmi = false;
        });
      } else {
        setState(() {
          _latestBmi = null;
          _latestCategory = null;
          _loadingBmi = false;
        });
      }
    } catch (e) {
      debugPrint('Latest BMI error: $e');

      if (mounted) {
        setState(() {
          _loadingBmi = false;
        });
      }
    }
  }

  Future<void> _loadLatestWellnessPlan() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingPlan = false;
        });
      }
      return;
    }

    try {
      final data = await _supabase
          .from('wellness_plans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _latestWellnessPlan = data;
        _loadingPlan = false;
      });
    } catch (e) {
      debugPrint('Latest wellness plan error: $e');

      if (mounted) {
        setState(() {
          _latestWellnessPlan = null;
          _loadingPlan = false;
        });
      }
    }
  }

  Future<void> _loadTodayProgress() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingTodayProgress = false;
        });
      }
      return;
    }

    try {
      final today = _todayString();

      final data = await _supabase
          .from('daily_checkins')
          .select(
            'breakfast_completed, lunch_completed, snack_completed, '
            'dinner_completed, water_completed, activity_completed, '
            'completion_percentage',
          )
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _todayCompletedCount = 0;
          _todayCompletionPercentage = 0;
          _loadingTodayProgress = false;
        });
        return;
      }

      final completed = [
        data['breakfast_completed'] == true,
        data['lunch_completed'] == true,
        data['snack_completed'] == true,
        data['dinner_completed'] == true,
        data['water_completed'] == true,
        data['activity_completed'] == true,
      ];

      final completedCount =
          completed.where((item) => item).length;

      final percentage =
          (data['completion_percentage'] as num?)?.toInt() ??
              ((completedCount / 6) * 100).round();

      setState(() {
        _todayCompletedCount = completedCount;
        _todayCompletionPercentage = percentage;
        _loadingTodayProgress = false;
      });
    } catch (e) {
      debugPrint('Today progress error: $e');

      if (mounted) {
        setState(() {
          _loadingTodayProgress = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // STREAK
  // ------------------------------------------------------------

  Future<void> _loadStreak() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _currentStreak = 0;
          _loadingStreak = false;
        });
      }
      return;
    }

    try {
      final data = await _supabase
          .from('daily_checkins')
          .select(
            'date, breakfast_completed, lunch_completed, '
            'snack_completed, dinner_completed, '
            'water_completed, activity_completed',
          )
          .eq('user_id', user.id)
          .order('date', ascending: false);

      final completedDates = <DateTime>{};

      for (final row in data) {
        final isCompleted = _isDayCompleted(row);

        if (!isCompleted) {
          continue;
        }

        final dateString = row['date']?.toString();

        if (dateString == null) {
          continue;
        }

        final date = DateTime.tryParse(dateString);

        if (date != null) {
          completedDates.add(
            DateTime(date.year, date.month, date.day),
          );
        }
      }

      final today = _dateOnly(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));

      int streak = 0;

      // If today is complete, start counting from today.
      // Otherwise, start from yesterday so a user doesn't
      // lose their existing streak during an unfinished day.
      DateTime currentDate;

      if (completedDates.contains(today)) {
        currentDate = today;
      } else {
        currentDate = yesterday;
      }

      while (completedDates.contains(currentDate)) {
        streak++;

        currentDate =
            currentDate.subtract(const Duration(days: 1));
      }

      if (!mounted) return;

      setState(() {
        _currentStreak = streak;
        _loadingStreak = false;
      });
    } catch (e) {
      debugPrint('Streak error: $e');

      if (mounted) {
        setState(() {
          _currentStreak = 0;
          _loadingStreak = false;
        });
      }
    }
  }

  bool _isDayCompleted(Map<String, dynamic> row) {
    return row['breakfast_completed'] == true &&
        row['lunch_completed'] == true &&
        row['snack_completed'] == true &&
        row['dinner_completed'] == true &&
        row['water_completed'] == true &&
        row['activity_completed'] == true;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  String _todayString() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ------------------------------------------------------------
  // REFRESH
  // ------------------------------------------------------------

  Future<void> _refreshHome() async {
    await Future.wait([
      _loadLatestBmi(),
      _loadLatestWellnessPlan(),
      _loadTodayProgress(),
      _loadStreak(),
    ]);
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  Future<void> _openDailyCheckin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DailyCheckinScreen(),
      ),
    );

    await Future.wait([
      _loadTodayProgress(),
      _loadStreak(),
    ]);
  }

  Future<void> _openCalculator() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BmiCalculatorScreen(),
      ),
    );

    await _refreshHome();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BmiHistoryScreen(),
      ),
    );

    await _refreshHome();
  }

  Future<void> _openDietPlan() async {
    if (_latestBmi == null || _latestCategory == null) {
      await _openCalculator();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WellnessIntroScreen(
          bmi: _latestBmi!,
          category: _latestCategory!,
        ),
      ),
    );

    await _loadLatestWellnessPlan();
  }

  Future<void> _openSavedPlan() async {
    final plan = _latestWellnessPlan;

    if (plan == null) {
      await _openDietPlan();
      return;
    }

    try {
      final savedPreferences =
          Map<String, dynamic>.from(
        plan['preferences'] ?? {},
      );

      final planJson =
          Map<String, dynamic>.from(
        plan['plan_json'] ?? {},
      );

      final preferences = WellnessPreferences(
        goal:
            savedPreferences['goal']?.toString() ?? '',
        activityLevel:
            savedPreferences['activity_level']?.toString() ??
                '',
        countryRegion:
            savedPreferences['country_region']?.toString() ??
                '',
        customCountryRegion:
            savedPreferences['custom_country_region']
                    ?.toString() ??
                '',
        foodPreference:
            savedPreferences['food_preference']?.toString() ??
                '',
        customFoodPreference:
            savedPreferences['custom_food_preference']
                    ?.toString() ??
                '',
        dietType:
            savedPreferences['diet_type']?.toString() ?? '',
        allergies: List<String>.from(
          savedPreferences['allergies'] ?? [],
        ),
        dislikedFoods: List<String>.from(
          savedPreferences['disliked_foods'] ?? [],
        ),
        mealPreference:
            savedPreferences['meal_preference']?.toString() ??
                '',
        yogaPreference:
            savedPreferences['yoga_preference']?.toString() ??
                '',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DietPlanScreen(
            bmi:
                (plan['bmi'] as num?)?.toDouble() ?? 0,
            category:
                plan['category']?.toString() ?? 'Normal',
            preferences: preferences,
            plan: planJson,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Open saved wellness plan error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open your saved plan: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDietHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DietHistoryScreen(),
      ),
    );

    await _loadLatestWellnessPlan();
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    _loadUserName();
  }

  void _showStreakMessage() {
    if (_loadingStreak) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading your streak...'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final message = _currentStreak == 0
        ? 'Complete all 6 habits today to start your streak 🌱'
        : _currentStreak == 1
            ? 'You have a 1 day streak! Keep going 🔥'
            : 'You are on a $_currentStreak day streak! Keep it going 🔥';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNotificationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No new notifications right now 💗',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        break;

      case 1:
        _openDietPlan();
        break;

      case 2:
        _openHistory();
        break;

      case 3:
        _openProfile();
        break;
    }
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    final date = DateTime.tryParse(dateString);

    if (date == null) return '';

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

    return '${localDate.day} '
        '${months[localDate.month - 1]} '
        '${localDate.year}';
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

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BMI AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showNotificationMessage,
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHome,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning 👋',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 24),

                _buildBmiCard(),

                const SizedBox(height: 28),

                _buildStreakCard(),

                const SizedBox(height: 20),

                _buildTodayProgressCard(),

                const SizedBox(height: 28),

                _buildLatestPlanSection(),

                const SizedBox(height: 28),

                const Text(
                  'Quick actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon:
                            Icons.check_circle_outline_rounded,
                        title: 'Daily check-in',
                        subtitle: 'Track today',
                        onTap: _openDailyCheckin,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionCard(
                        icon:
                            Icons.restaurant_menu_rounded,
                        title: 'Diet plan',
                        subtitle: 'Create a plan',
                        onTap: _openDietPlan,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.history_rounded,
                        title: 'Diet history',
                        subtitle: 'View saved plans',
                        onTap: _openDietHistory,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.show_chart_rounded,
                        title: 'BMI history',
                        subtitle: 'Track progress',
                        onTap: _openHistory,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon:
                            Icons.person_outline_rounded,
                        title: 'Profile',
                        subtitle: 'Manage account',
                        onTap: _openProfile,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionCard(
                        icon:
                            Icons.local_fire_department_rounded,
                        title: 'My streak',
                        subtitle: _loadingStreak
                            ? 'Loading...'
                            : '$_currentStreak day streak',
                        onTap: _showStreakMessage,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Daily wellness',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              AppColors.accent.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take care of yourself 💗',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Small healthy habits every day can make a meaningful difference over time.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color:
                                    AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI wellness insights',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                                color:
                                    AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _latestBmi == null
                                  ? 'Your personalized insights will appear here after your first BMI calculation.'
                                  : 'Your wellness plan can be personalized using your latest BMI and preferences.',
                              style: const TextStyle(
                                fontSize: 13,
                                color:
                                    AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected:
            _handleBottomNavigation,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.restaurant_outlined,
            ),
            selectedIcon: Icon(
              Icons.restaurant_rounded,
            ),
            label: 'Diet',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.show_chart_outlined,
            ),
            selectedIcon: Icon(
              Icons.show_chart_rounded,
            ),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STREAK CARD
  // ------------------------------------------------------------

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
              size: 31,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your streak',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                if (_loadingStreak)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                else
                  Text(
                    '$_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color:
                          AppColors.textPrimary,
                    ),
                  ),

                const SizedBox(height: 3),

                Text(
                  _currentStreak == 0
                      ? 'Complete all 6 habits to start 🔥'
                      : 'Keep your healthy routine going!',
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: _showStreakMessage,
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TODAY'S PROGRESS
  // ------------------------------------------------------------

  Widget _buildTodayProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's progress",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Keep building your healthy routine',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: _openDailyCheckin,
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_loadingTodayProgress)
            const LinearProgressIndicator()
          else ...[
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_todayCompletedCount / 6 habits',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$_todayCompletionPercentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value:
                    _todayCompletionPercentage / 100,
                minHeight: 9,
                backgroundColor:
                    AppColors.border,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _todayCompletedCount == 0
                  ? 'Start your first check-in for today 🌱'
                  : _todayCompletedCount == 6
                      ? 'Amazing! You completed everything today 🎉'
                      : 'You are making progress. Keep going 💗',
              style: const TextStyle(
                fontSize: 13,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openDailyCheckin,
              icon: const Icon(
                Icons.check_circle_outline_rounded,
              ),
              label: Text(
                _todayCompletedCount == 0
                    ? "Start today's check-in"
                    : "Update today's check-in",
              ),
              style:
                  OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LATEST WELLNESS PLAN
  // ------------------------------------------------------------

  Widget _buildLatestPlanSection() {
    if (_loadingPlan) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(width: 14),
            Text(
              'Loading your wellness plan...',
              style: TextStyle(
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_latestWellnessPlan == null) {
      return _buildNoPlanCard();
    }

    final plan = _latestWellnessPlan!;

    final bmi =
        (plan['bmi'] as num?)?.toDouble();

    final category =
        plan['category']?.toString() ??
            'Normal';

    final createdAt =
        plan['created_at']?.toString();

    final planJson =
        Map<String, dynamic>.from(
      plan['plan_json'] ?? {},
    );

    final summary =
        planJson['summary']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(
              alpha: 0.10,
            ),
            AppColors.surface,
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              AppColors.primary.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your wellness plan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your latest saved plan',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _planInfo(
                  'BMI',
                  bmi?.toStringAsFixed(1) ??
                      '--',
                  Icons
                      .monitor_weight_outlined,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _planInfo(
                  'Category',
                  category,
                  Icons.favorite_outline_rounded,
                  valueColor:
                      _categoryColor(category),
                ),
              ),
            ],
          ),

          if (createdAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Created ${_formatDate(createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],

          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              summary,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openSavedPlan,
              icon: const Icon(
                Icons.visibility_outlined,
              ),
              label: const Text(
                'View Latest Plan',
              ),
              style:
                  ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openDietPlan,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Create New Plan',
              ),
              style:
                  OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      AppColors.accent.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No wellness plan yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create your first personalized plan.',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openDietPlan,
              icon: const Icon(
                Icons.auto_awesome_rounded,
              ),
              label: const Text(
                'Create Wellness Plan',
              ),
              style:
                  ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planInfo(
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: AppColors.primary,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color: valueColor ??
                        AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BMI CARD
  // ------------------------------------------------------------

  Widget _buildBmiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.primary.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      Colors.white.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              const Text(
                'Your BMI',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_loadingBmi)
            const SizedBox(
              height: 50,
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Text(
              _latestBmi != null
                  ? _latestBmi!
                      .toStringAsFixed(1)
                  : '--',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 4),

          Text(
            _latestCategory ??
                'No data yet',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openCalculator,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    AppColors.primary,
                minimumSize:
                    const Size(
                  double.infinity,
                  52,
                ),
              ),
              child: Text(
                _latestBmi == null
                    ? 'Calculate BMI'
                    : 'Recalculate BMI',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION CARD
// ============================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                    AppColors.accent.withValues(
                  alpha: 0.15,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}