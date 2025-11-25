import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Profile Screen
/// Displays user profile information, statistics, and settings
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(SolarIconsOutline.menuDots),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Profile Header
            _buildProfileHeader(context, colorScheme),
            
            const SizedBox(height: 24),
            
            // Statistics Cards
            _buildStatisticsRow(context, colorScheme),
            
            const SizedBox(height: 24),
            
            // Settings Options
            _buildSettingsSection(context, colorScheme),
            
            const SizedBox(height: 16),
            
            // Log Out Button
            _buildLogOutButton(context, colorScheme),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // Profile Picture with Edit Button
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 3,
                ),
              ),
              child: Icon(
                SolarIconsBold.user,
                size: 60,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 3,
                  ),
                ),
                child: Icon(
                  SolarIconsBold.pen,
                  size: 16,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // User Name
        Text(
          'Alex Taylor',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Join Date
        Text(
          'Joined March 2025',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatisticsRow(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              colorScheme,
              '128',
              'Workouts',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              colorScheme,
              '15',
              'Streak',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              colorScheme,
              '5',
              'Awards',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    ColorScheme colorScheme,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            colorScheme,
            icon: SolarIconsBold.user,
            iconColor: colorScheme.primary,
            title: 'Personal Information',
            onTap: () {
              // Navigate to personal information screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonalInformationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            colorScheme,
            icon: SolarIconsBold.bell,
            iconColor: colorScheme.secondary,
            title: 'Notifications',
            onTap: () {
              // Navigate to notifications settings
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            colorScheme,
            icon: SolarIconsBold.shieldKeyhole,
            iconColor: Colors.orange,
            title: 'Security',
            onTap: () {
              // Navigate to security settings
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecurityScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            colorScheme,
            icon: SolarIconsBold.questionCircle,
            iconColor: Colors.green,
            title: 'Help & Support',
            onTap: () {
              // Navigate to help & support
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTile(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                SolarIconsOutline.altArrowRight,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogOutButton(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            // Show confirmation dialog
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Log Out'),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            );
            
            if (confirm == true && context.mounted) {
              // TODO: Implement actual sign out logic
              // await AuthService.signOut();
              
              // Navigate to welcome screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                (route) => false,
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Log Out',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Example template screens for the settings options


/// Personal Information Screen Template
class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            context,
            colorScheme,
            icon: SolarIconsBold.user,
            label: 'Full Name',
            value: 'Alex Taylor',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            colorScheme,
            icon: SolarIconsBold.letter,
            label: 'Email',
            value: 'alex.taylor@example.com',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            colorScheme,
            icon: SolarIconsBold.phone,
            label: 'Phone',
            value: '+1 (555) 123-4567',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            colorScheme,
            icon: SolarIconsBold.calendar,
            label: 'Date of Birth',
            value: 'January 15, 1990',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            colorScheme,
            icon: Icons.straighten,
            label: 'Height',
            value: '175 cm',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            colorScheme,
            icon: Icons.monitor_weight,
            label: 'Weight',
            value: '70 kg',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement edit functionality
            },
            child: const Text('Edit Information'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications Screen Template
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _workoutReminders = true;
  bool _heartRateAlerts = true;
  bool _sleepReminders = false;
  bool _nutritionReminders = true;
  bool _achievementNotifications = true;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Manage your notification preferences',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildNotificationTile(
            context,
            colorScheme,
            icon: SolarIconsBold.dumbbell,
            title: 'Workout Reminders',
            subtitle: 'Get reminded to stay active',
            value: _workoutReminders,
            onChanged: (value) {
              setState(() => _workoutReminders = value);
            },
          ),
          const SizedBox(height: 12),
          
          _buildNotificationTile(
            context,
            colorScheme,
            icon: SolarIconsBold.heartPulse,
            title: 'Heart Rate Alerts',
            subtitle: 'Alerts for abnormal heart rate',
            value: _heartRateAlerts,
            onChanged: (value) {
              setState(() => _heartRateAlerts = value);
            },
          ),
          const SizedBox(height: 12),
          
          _buildNotificationTile(
            context,
            colorScheme,
            icon: SolarIconsBold.moon,
            title: 'Sleep Reminders',
            subtitle: 'Bedtime and wake-up reminders',
            value: _sleepReminders,
            onChanged: (value) {
              setState(() => _sleepReminders = value);
            },
          ),
          const SizedBox(height: 12),
          
          _buildNotificationTile(
            context,
            colorScheme,
            icon: SolarIconsBold.cup,
            title: 'Nutrition Reminders',
            subtitle: 'Meal and water intake reminders',
            value: _nutritionReminders,
            onChanged: (value) {
              setState(() => _nutritionReminders = value);
            },
          ),
          const SizedBox(height: 12),
          
          _buildNotificationTile(
            context,
            colorScheme,
            icon: Icons.emoji_events,
            title: 'Achievement Notifications',
            subtitle: 'Celebrate your milestones',
            value: _achievementNotifications,
            onChanged: (value) {
              setState(() => _achievementNotifications = value);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationTile(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Security Screen Template
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Manage your account security',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSecurityOption(
            context,
            colorScheme,
            icon: SolarIconsBold.lock,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              // TODO: Navigate to change password screen
            },
          ),
          const SizedBox(height: 12),
          
          _buildSecurityOption(
            context,
            colorScheme,
            icon: SolarIconsBold.shieldCheck,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            onTap: () {
              // TODO: Navigate to 2FA setup
            },
          ),
          const SizedBox(height: 12),
          
          _buildSecurityOption(
            context,
            colorScheme,
            icon: Icons.devices,
            title: 'Connected Devices',
            subtitle: 'Manage devices linked to your account',
            onTap: () {
              // TODO: Navigate to connected devices
            },
          ),
          const SizedBox(height: 12),
          
          _buildSecurityOption(
            context,
            colorScheme,
            icon: SolarIconsBold.history,
            title: 'Login History',
            subtitle: 'View your recent login activity',
            onTap: () {
              // TODO: Navigate to login history
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityOption(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                SolarIconsOutline.altArrowRight,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Help & Support Screen Template
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'We\'re here to help',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildHelpOption(
            context,
            colorScheme,
            icon: SolarIconsBold.book,
            title: 'User Guide',
            subtitle: 'Learn how to use FlowFit',
            onTap: () {
              // TODO: Open user guide
            },
          ),
          const SizedBox(height: 12),
          
          _buildHelpOption(
            context,
            colorScheme,
            icon: SolarIconsBold.questionCircle,
            title: 'FAQs',
            subtitle: 'Frequently asked questions',
            onTap: () {
              // TODO: Open FAQs
            },
          ),
          const SizedBox(height: 12),
          
          _buildHelpOption(
            context,
            colorScheme,
            icon: SolarIconsBold.chatRound,
            title: 'Contact Support',
            subtitle: 'Get help from our team',
            onTap: () {
              // TODO: Open contact support
            },
          ),
          const SizedBox(height: 12),
          
          _buildHelpOption(
            context,
            colorScheme,
            icon: SolarIconsBold.documentText,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            onTap: () {
              // TODO: Open terms of service
            },
          ),
          const SizedBox(height: 12),
          
          _buildHelpOption(
            context,
            colorScheme,
            icon: SolarIconsBold.shieldKeyhole,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          const SizedBox(height: 24),
          
          // App Version
          Center(
            child: Column(
              children: [
                Text(
                  'FlowFit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpOption(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                SolarIconsOutline.altArrowRight,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
