import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'random_workout_screen.dart';
import 'walk_screen.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Time to Move!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                  fontFamily: 'GeneralSans', // Assuming this font is available
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'What do you want to do today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF9098A3),
                ),
              ),
              
              const SizedBox(height: 40),

              // Flowy Character
              Expanded(
                flex: 2,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/flowy.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Options
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Random Workout Button
                    _buildActivityButton(
                      context,
                      title: 'Random Workout',
                      subtitle: 'Fun exercises with Flowy!',
                      icon: Icons.fitness_center,
                      color: const Color(0xFFFF6B6B), // Coral/Red
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RandomWorkoutScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // Take a Walk Button
                    _buildActivityButton(
                      context,
                      title: 'Take a Walk',
                      subtitle: 'Explore the outdoors',
                      icon: Icons.directions_walk,
                      color: const Color(0xFF4ECDC4), // Teal/Green
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalkScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
