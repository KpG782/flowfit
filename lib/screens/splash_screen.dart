import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../presentation/providers/providers.dart';
import '../domain/entities/auth_state.dart';

/// Splash screen shown while checking authentication state.
/// 
/// Requirements: 5.1 - Check auth state on app start
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait a moment for UI to render
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    // Initialize auth state (check for existing session)
    await authNotifier.initialize();

    if (!mounted) return;

    final updatedAuthState = ref.read(authNotifierProvider);

    if (updatedAuthState.status == AuthStatus.authenticated && updatedAuthState.user != null) {
      // User is authenticated, check if profile is complete
      final profileRepository = ref.read(profileRepositoryProvider);
      
      try {
        final hasCompletedSurvey = await profileRepository.hasCompletedSurvey(
          updatedAuthState.user!.id,
        );

        if (!mounted) return;

        if (hasCompletedSurvey) {
          // Profile complete, go to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Profile incomplete, go to survey
          Navigator.pushReplacementNamed(
            context,
            '/survey_intro',
            arguments: {'userId': updatedAuthState.user!.id},
          );
        }
      } catch (e) {
        // Error checking profile, assume incomplete and go to survey
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/survey_intro',
            arguments: {'userId': updatedAuthState.user!.id},
          );
        }
      }
    } else {
      // Not authenticated, go to welcome screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App name
            const Text(
              'FlowFit',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}
