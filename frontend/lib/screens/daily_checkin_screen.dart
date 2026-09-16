import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  bool _breakfast = false;
  bool _lunch = false;
  bool _snack = false;
  bool _dinner = false;
  bool _water = false;
  bool _activity = false;

  int get _completedCount {
    return [
      _breakfast,
      _lunch,
      _snack,
      _dinner,
      _water,
      _activity,
    ].where((value) => value).length;
  }

  int get _completionPercentage {
    return ((_completedCount / 6) * 100).round();
  }

  @override
  void initState() {
    super.initState();
    _loadTodayCheckin();
  }

  Future<void> _loadTodayCheckin() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      final today = _todayString();

      final data = await _supabase
          .from('daily_checkins')
          .select()
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          _breakfast = data['breakfast_completed'] == true;
          _lunch = data['lunch_completed'] == true;
          _snack = data['snack_completed'] == true;
          _dinner = data['dinner_completed'] == true;
          _water = data['water_completed'] == true;
          _activity = data['activity_completed'] == true;
        });
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load daily check-in error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load today\'s progress: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveCheckin() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final today = _todayString();

      await _supabase.from('daily_checkins').upsert(
        {
          'user_id': user.id,
          'date': today,
          'breakfast_completed': _breakfast,
          'lunch_completed': _lunch,
          'snack_completed': _snack,
          'dinner_completed': _dinner,
          'water_completed': _water,
          'activity_completed': _activity,
          'completion_percentage': _completionPercentage,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,date',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _completionPercentage == 100
                ? 'Amazing! You completed everything today 🎉'
                : 'Today\'s progress has been saved 💗',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Save daily check-in error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save today\'s progress: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _todayString() {
    final now = DateTime.now();

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  void _toggleItem(
    String item,
    bool value,
  ) {
    setState(() {
      switch (item) {
        case 'breakfast':
          _breakfast = value;
          break;
        case 'lunch':
          _lunch = value;
          break;
        case 'snack':
          _snack = value;
          break;
        case 'dinner':
          _dinner = value;
          break;
        case 'water':
          _water = value;
          break;
        case 'activity':
          _activity = value;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Check-in',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressCard(),

                    const SizedBox(height: 28),

                    const Text(
                      'Today\'s habits',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Check off the healthy habits you completed today.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _CheckinCard(
                      icon: Icons.free_breakfast_rounded,
                      title: 'Breakfast',
                      subtitle: 'Did you have your breakfast?',
                      value: _breakfast,
                      onChanged: (value) {
                        _toggleItem('breakfast', value);
                      },
                    ),

                    _CheckinCard(
                      icon: Icons.lunch_dining_rounded,
                      title: 'Lunch',
                      subtitle: 'Did you have your lunch?',
                      value: _lunch,
                      onChanged: (value) {
                        _toggleItem('lunch', value);
                      },
                    ),

                    _CheckinCard(
                      icon: Icons.apple_rounded,
                      title: 'Evening snack',
                      subtitle: 'Did you have a planned snack?',
                      value: _snack,
                      onChanged: (value) {
                        _toggleItem('snack', value);
                      },
                    ),

                    _CheckinCard(
                      icon: Icons.restaurant_rounded,
                      title: 'Dinner',
                      subtitle: 'Did you have your dinner?',
                      value: _dinner,
                      onChanged: (value) {
                        _toggleItem('dinner', value);
                      },
                    ),

                    _CheckinCard(
                      icon: Icons.water_drop_rounded,
                      title: 'Water',
                      subtitle: 'Did you stay hydrated today?',
                      value: _water,
                      onChanged: (value) {
                        _toggleItem('water', value);
                      },
                    ),

                    _CheckinCard(
                      icon: Icons.self_improvement_rounded,
                      title: 'Yoga / activity',
                      subtitle: 'Did you complete your activity?',
                      value: _activity,
                      onChanged: (value) {
                        _toggleItem('activity', value);
                      },
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveCheckin,
                        icon: _saving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.save_rounded,
                              ),
                        label: Text(
                          _saving
                              ? 'Saving...'
                              : 'Save Today\'s Progress',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressCard() {
    final percentage = _completionPercentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Today\'s progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '$_completedCount of 6 completed',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            percentage == 100
                ? 'You did it! Keep the momentum going 🔥'
                : percentage == 0
                    ? 'Let\'s get started 💗'
                    : 'Every small habit counts.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckinCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Checkbox(
                value: value,
                onChanged: (checked) {
                  onChanged(checked ?? false);
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}