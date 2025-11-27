import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import 'dart:math';

class SurveyDailyTargetsScreen extends ConsumerStatefulWidget {
  const SurveyDailyTargetsScreen({super.key});

  @override
  ConsumerState<SurveyDailyTargetsScreen> createState() => _SurveyDailyTargetsScreenState();
}

class _SurveyDailyTargetsScreenState extends ConsumerState<SurveyDailyTargetsScreen> {
  int _targetCalories = 2450;
  int _targetSteps = 10000;
  int _targetActiveMinutes = 30;
  double _targetWaterLiters = 2.0;
  bool _isSubmitting = false;

  final List<int> _stepsOptions = [5000, 10000, 12000, 15000];
  final List<int> _minutesOptions = [20, 30, 45, 60];
  final List<double> _waterOptions = [1.5, 2.0, 2.5, 3.0];

  @override
  void initState() {
    super.initState();
    _calculateCalorieTarget();
  }

  void _calculateCalorieTarget() {
    final surveyState = ref.read(surveyNotifierProvider);
    final surveyData = surveyState.surveyData;

    // Get user data
    final age = surveyData['age'] as int? ?? 25;
    final gender = surveyData['gender'] as String? ?? 'male';
    final weight = surveyData['weight'] as double? ?? 70.0;
    final height = surveyData['height'] as double? ?? 170.0;
    final activityLevel = surveyData['activityLevel'] as String? ?? 'moderately_active';
    final goals = surveyData['goals'] as List<dynamic>? ?? [];

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Apply activity multiplier
    double activityMultiplier;
    switch (activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'lightly_active':
        activityMultiplier = 1.375;
        break;
      case 'moderately_active':
        activityMultiplier = 1.55;
        break;
      case 'very_active':
        activityMultiplier = 1.725;
        break;
      case 'extremely_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    double tdee = bmr * activityMultiplier;

    // Adjust based on primary goal
    if (goals.contains('lose_weight')) {
      tdee -= 500; // Safe deficit
    } else if (goals.contains('build_muscle')) {
      tdee += 300; // Surplus
    }

    setState(() {
      _targetCalories = tdee.round();
    });

    // Save to survey data
    ref.read(surveyNotifierProvider.notifier).updateSurveyData('dailyCalorieTarget', _targetCalories);
  }

  Future<void> _handleComplete() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save daily targets to survey data
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      await surveyNotifier.updateSurveyData('dailyCalorieTarget', _targetCalories);
      await surveyNotifier.updateSurveyData('dailyStepsTarget', _targetSteps);
      await surveyNotifier.updateSurveyData('dailyActiveMinutesTarget', _targetActiveMinutes);
      await surveyNotifier.updateSurveyData('dailyWaterTarget', _targetWaterLiters);

      // Get user ID from arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as String?;

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Submit survey to backend
      final success = await surveyNotifier.submitSurvey(userId);

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to dashboard
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        });
      } else {
        // Show error
        final errorMessage = ref.read(surveyNotifierProvider).errorMessage ?? 'Failed to save profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getActivityLevelDisplay() {
    final surveyData = ref.read(surveyNotifierProvider).surveyData;
    final activityLevel = surveyData['activityLevel'] as String? ?? 'moderately_active';
    
    switch (activityLevel) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly active';
      case 'moderately_active':
        return 'Moderately active';
      case 'very_active':
        return 'Very active';
      case 'extremely_active':
        return 'Extremely active';
      default:
        return 'Moderately active';
    }
  }

  String _getGoalsDisplay() {
    final surveyData = ref.read(surveyNotifierProvider).surveyData;
    final goals = surveyData['goals'] as List<dynamic>? ?? [];
    
    if (goals.isEmpty) return 'No goals selected';
    
    final goalNames = goals.map((goal) {
      switch (goal) {
        case 'lose_weight':
          return 'Lose weight';
        case 'maintain_weight':
          return 'Maintain weight';
        case 'build_muscle':
          return 'Build muscle';
        case 'improve_cardio':
          return 'Improve cardio';
        default:
          return goal.toString();
      }
    }).toList();
    
    return goalNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final surveyData = ref.watch(surveyNotifierProvider).surveyData;
    final age = surveyData['age'] as int? ?? 0;
    final gender = surveyData['gender'] as String? ?? 'male';
    final height = surveyData['height'] as double? ?? 0.0;
    final weight = surveyData['weight'] as double? ?? 0.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Daily Targets',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '4/4',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Row(
                children: [
                  Icon(SolarIconsBold.target, color: AppTheme.primaryBlue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Personalized Goals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Based on your profile, here are your recommended daily targets:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Calorie Target
              Row(
                children: [
                  const Icon(SolarIconsBold.fire, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Calorie Target',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_targetCalories calories',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on: ${age}${gender == 'male' ? 'M' : gender == 'female' ? 'F' : ''}, ${height.toStringAsFixed(0)}cm, ${weight.toStringAsFixed(0)}kg',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${_getActivityLevelDisplay()} • Goals: ${_getGoalsDisplay()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        _showCalorieAdjustDialog();
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Adjust'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Steps Target
              Row(
                children: [
                  const Icon(SolarIconsBold.walking, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Steps Target',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildProgressBar(_targetSteps / 15000, Colors.green),
              
              const SizedBox(height: 12),
              
              Text(
                '${_targetSteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} steps/day',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _stepsOptions.map((steps) {
                  return _buildQuickSelectChip(
                    label: '${(steps / 1000).toStringAsFixed(0)}K',
                    isSelected: _targetSteps == steps,
                    onTap: () => setState(() => _targetSteps = steps),
                    color: Colors.green,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Active Minutes Target
              Row(
                children: [
                  const Icon(SolarIconsBold.clockCircle, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Active Minutes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildProgressBar(_targetActiveMinutes / 60, Colors.purple),
              
              const SizedBox(height: 12),
              
              Text(
                '$_targetActiveMinutes minutes/day',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _minutesOptions.map((minutes) {
                  return _buildQuickSelectChip(
                    label: '$minutes',
                    isSelected: _targetActiveMinutes == minutes,
                    onTap: () => setState(() => _targetActiveMinutes = minutes),
                    color: Colors.purple,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Water Intake Target
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Water Intake',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildProgressBar(_targetWaterLiters / 3, Colors.blue),
              
              const SizedBox(height: 12),
              
              Text(
                '${_targetWaterLiters.toStringAsFixed(1)} liters/day',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _waterOptions.map((liters) {
                  return _buildQuickSelectChip(
                    label: '${liters}L',
                    isSelected: _targetWaterLiters == liters,
                    onTap: () => setState(() => _targetWaterLiters = liters),
                    color: Colors.blue,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Info
              Row(
                children: [
                  Icon(SolarIconsBold.infoCircle, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can adjust these anytime in your profile settings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 3 ? AppTheme.primaryBlue : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Complete Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'COMPLETE & START APP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _showCalorieAdjustDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempCalories = _targetCalories;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adjust Calorie Target'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tempCalories calories',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempCalories.toDouble(),
                    min: 1200,
                    max: 4000,
                    divisions: 56,
                    activeColor: Colors.orange,
                    label: '$tempCalories',
                    onChanged: (value) {
                      setDialogState(() {
                        tempCalories = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _targetCalories = tempCalories;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
