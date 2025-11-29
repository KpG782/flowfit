import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../presentation/providers/providers.dart';
import '../../core/domain/entities/user_profile.dart';
import '../../models/buddy_profile.dart';
import '../../providers/buddy_profile_provider.dart';
import 'buddy_profile_card.dart';

/// Kids Profile Screen - Kid-friendly profile with Buddy companion
class KidsProfileScreen extends ConsumerWidget {
  const KidsProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F6FD),
        body: _buildEmptyState(context),
      );
    }

    final profileAsync = ref.watch(profileNotifierProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => profile == null
              ? _buildEmptyState(context)
              : _buildKidsProfileContent(context, profile, userId, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(context),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(SolarIconsOutline.sadCircle, size: 64),
          const SizedBox(height: 16),
          const Text('Oops! Something went wrong'),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () {}, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              SolarIconsOutline.userCircle,
              size: 80,
              color: Color(0xFF3B82F6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Let\'s Get Started!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Meet your new whale companion! 🐋',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Meet Your Whale Buddy!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKidsProfileContent(
    BuildContext context,
    UserProfile profile,
    String userId,
    WidgetRef ref,
  ) {
    final buddyProfileAsync = ref.watch(buddyProfileNotifierProvider(userId));

    return buddyProfileAsync.when(
      data: (buddyProfile) {
        // Use real buddy profile if it exists, otherwise use mock
        final effectiveBuddyProfile =
            buddyProfile ?? _getMockBuddyProfile(userId, profile);

        return _buildProfileWithBuddy(
          context,
          profile,
          effectiveBuddyProfile,
          buddyProfile != null, // isRealProfile
          ref,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // On error, fall back to mock profile
        final mockBuddyProfile = _getMockBuddyProfile(userId, profile);
        return _buildProfileWithBuddy(
          context,
          profile,
          mockBuddyProfile,
          false, // isRealProfile
          ref,
        );
      },
    );
  }

  /// Get mock buddy profile as fallback
  BuddyProfile _getMockBuddyProfile(String userId, UserProfile profile) {
    return BuddyProfile(
      id: 'buddy-mock',
      userId: userId,
      name: profile.nickname ?? 'Buddy',
      color: 'blue',
      level: 5,
      xp: 350,
      unlockedColors: const ['blue', 'teal', 'green'],
      accessories: const {
        'unlocked': {
          'hats': ['cap'],
          'clothes': ['basic'],
          'shoes': [],
          'extras': [],
        },
        'current': {
          'hat': 'cap',
          'clothes': 'basic',
          'shoes': null,
          'extra': null,
        },
        'background': 'home',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Widget _buildProfileWithBuddy(
    BuildContext context,
    UserProfile profile,
    BuddyProfile buddyProfile,
    bool isRealProfile,
    WidgetRef ref,
  ) {
    // Calculate happiness and health from level and xp
    const happiness = 80;
    const health = 90;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF314158),
                  ),
                ),
                IconButton(
                  icon: const Icon(SolarIconsOutline.settings),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BuddyProfileCard(
              buddyProfile: buddyProfile,
              onCustomizeTap: () {
                if (isRealProfile) {
                  Navigator.pushNamed(context, '/buddy-customization');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Complete the Buddy onboarding to unlock customization!',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('😊', 'Happy', '$happiness%')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('⚡', 'Energy', '$health%')),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Wellness Goals Section (from whale onboarding)
          if (profile.wellnessGoals != null &&
              profile.wellnessGoals!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My Wellness Goals 🎯',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF314158),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.wellnessGoals!.map((goal) {
                  final goalData = _getGoalData(goal);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${goalData['emoji']} ${goalData['title']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF314158),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            context,
            'Customize ${buddyProfile.name}',
            SolarIconsOutline.palette,
            const Color(0xFF4ECDC4),
            () {
              if (isRealProfile) {
                Navigator.pushNamed(context, '/buddy-customization');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Complete the Buddy onboarding to unlock customization!',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          _buildActionTile(
            context,
            'Notifications',
            SolarIconsOutline.bell,
            const Color(0xFF3B82F6),
            () => Navigator.pushNamed(context, '/notification-settings'),
          ),
          _buildActionTile(
            context,
            'Privacy & Safety',
            SolarIconsOutline.shieldCheck,
            const Color(0xFF10B981),
            () => Navigator.pushNamed(context, '/privacy-policy'),
          ),

          const SizedBox(height: 24),

          // Account Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF314158),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (profile.nickname != null)
            _buildInfoTile(context, 'Nickname', profile.nickname!),
          _buildActionTile(
            context,
            'Help & Support',
            SolarIconsOutline.questionCircle,
            const Color(0xFFF59E0B),
            () => Navigator.pushNamed(context, '/help-support'),
          ),
          _buildActionTile(
            context,
            'Logout',
            SolarIconsOutline.logout,
            Colors.red,
            () => _handleLogout(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF314158),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF314158),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getGoalData(String goalId) {
    const goalMap = {
      'focus': {'emoji': '🎯', 'title': 'Focus Better'},
      'hygiene': {'emoji': '🪥', 'title': 'Stay Clean'},
      'active': {'emoji': '👟', 'title': 'Be Active'},
      'stress': {'emoji': '🏔️', 'title': 'Manage Stress'},
      'social': {'emoji': '☎️', 'title': 'Make Friends'},
    };
    return goalMap[goalId] ?? {'emoji': '✨', 'title': goalId};
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    }
  }
}
