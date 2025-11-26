import 'dart:math';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';

class SurveyBodyMeasurementsScreen extends StatefulWidget {
  const SurveyBodyMeasurementsScreen({super.key});

  @override
  State<SurveyBodyMeasurementsScreen> createState() => _SurveyBodyMeasurementsScreenState();
}

class _SurveyBodyMeasurementsScreenState extends State<SurveyBodyMeasurementsScreen> {
  String _unitSystem = 'imperial';
  
  // Imperial
  int _heightFeet = 5;
  int _heightInches = 9;
  double _weightLbs = 165;
  
  // Metric
  double _heightCm = 175;
  double _weightKg = 75;

  double get _displayHeightCm {
    if (_unitSystem == 'metric') {
      return _heightCm;
    } else {
      return (_heightFeet * 30.48) + (_heightInches * 2.54);
    }
  }

  double get _displayWeightKg {
    if (_unitSystem == 'metric') {
      return _weightKg;
    } else {
      return _weightLbs * 0.453592;
    }
  }

  double get _bmi {
    final heightM = _displayHeightCm / 100;
    return _displayWeightKg / (heightM * heightM);
  }

  String get _bmiStatus {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25) return 'Healthy ✓';
    if (_bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return Colors.red;
  }

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
          'Body Measurements',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '2/4',
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
                        color: Colors.grey[300],
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
              
              // Title
              const Row(
                children: [
                  Icon(SolarIconsBold.ruler, color: AppTheme.primaryBlue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Your measurements',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Unit System Toggle
              Text(
                'Units:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildUnitButton('Metric', 'metric'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUnitButton('Imperial', 'imperial'),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Height
              Row(
                children: [
                  const Icon(SolarIconsBold.ruler, size: 20, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Height',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (_unitSystem == 'imperial') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Feet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _heightFeet,
                                isExpanded: true,
                                items: List.generate(5, (i) => i + 3).map((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text('$value ft'),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() => _heightFeet = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inches',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _heightInches,
                                isExpanded: true,
                                items: List.generate(12, (i) => i).map((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text('$value in'),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() => _heightInches = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '= ${_displayHeightCm.toStringAsFixed(0)} cm ($_heightFeet\'$_heightInches")',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Slider(
                  value: _heightCm,
                  min: 120,
                  max: 220,
                  divisions: 100,
                  activeColor: AppTheme.primaryBlue,
                  label: '${_heightCm.toStringAsFixed(0)} cm',
                  onChanged: (value) {
                    setState(() => _heightCm = value);
                  },
                ),
                Text(
                  '${_heightCm.toStringAsFixed(0)} cm',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // Weight
              Row(
                children: [
                  const Icon(SolarIconsBold.scale, size: 20, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Current Weight',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (_unitSystem == 'imperial') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_weightLbs > 50) _weightLbs -= 1;
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove, size: 20),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '${_weightLbs.toStringAsFixed(0)} lbs',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_weightLbs < 400) _weightLbs += 1;
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 20, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _weightLbs,
                  min: 50,
                  max: 400,
                  divisions: 350,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (value) {
                    setState(() => _weightLbs = value);
                  },
                ),
                Text(
                  '= ${_displayWeightKg.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_weightKg > 30) _weightKg -= 0.5;
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove, size: 20),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '${_weightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_weightKg < 200) _weightKg += 0.5;
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 20, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _weightKg,
                  min: 30,
                  max: 200,
                  divisions: 340,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (value) {
                    setState(() => _weightKg = value);
                  },
                ),
              ],
              
              const SizedBox(height: 32),
              
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 24),
              
              // BMI Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _bmiColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _bmiColor.withOpacity(0.3), width: 2),
                ),
                child: Row(
                  children: [
                    Icon(SolarIconsBold.chartSquare, color: _bmiColor, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your BMI: ${_bmi.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _bmiColor,
                            ),
                          ),
                          Text(
                            _bmiStatus,
                            style: TextStyle(
                              fontSize: 14,
                              color: _bmiColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(SolarIconsBold.infoCircle, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Used to calculate personalized calorie burn during activities',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/survey_activity_goals');
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

  Widget _buildUnitButton(String label, String value) {
    final isSelected = _unitSystem == value;
    
    return GestureDetector(
      onTap: () => setState(() => _unitSystem = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
