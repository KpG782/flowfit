import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';

class SurveyBasicInfoScreen extends ConsumerStatefulWidget {
  const SurveyBasicInfoScreen({super.key});

  @override
  ConsumerState<SurveyBasicInfoScreen> createState() => _SurveyBasicInfoScreenState();
}

class _SurveyBasicInfoScreenState extends ConsumerState<SurveyBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String _userName = '';

  final List<Map<String, dynamic>> _genderOptions = [
    {'value': 'male', 'label': 'Male', 'icon': SolarIconsBold.user},
    {'value': 'female', 'label': 'Female', 'icon': SolarIconsBold.user},
    {'value': 'other', 'label': 'Other', 'icon': SolarIconsBold.user},
    {'value': 'prefer_not_to_say', 'label': 'Prefer not to say', 'icon': SolarIconsBold.user},
  ];

  @override
  void initState() {
    super.initState();
    // Get user name from arguments (passed from signup)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final name = args?['name'] as String?;
      if (name != null && name.isNotEmpty) {
        setState(() {
          _userName = name;
        });
        // Save to survey data
        ref.read(surveyNotifierProvider.notifier).updateSurveyData('fullName', name);
      }
    });
    
    // Load existing data if available
    final surveyState = ref.read(surveyNotifierProvider);
    final age = surveyState.surveyData['age'];
    if (age != null) {
      _ageController.text = age.toString();
    }
    _selectedGender = surveyState.surveyData['gender'] as String?;
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your gender'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save data to survey notifier
      final surveyNotifier = ref.read(surveyNotifierProvider.notifier);
      await surveyNotifier.updateSurveyData('age', int.parse(_ageController.text));
      await surveyNotifier.updateSurveyData('gender', _selectedGender);

      // Validate using the notifier's validation method
      final validationError = surveyNotifier.validateBasicInfo();
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
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        Navigator.pushReplacementNamed(
          context,
          '/survey_body_measurements',
          arguments: args,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Basic Info',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '1/4',
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
                      Row(
                        children: [
                          const Icon(SolarIconsBold.user, color: AppTheme.primaryBlue, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _userName.isNotEmpty ? 'Hi $_userName!' : 'Tell us about yourself',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Just a few quick questions to personalize your experience',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 32),
                      
                      Divider(color: Colors.grey[300], thickness: 1),

                      const SizedBox(height: 24),

                      // Age Field
                      const Text(
                        'Age',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your age',
                          prefixIcon: Icon(SolarIconsBold.calendar),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Age is required';
                          }
                          final age = int.tryParse(value);
                          if (age == null) {
                            return 'Please enter a valid number';
                          }
                          if (age < 13 || age > 120) {
                            return 'Age must be between 13 and 120';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Gender Selection
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._genderOptions.map((option) {
                        final isSelected = _selectedGender == option['value'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedGender = option['value'] as String;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue.withOpacity(0.1)
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    option['icon'] as IconData,
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    option['label'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primaryBlue,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
