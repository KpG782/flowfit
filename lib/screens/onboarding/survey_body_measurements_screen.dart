import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';

class SurveyBodyMeasurementsScreen extends ConsumerStatefulWidget {
  const SurveyBodyMeasurementsScreen({super.key});

  @override
  ConsumerState<SurveyBodyMeasurementsScreen> createState() =>
      _SurveyBodyMeasurementsScreenState();
}

class _SurveyBodyMeasurementsScreenState
    extends ConsumerState<SurveyBodyMeasurementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing data if available
    final surveyState = ref.read(surveyNotifierProvider);
    final weight = surveyState.surveyData['weight'];
    if (weight != null) {
      _weightController.text = weight.toString();
    }
    final height = surveyState.surveyData['height'];
    if (height != null) {
      _heightController.text = height.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      // Save data to survey notifier
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      await surveyNotifier.updateSurveyData(
        'weight',
        double.parse(_weightController.text),
      );
      await surveyNotifier.updateSurveyData(
        'height',
        double.parse(_heightController.text),
      );

      // Validate using the notifier's validation method
      final validationError = surveyNotifier.validateBodyMeasurements();
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Navigate to next screen
      if (mounted) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        Navigator.pushReplacementNamed(
          context,
          '/survey_activity_goals',
          arguments: args,
        );
      }
    }
  }

  void _handleBack() {
    Navigator.pop(context);
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
          onPressed: _handleBack,
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
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
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
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Row(
                        children: [
                          Icon(SolarIconsBold.scale, color: AppTheme.primaryBlue, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Your body measurements',
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
                        'Help us calculate your daily targets',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 32),
                      
                      Divider(color: Colors.grey[300], thickness: 1),

                      const SizedBox(height: 24),

                      // Weight Field
                      const Text(
                        'Weight (kg)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your weight in kg',
                          prefixIcon: Icon(SolarIconsBold.scale),
                          suffixText: 'kg',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Weight is required';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null) {
                            return 'Please enter a valid number';
                          }
                          if (weight <= 0 || weight >= 500) {
                            return 'Weight must be between 0 and 500 kg';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Height Field
                      const Text(
                        'Height (cm)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your height in cm',
                          prefixIcon: Icon(SolarIconsBold.ruler),
                          suffixText: 'cm',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Height is required';
                          }
                          final height = double.tryParse(value);
                          if (height == null) {
                            return 'Please enter a valid number';
                          }
                          if (height <= 0 || height >= 300) {
                            return 'Height must be between 0 and 300 cm';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              SolarIconsBold.infoCircle,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'We use this to calculate your BMI and personalized calorie targets',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
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

            // Next Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleNext,
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
            ),
          ],
        ),
      ),
    );
  }

}
