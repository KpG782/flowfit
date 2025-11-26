import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';

class SurveyActivityGoalsScreen extends StatefulWidget {
  const SurveyActivityGoalsScreen({super.key});

  @override
  State<SurveyActivityGoalsScreen> createState() => _SurveyActivityGoalsScreenState();
}

class _SurveyActivityGoalsScreenState extends State<SurveyActivityGoalsScreen> {
  String? _selectedActivityLevel;
  String? _selectedGoal;

  final List<Map<String, dynamic>> _activityLevels = [
    {
      'id': 'sedentary',
      'title': 'Sedentary',
      'icon': SolarIconsBold.smartphone,
      'description': 'Desk job, little exercise',
      'multiplier': '1.2×',
    },
    {
      'id': 'moderate',
      'title': 'Moderately Active',
      'icon': SolarIconsBold.bicycling,
      'description': 'Exercise 3-5 times/week',
      'multiplier': '1.55×',
    },
    {
      'id': 'very_active',
      'title': 'Very Active',
      'icon': SolarIconsBold.dumbbellSmall,
      'description': 'Daily intense exercise',
      'multiplier': '1.725×',
    },
  ];

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'lose_weight',
      'title': 'Lose Weight',
      'icon': SolarIconsBold.fire,
      'description': 'Safe deficit: -500 cal/day',
      'color': Colors.orange,
    },
    {
      'id': 'maintain',
      'title': 'Maintain Weight',
      'icon': SolarIconsBold.scale,
      'description': 'Stay at current weight',
      'color': Colors.green,
    },
    {
      'id': 'build_muscle',
      'title': 'Build Muscle',
      'icon': SolarIconsBold.dumbbellSmall,
      'description': 'Surplus: +300 cal/day',
      'color': Colors.purple,
    },
    {
      'id': 'improve_cardio',
      'title': 'Improve Cardio',
      'icon': SolarIconsBold.heartPulse,
      'description': 'Focus on heart health',
      'color': Colors.red,
    },
  ];

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
          'Activity & Goals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '3/4',
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Activity Level Section
              const Row(
                children: [
                  Icon(SolarIconsBold.running, color: AppTheme.primaryBlue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Current Activity Level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ..._activityLevels.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActivityCard(level),
              )),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 32),
              
              // Goals Section
              const Row(
                children: [
                  Icon(SolarIconsBold.target, color: AppTheme.primaryBlue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Primary Fitness Goal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ..._goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGoalCard(goal),
              )),
              
              const SizedBox(height: 48),
              
              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/survey_daily_targets');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE →',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Back and Skip
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
                      'Skip this screen',
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

  Widget _buildActivityCard(Map<String, dynamic> level) {
    final isSelected = _selectedActivityLevel == level['id'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = level['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Icon(
              level['icon'],
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(${level['multiplier']} multiplier)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final isSelected = _selectedGoal == goal['id'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = goal['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? goal['color'].withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? goal['color'] : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? goal['color'] : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Icon(
              goal['icon'],
              color: isSelected ? goal['color'] : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? goal['color'] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
