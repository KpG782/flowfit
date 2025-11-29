import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/buddy_onboarding_provider.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/onboarding_button.dart';

/// Wellness Goal Selection Screen - Step 6 of 8
///
/// Multi-select goal cards inspired by whale companion pattern.
/// Kids select areas they want support with.
///
/// Goals:
/// - Boost focus and productivity
/// - Stay fresh and clean
/// - Be more active
/// - Manage stress and anxiety
/// - Strengthen social skills
class GoalSelectionScreen extends ConsumerWidget {
  const GoalSelectionScreen({super.key});

  static const List<WellnessGoal> predefinedGoals = [
    WellnessGoal(
      id: 'focus',
      title: 'Boost focus and productivity',
      icon: '🎯',
    ),
    WellnessGoal(id: 'hygiene', title: 'Stay fresh and clean', icon: '🪥'),
    WellnessGoal(id: 'active', title: 'Be more active', icon: '👟'),
    WellnessGoal(id: 'stress', title: 'Manage stress and anxiety', icon: '🏔️'),
    WellnessGoal(id: 'social', title: 'Strengthen social skills', icon: '☎️'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(buddyOnboardingProvider);
    final selectedGoals = state.selectedGoals;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator: ●●●○ (step 6 of 8)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  8,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= 5
                          ? const Color(0xFF4ECDC4)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Buddy with lightbulb (thinking pose)
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BuddyCharacterWidget(
                      color: const Color(0xFF4ECDC4),
                      size: 100,
                    ),
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Text('💡', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'What areas would you like support with?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF314158),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Select as many as you like',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF7F8C8D),
                ),
              ),

              const SizedBox(height: 32),

              // Goal cards
              Expanded(
                child: ListView.separated(
                  itemCount: predefinedGoals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = predefinedGoals[index];
                    final isSelected = selectedGoals.contains(goal.id);

                    return GoalCard(
                      goal: goal,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(buddyOnboardingProvider.notifier)
                            .toggleGoal(goal.id);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Next button (always enabled)
              OnboardingButton(
                label: 'NEXT',
                onPressed: () {
                  Navigator.pushNamed(context, '/notification-permission');
                },
                customColor: const Color(0xFF66BB6A),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wellness Goal model
class WellnessGoal {
  final String id;
  final String title;
  final String icon;

  const WellnessGoal({
    required this.id,
    required this.title,
    required this.icon,
  });
}

/// Goal Card widget
class GoalCard extends StatelessWidget {
  final WellnessGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF66BB6A).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji icon
            Text(goal.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                goal.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF314158),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Check/Plus icon
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
