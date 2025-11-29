import 'package:flutter/material.dart';

class PotatoScreen extends StatelessWidget {
  const PotatoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink[200]!,
              Colors.orange[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink[300]!,
                              Colors.orange[300]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_circle_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, Buddy! 👋', // Using Buddy as the pet name for now
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[800],
                              ),
                            ),
                            Text(
                              'Level 3 Fitness Explorer',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.pink[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.7, // 70% to next level
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.pink[400]!,
                                        Colors.orange[400]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '70% to Level 4',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Pet Buddy Section
                Text(
                  'Your Pet Buddy',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[800],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[100]!,
                        Colors.cyan[100]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      // Pet Avatar - Sticker style
                      GestureDetector(
                        onTap: () {
                          _showPetInteraction(context);
                        },
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan[300]!,
                                Colors.blue[400]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(65),
                            border: Border.all(color: Colors.white, width: 6), // Thick white border
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '🐋', // Kid-friendly whale emoji
                              style: TextStyle(fontSize: 70),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Buddy the Whale',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      
                      Text(
                        'Happy and Energetic',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[600],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Pet Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPetStat(
                            context,
                            'Happiness',
                            '85%',
                            Icons.sentiment_very_satisfied,
                            Colors.green,
                          ),
                          _buildPetStat(
                            context,
                            'Energy',
                            '92%',
                            Icons.bolt,
                            Colors.orange,
                          ),
                          _buildPetStat(
                            context,
                            'Health',
                            '78%',
                            Icons.favorite,
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats Overview
                Text(
                  'Your Stats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[800],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Goals\nCompleted',
                        '47',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Active\nDays',
                        '12',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total\nPoints',
                        '1,247',
                        Icons.bolt,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Badges\nEarned',
                        '8',
                        Icons.emoji_events,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Settings & Actions
                Text(
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[800],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildSettingsItem(
                  context,
                  'Notifications',
                  'Manage your reminders',
                  Icons.notifications,
                  Colors.blue,
                ),
                
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  'Goals & Preferences',
                  'Customize your fitness goals',
                  Icons.tune,
                  Colors.green,
                ),
                
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  'Family & Friends',
                  'Connect with family members',
                  Icons.family_restroom,
                  Colors.purple,
                ),
                
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  'Help & Support',
                  'Get help when you need it',
                  Icons.help,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _handleSettingsTap(context, title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showPetInteraction(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.pets, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Buddy says...'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.pets,
                  size: 40,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Great job today, Potato! You\'re doing amazing with your fitness goals. Keep up the awesome work! 🌟',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Thanks, Buddy!'),
            ),
          ],
        );
      },
    );
  }

  void _handleSettingsTap(BuildContext context, String settingName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $settingName...'),
        backgroundColor: Colors.pink[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}