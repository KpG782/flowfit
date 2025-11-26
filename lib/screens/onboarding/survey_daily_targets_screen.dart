import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';

class SurveyDailyTargetsScreen extends StatefulWidget {
  const SurveyDailyTargetsScreen({super.key});

  @override
  State<SurveyDailyTargetsScreen> createState() => _SurveyDailyTargetsScreenState();
}

class _SurveyDailyTargetsScreenState extends State<SurveyDailyTargetsScreen> {
  int _targetCalories = 2450;
  int _targetSteps = 10000;
  int _targetActiveMinutes = 30;
  double _targetWaterLiters = 2.0;

  final List<int> _stepsOptions = [5000, 10000, 12000, 15000];
  final List<int> _minutesOptions = [20, 30, 45, 60];
  final List<double> _waterOptions = [1.5, 2.0, 2.5, 3.0];

  @override
  Widget build(BuildContext context) {
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
                      'Based on: 27M, 175cm, 75kg',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Moderately active • Goal: Maintain weight',
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
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
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
              
              const SizedBox(height: 16),
              
              // Back and Use Defaults
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '← Back',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    child: Text(
                      'Use these defaults',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
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
