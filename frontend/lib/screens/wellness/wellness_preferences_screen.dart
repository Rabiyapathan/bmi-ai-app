import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/wellness_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/wellness/preference_option_card.dart';
import '../../widgets/wellness/preference_progress.dart';
import 'diet_plan_screen.dart';

class WellnessPreferencesScreen extends StatefulWidget {
  final double bmi;
  final String category;

  const WellnessPreferencesScreen({
    super.key,
    required this.bmi,
    required this.category,
  });

  @override
  State<WellnessPreferencesScreen> createState() =>
      _WellnessPreferencesScreenState();
}

class _WellnessPreferencesScreenState
    extends State<WellnessPreferencesScreen> {
  static const int _totalSteps = 9;

  // Flask backend running locally.
  static const String _backendUrl = 'http://127.0.0.1:5000';

  int _currentStep = 0;
  bool _isGeneratingPlan = false;

  String? _goal;
  String? _activityLevel;
  String? _countryRegion;
  String? _foodPreference;
  String? _dietType;

  final List<String> _allergies = [];
  final List<String> _dislikedFoods = [];

  String? _mealPreference;
  String? _yogaPreference;

  final TextEditingController _countryController =
      TextEditingController();

  final TextEditingController _foodPreferenceController =
      TextEditingController();

  final List<String> _countryOptions = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Ivory Coast',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
    'Other',
  ];

  final List<String> _foodPreferenceOptions = [
    'Mostly homemade food',
    'Indian cuisine',
    'Mediterranean cuisine',
    'East Asian cuisine',
    'Middle Eastern cuisine',
    'Western cuisine',
    'African cuisine',
    'Latin American cuisine',
    'Mixed / variety of cuisines',
    'Other',
  ];

  final List<String> _allergyOptions = [
    'None',
    'Dairy',
    'Nuts',
    'Eggs',
    'Gluten',
    'Soy',
  ];

  final List<String> _foodOptions = [
    'None',
    'Milk',
    'Eggs',
    'Fish',
    'Chicken',
    'Rice',
    'Oats',
    'Paneer',
  ];

  final List<String> _mealOptions = [
    '3 meals',
    '4 meals',
    '5–6 smaller meals',
  ];

  final List<String> _yogaOptions = [
    'No yoga',
    'Beginner',
    'Regular',
  ];

  @override
  void dispose() {
    _countryController.dispose();
    _foodPreferenceController.dispose();
    super.dispose();
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'What is your main goal?';
      case 1:
        return 'How active are you?';
      case 2:
        return 'Where are you from?';
      case 3:
        return 'What kind of food do you usually eat?';
      case 4:
        return 'What type of diet do you follow?';
      case 5:
        return 'Any food allergies?';
      case 6:
        return 'Anything you dislike?';
      case 7:
        return 'How do you prefer to eat?';
      case 8:
        return 'Would you like yoga?';
      default:
        return 'Your preferences';
    }
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 0:
        return 'We’ll use this to shape your wellness plan.';
      case 1:
        return 'This helps us suggest realistic activities.';
      case 2:
        return 'Your region helps us suggest familiar and realistic foods.';
      case 3:
        return 'Tell us about the cuisine or food you normally eat.';
      case 4:
        return 'Choose the eating style that fits you.';
      case 5:
        return 'We’ll avoid these foods in your suggestions.';
      case 6:
        return 'Tell us which foods you would rather avoid.';
      case 7:
        return 'Choose the meal pattern you prefer.';
      case 8:
        return 'We’ll include suitable yoga suggestions.';
      default:
        return '';
    }
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _goal != null;

      case 1:
        return _activityLevel != null;

      case 2:
        if (_countryRegion == null) {
          return false;
        }

        if (_countryRegion == 'Other') {
          return _isSensibleText(_countryController.text);
        }

        return true;

      case 3:
        if (_foodPreference == null) {
          return false;
        }

        if (_foodPreference == 'Other') {
          return _isSensibleText(
            _foodPreferenceController.text,
          );
        }

        return true;

      case 4:
        return _dietType != null;

      case 5:
        return _allergies.isNotEmpty;

      case 6:
        return _dislikedFoods.isNotEmpty;

      case 7:
        return _mealPreference != null;

      case 8:
        return _yogaPreference != null;

      default:
        return false;
    }
  }

  bool _isSensibleText(String value) {
    final text = value.trim().toLowerCase();

    if (text.length < 3) {
      return false;
    }

    final obviousRubbish = {
      'asdf',
      'asdfgh',
      'asdfghjkl',
      'qwerty',
      'qwertyuiop',
      'test',
      'testing',
      'xyz',
      'aaaa',
      'bbbb',
      '123',
      '1234',
      'none',
    };

    if (obviousRubbish.contains(text)) {
      return false;
    }

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasVowel = RegExp(r'[aeiou]').hasMatch(text);

    if (!hasLetter || !hasVowel) {
      return false;
    }

    final repeatedCharacter =
        RegExp(r'^(.)\1+$').hasMatch(text);

    if (repeatedCharacter) {
      return false;
    }

    return true;
  }

  void _nextStep() {
    if (!_canContinue || _isGeneratingPlan) {
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _createPlan();
    }
  }

  void _previousStep() {
    if (_isGeneratingPlan) {
      return;
    }

    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  Future<void> _createPlan() async {
    if (!_canContinue || _isGeneratingPlan) {
      return;
    }

    final preferences = WellnessPreferences(
      goal: _goal!,
      activityLevel: _activityLevel!,
      countryRegion: _countryRegion!,
      customCountryRegion: _countryRegion == 'Other'
          ? _countryController.text.trim()
          : '',
      foodPreference: _foodPreference!,
      customFoodPreference: _foodPreference == 'Other'
          ? _foodPreferenceController.text.trim()
          : '',
      dietType: _dietType!,
      allergies: List<String>.from(_allergies),
      dislikedFoods: List<String>.from(_dislikedFoods),
      mealPreference: _mealPreference!,
      yogaPreference: _yogaPreference!,
    );

    setState(() {
      _isGeneratingPlan = true;
    });

    try {
      // ----------------------------------------------------------
      // 1. PREPARE REQUEST
      // ----------------------------------------------------------

      final payload = {
        'bmi': widget.bmi,
        'category': widget.category,
        ...preferences.toJson(),
      };

      debugPrint('Sending wellness plan request...');

      // ----------------------------------------------------------
      // 2. ASK FLASK / GROQ TO GENERATE PLAN
      // ----------------------------------------------------------

      final response = await http
          .post(
            Uri.parse('$_backendUrl/diet-plan'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 60),
          );

      debugPrint(
        'Diet API status: ${response.statusCode}',
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode != 200) {
        String errorMessage =
            'Unable to generate your wellness plan.';

        try {
          final errorData = jsonDecode(response.body);

          if (errorData is Map<String, dynamic> &&
              errorData['error'] != null) {
            errorMessage =
                errorData['error'].toString();
          }
        } catch (_) {
          // Keep default error message.
        }

        throw Exception(errorMessage);
      }

      // ----------------------------------------------------------
      // 3. PARSE GENERATED PLAN
      // ----------------------------------------------------------

      final responseData = jsonDecode(response.body);

      if (responseData is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response received from the server.',
        );
      }

      if (responseData['success'] != true) {
        throw Exception(
          responseData['error']?.toString() ??
              'Unable to generate your wellness plan.',
        );
      }

      final plan = responseData['plan'];

      if (plan is! Map<String, dynamic>) {
        throw Exception(
          'The server returned an invalid wellness plan.',
        );
      }

      debugPrint('Wellness plan generated successfully.');

      // ----------------------------------------------------------
      // 4. CHECK SUPABASE LOGIN
      // ----------------------------------------------------------

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      debugPrint(
        'Supabase user: ${user?.id}',
      );

      if (user == null) {
        throw Exception(
          'No logged-in user found. Please log in again.',
        );
      }

      // ----------------------------------------------------------
      // 5. SAVE PLAN TO SUPABASE
      // ----------------------------------------------------------

      debugPrint(
        'Saving wellness plan to Supabase...',
      );

      final savedPlan = await supabase
          .from('wellness_plans')
          .insert({
            'user_id': user.id,
            'bmi': widget.bmi,
            'category': widget.category,
            'preferences': preferences.toJson(),
            'plan_json': plan,
          })
          .select('id')
          .single();

      // ----------------------------------------------------------
      // 6. VERIFY SUPABASE ACTUALLY RETURNED A ROW
      // ----------------------------------------------------------

      final savedPlanId = savedPlan['id'];

      debugPrint(
        'Wellness plan saved successfully. ID: $savedPlanId',
      );

      if (savedPlanId == null) {
        throw Exception(
          'Supabase did not return a saved plan ID.',
        );
      }

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // 7. ONLY NOW OPEN DIET PLAN SCREEN
      // ----------------------------------------------------------

      setState(() {
        _isGeneratingPlan = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DietPlanScreen(
            bmi: widget.bmi,
            category: widget.category,
            preferences: preferences,
            plan: plan,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGeneratingPlan = false;
      });

      debugPrint(
        'WELLNESS PLAN ERROR: $error',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save your plan:\n'
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed:
              _isGeneratingPlan ? null : _previousStep,
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const Text(
          'Personalize Your Plan',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              PreferenceProgress(
                currentStep: _currentStep + 1,
                totalSteps: _totalSteps,
              ),

              const SizedBox(height: 28),

              Text(
                _stepTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _stepSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: AnimatedSwitcher(
                  duration:
                      const Duration(milliseconds: 300),
                  transitionBuilder:
                      (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                          begin:
                              const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStep(),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_canContinue &&
                              !_isGeneratingPlan)
                          ? _nextStep
                          : null,
                  child: _isGeneratingPlan
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _currentStep ==
                                  _totalSteps - 1
                              ? 'Create My Wellness Plan'
                              : 'Continue',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildGoalStep();
      case 1:
        return _buildActivityStep();
      case 2:
        return _buildCountryStep();
      case 3:
        return _buildFoodPreferenceStep();
      case 4:
        return _buildDietStep();
      case 5:
        return _buildAllergyStep();
      case 6:
        return _buildDislikedFoodStep();
      case 7:
        return _buildMealStep();
      case 8:
        return _buildYogaStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalStep() {
    return ListView(
      key: const ValueKey('goal'),
      children: [
        _option(
          'Maintain my current health',
          'Balanced nutrition and healthy habits',
          Icons.balance_rounded,
          _goal == 'maintenance',
          () => setState(
            () => _goal = 'maintenance',
          ),
        ),
        _option(
          'Gain weight healthily',
          'Nourishing meals and gradual progress',
          Icons.trending_up_rounded,
          _goal == 'healthy_weight_gain',
          () => setState(
            () => _goal = 'healthy_weight_gain',
          ),
        ),
        _option(
          'Manage my weight',
          'Balanced food choices and regular movement',
          Icons.monitor_weight_outlined,
          _goal == 'weight_management',
          () => setState(
            () => _goal = 'weight_management',
          ),
        ),
        _option(
          'Improve overall wellness',
          'Nutrition, movement and daily habits',
          Icons.favorite_border_rounded,
          _goal == 'overall_wellness',
          () => setState(
            () => _goal = 'overall_wellness',
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStep() {
    return ListView(
      key: const ValueKey('activity'),
      children: [
        _option(
          'Mostly sedentary',
          'Mostly sitting or little daily movement',
          Icons.event_seat_outlined,
          _activityLevel == 'sedentary',
          () => setState(
            () => _activityLevel = 'sedentary',
          ),
        ),
        _option(
          'Lightly active',
          'Some walking or light activity',
          Icons.directions_walk_rounded,
          _activityLevel == 'light',
          () => setState(
            () => _activityLevel = 'light',
          ),
        ),
        _option(
          'Moderately active',
          'Regular exercise or active lifestyle',
          Icons.directions_run_rounded,
          _activityLevel == 'moderate',
          () => setState(
            () => _activityLevel = 'moderate',
          ),
        ),
        _option(
          'Very active',
          'Frequent or intensive physical activity',
          Icons.fitness_center_rounded,
          _activityLevel == 'very_active',
          () => setState(
            () => _activityLevel = 'very_active',
          ),
        ),
      ],
    );
  }

  Widget _buildCountryStep() {
    return ListView(
      key: const ValueKey('country'),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _countryRegion,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Country / Region',
            hintText:
                'Select your country or region',
            prefixIcon:
                const Icon(Icons.public_rounded),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
          ),
          items: _countryOptions.map((country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(country),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _countryRegion = value;

              if (value != 'Other') {
                _countryController.clear();
              }
            });
          },
        ),

        if (_countryRegion == 'Other') ...[
          const SizedBox(height: 18),
          _buildCustomTextField(
            controller: _countryController,
            label:
                'Enter your country or region',
            hint: 'Example: Caribbean region',
            icon:
                Icons.edit_location_alt_outlined,
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enter a meaningful country or region.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFoodPreferenceStep() {
    return ListView(
      key: const ValueKey('food_preference'),
      children: [
        ..._foodPreferenceOptions.map((option) {
          return _option(
            option,
            _foodPreferenceSubtitle(option),
            _foodPreferenceIcon(option),
            _foodPreference == option,
            () {
              setState(() {
                _foodPreference = option;

                if (option != 'Other') {
                  _foodPreferenceController.clear();
                }
              });
            },
          );
        }),

        if (_foodPreference == 'Other') ...[
          const SizedBox(height: 4),
          _buildCustomTextField(
            controller:
                _foodPreferenceController,
            label:
                'Describe your usual food',
            hint:
                'Example: homemade Maharashtrian food',
            icon: Icons.edit_note_rounded,
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us what you normally eat so the AI can make the plan more relevant to you.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  String _foodPreferenceSubtitle(
    String option,
  ) {
    switch (option) {
      case 'Mostly homemade food':
        return 'Simple meals prepared at home';

      case 'Indian cuisine':
        return 'Indian foods and familiar ingredients';

      case 'Mediterranean cuisine':
        return 'Mediterranean-style foods and ingredients';

      case 'East Asian cuisine':
        return 'Foods commonly found in East Asian cuisines';

      case 'Middle Eastern cuisine':
        return 'Foods commonly found in Middle Eastern cuisines';

      case 'Western cuisine':
        return 'Foods commonly found in Western cuisines';

      case 'African cuisine':
        return 'Foods commonly found across African cuisines';

      case 'Latin American cuisine':
        return 'Foods commonly found across Latin American cuisines';

      case 'Mixed / variety of cuisines':
        return 'A mixture of different cuisines';

      case 'Other':
        return 'Describe what you usually eat';

      default:
        return '';
    }
  }

  IconData _foodPreferenceIcon(
    String option,
  ) {
    switch (option) {
      case 'Mostly homemade food':
        return Icons.home_rounded;

      case 'Indian cuisine':
        return Icons.rice_bowl_rounded;

      case 'Mediterranean cuisine':
        return Icons.local_dining_rounded;

      case 'East Asian cuisine':
        return Icons.ramen_dining_rounded;

      case 'Middle Eastern cuisine':
        return Icons.restaurant_rounded;

      case 'Western cuisine':
        return Icons.lunch_dining_rounded;

      case 'African cuisine':
        return Icons.public_rounded;

      case 'Latin American cuisine':
        return Icons.fastfood_rounded;

      case 'Mixed / variety of cuisines':
        return Icons.auto_awesome_rounded;

      case 'Other':
        return Icons.edit_rounded;

      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization:
          TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDietStep() {
    return ListView(
      key: const ValueKey('diet'),
      children: [
        _option(
          'Vegetarian',
          'No meat or fish',
          Icons.eco_outlined,
          _dietType == 'vegetarian',
          () => setState(
            () => _dietType = 'vegetarian',
          ),
        ),
        _option(
          'Non-vegetarian',
          'Includes meat, fish or eggs',
          Icons.restaurant_rounded,
          _dietType == 'non_vegetarian',
          () => setState(
            () => _dietType = 'non_vegetarian',
          ),
        ),
        _option(
          'Vegan',
          'Plant-based foods only',
          Icons.spa_outlined,
          _dietType == 'vegan',
          () => setState(
            () => _dietType = 'vegan',
          ),
        ),
        _option(
          'Other',
          'A different eating pattern',
          Icons.more_horiz_rounded,
          _dietType == 'other',
          () => setState(
            () => _dietType = 'other',
          ),
        ),
      ],
    );
  }

  Widget _buildAllergyStep() {
    return _buildMultiSelectList(
      key: const ValueKey('allergies'),
      options: _allergyOptions,
      selected: _allergies,
    );
  }

  Widget _buildDislikedFoodStep() {
    return _buildMultiSelectList(
      key: const ValueKey('disliked'),
      options: _foodOptions,
      selected: _dislikedFoods,
    );
  }

  Widget _buildMultiSelectList({
    required Key key,
    required List<String> options,
    required List<String> selected,
  }) {
    return ListView(
      key: key,
      children: options.map((option) {
        final isSelected =
            selected.contains(option);

        return _option(
          option,
          option == 'None'
              ? 'No foods to avoid'
              : 'Exclude this from suggestions',
          option == 'None'
              ? Icons.check_circle_outline_rounded
              : Icons.no_food_outlined,
          isSelected,
          () {
            setState(() {
              if (option == 'None') {
                selected
                  ..clear()
                  ..add('None');
              } else {
                selected.remove('None');

                if (isSelected) {
                  selected.remove(option);
                } else {
                  selected.add(option);
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMealStep() {
    return ListView(
      key: const ValueKey('meals'),
      children: _mealOptions.map((option) {
        return _option(
          option,
          option == '3 meals'
              ? 'Breakfast, lunch and dinner'
              : option == '4 meals'
                  ? 'Three meals plus one snack'
                  : 'Smaller meals spread through the day',
          Icons.restaurant_menu_rounded,
          _mealPreference == option,
          () => setState(
            () => _mealPreference = option,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYogaStep() {
    return ListView(
      key: const ValueKey('yoga'),
      children: _yogaOptions.map((option) {
        return _option(
          option,
          option == 'No yoga'
              ? 'Focus on other forms of movement'
              : option == 'Beginner'
                  ? 'Gentle yoga and simple poses'
                  : 'More consistent yoga practice',
          option == 'No yoga'
              ? Icons.block_rounded
              : option == 'Beginner'
                  ? Icons.self_improvement_rounded
                  : Icons.spa_rounded,
          _yogaPreference == option,
          () => setState(
            () => _yogaPreference = option,
          ),
        );
      }).toList(),
    );
  }

  Widget _option(
    String title,
    String subtitle,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return PreferenceOptionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      selected: selected,
      onTap: onTap,
    );
  }
}