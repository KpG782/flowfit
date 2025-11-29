import 'package:flutter/material.dart';

// Home Screen - Kid-friendly design with Buddy pet companion
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.lightBlue[200]!, // Sky blue
              Colors.blue[300]!,      // Ocean blue
              Colors.blue[400]!,      // Deeper ocean
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with greeting and pet
              SizedBox(
                height: 320,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Sun
                    Positioned(
                      top: 60,
                      right: 40,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.orange[300],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Clouds
                    Positioned(
                      top: 80,
                      left: 60,
                      child: _buildCloud(30),
                    ),
                    Positioned(
                      top: 100,
                      left: 150,
                      child: _buildCloud(25),
                    ),
                    
                    // Greeting text
                    Positioned(
                      top: 80,
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          Text(
                            _getGreeting(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Potato! 👋',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Pet Buddy in center
                    Positioned(
                      top: 180,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            // Show pet interaction dialog
                            _showPetInteractionDialog(context);
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.blue[800],
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.pets,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Wave decorations
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.elliptical(100, 20),
                            topRight: Radius.elliptical(100, 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress Section
              ColoredBox(
                color: Colors.blue[100]!,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  children: [
                    // Adventure Progress
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fitness Adventure Level 1',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 0.2, // 3/15 progress
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '3 / 15',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Goals left indicator
                    Row(
                      children: [
                        Icon(Icons.flag, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '4 more goals to complete today!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.waves, color: Colors.blue[400]),
                        const SizedBox(width: 8),
                        Icon(Icons.grid_view, color: Colors.blue[400]),
                      ],
                    ),
                  ],
                  ),
                ),
              ),

              // Goals Section
              ColoredBox(
                color: Colors.blue[100]!,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Morning Goals Section
                    Row(
                      children: [
                        Text(
                          'Start the day',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            _showAddGoalDialog(context, 'morning');
                          },
                          icon: Icon(Icons.add_circle, color: Colors.blue[600], size: 28),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Goal Cards
                    _buildGoalCard(
                      context,
                      Icons.wb_sunny,
                      'Get out of bed',
                      5,
                      true,
                    ),
                    const SizedBox(height: 12),
                    _buildGoalCard(
                      context,
                      Icons.clean_hands,
                      'Brush teeth',
                      5,
                      true,
                    ),
                    const SizedBox(height: 12),
                    _buildGoalCard(
                      context,
                      Icons.face,
                      'Wash my face',
                      5,
                      true,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Any time section
                    Row(
                      children: [
                        Text(
                          'Any time',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            _showAddGoalDialog(context, 'anytime');
                          },
                          icon: Icon(Icons.add_circle, color: Colors.blue[600], size: 28),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildGoalCard(
                      context,
                      Icons.water_drop,
                      'Drink water',
                      5,
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildGoalCard(
                      context,
                      Icons.accessibility_new,
                      'Take a stretch break',
                      5,
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildGoalCard(
                      context,
                      Icons.sentiment_very_satisfied,
                      'Do one thing that makes me happy',
                      5,
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildGoalCard(
                      context,
                      Icons.air,
                      'Take 3 deep breaths',
                      5,
                      false,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Add goal button
                    GestureDetector(
                      onTap: () {
                        _showAddGoalDialog(context, 'custom');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[200]?.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Add a goal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloud(double size) {
    return Container(
      width: size * 2,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    IconData icon,
    String title,
    int points,
    bool isCompleted,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        _toggleGoalCompletion(context, title, isCompleted);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Drag handle
            Icon(
              Icons.drag_indicator,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: isCompleted ? Colors.green[600] : Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Title
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.grey[600] : Colors.grey[800],
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            
            // Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$points',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.bolt,
                    color: Colors.orange[700],
                    size: 16,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Checkmark
            GestureDetector(
              onTap: () {
                _toggleGoalCompletion(context, title, isCompleted);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check,
                  color: isCompleted ? Colors.white : Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKidStatCard(
    BuildContext context,
    String label,
    String value,
    String emoji,
    Color color,
    String encouragement,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            encouragement,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKidActivityCard(
    BuildContext context,
    String title,
    String subtitle,
    String emoji,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKidActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    String time,
    String emoji,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
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
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPetInteractionDialog(BuildContext context) {
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
              const Text('Your Pet Buddy'),
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
                'Hi there! I\'m your wellness buddy. Complete your daily goals to help me grow stronger!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context, String category) {
    final TextEditingController goalController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Add ${category == 'morning' ? 'Morning' : category == 'anytime' ? 'Anytime' : 'Custom'} Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: goalController,
                decoration: const InputDecoration(
                  hintText: 'Enter your goal...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your new goal will be added to your daily routine!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (goalController.text.isNotEmpty) {
                  // Here you would typically save the goal to your state management
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal "${goalController.text}" added!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Goal'),
            ),
          ],
        );
      },
    );
  }

  void _toggleGoalCompletion(BuildContext context, String goalTitle, bool currentStatus) {
    // Here you would typically update your state management
    final newStatus = !currentStatus;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus 
            ? 'Great job! "$goalTitle" completed! 🎉' 
            : '"$goalTitle" marked as incomplete',
        ),
        backgroundColor: newStatus ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
