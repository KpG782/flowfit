import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';

class SurveyIntroScreen extends StatelessWidget {
  const SurveyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  SolarIconsBold.heartPulse,
                  size: 100,
                  color: AppTheme.primaryBlue,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Title
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, color: AppTheme.primaryBlue, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Quick Setup',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '(2 Minutes)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Description
              Text(
                'Let\'s personalize FlowFit for you!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Features
              _buildFeature(
                icon: SolarIconsBold.fire,
                text: 'Daily calorie target',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildFeature(
                icon: SolarIconsBold.heartPulse,
                text: 'Heart rate zones',
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              _buildFeature(
                icon: SolarIconsBold.target,
                text: 'Personalized goals',
                color: AppTheme.primaryBlue,
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Just 4 quick questions!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              // Start Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/survey_basic_info');
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
                    'LET\'S PERSONALIZE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Skip Button
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: Text(
                  'I\'ll do this later →',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              Text(
                '(You can always skip and use smart defaults)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeature({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
