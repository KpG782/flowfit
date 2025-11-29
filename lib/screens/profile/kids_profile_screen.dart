import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../presentation/providers/providers.dart';
import '../../core/domain/entities/user_profile.dart';
import '../../models/buddy_profile.dart';
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
              : _buildKidsProfileContent(context, profile, userId),
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
  ) {
    // Mock Buddy profile
    final buddyProfile = BuddyProfile(
      id: 'buddy-1',
      userId: userId,
      name: profile.nickname ?? 'Buddy',
      color: 'blue',
      level: 5,
      xp: 350,
      unlockedColors: ['blue', 'teal', 'green'],
      accessories: {
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

    // Calculate happiness and health from level and xp
    final happiness = 80;
    final health = 90;

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
              onCustomizeTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '���',
                    'Happy',
                    '${buddyProfile.happiness}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '⚡',
                    'Energy',
                    '${buddyProfile.health}%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Wellness Goals Section (from onboarding)
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
            () => Navigator.pushNamed(context, '/buddy-customization'),
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
}
