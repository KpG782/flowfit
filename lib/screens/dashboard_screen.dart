import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/providers.dart';
import 'home/home_screen.dart';
import 'quests/quests_screen.dart';
import 'play/play_screen.dart';
import 'rewards/rewards_screen.dart';
import 'potato/potato_screen.dart';
// Keep tab imports for future use
// ignore: unused_import
import 'dashboard/home_tab.dart';
// ignore: unused_import
import 'dashboard/health_tab.dart';
// ignore: unused_import
import 'dashboard/track_tab.dart';
// ignore: unused_import
import 'dashboard/progress_tab.dart';
// ignore: unused_import
import 'dashboard/profile_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QuestsScreen(), // Fitness challenges and daily quests
    const PlayScreen(),   // Activities and workouts (renamed from Track)
    const RewardsScreen(), // Achievements and rewards (renamed from Progress)
    const PotatoScreen(),  // User profile with pet buddy (renamed from Profile)
  ];

  @override
  void initState() {
    super.initState();
    // Check auth state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
      _checkInitialTab();
    });
  }

  void _checkInitialTab() {
    // Check if we should navigate to a specific tab
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialTab = args?['initialTab'] as int?;

    if (initialTab != null && initialTab >= 0 && initialTab < _screens.length) {
      setState(() {
        _currentIndex = initialTab;
      });
    }
  }

  void _checkAuthState() {
    final authState = ref.read(authNotifierProvider);

    // If not authenticated, redirect to welcome screen
    if (authState.user == null) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Listen for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      // If user logs out, redirect to welcome
      if (next.user == null && mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    });

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[50]!,
              Colors.purple[50]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.orange[600],
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          selectedFontSize: 13,
          unselectedFontSize: 11,
          iconSize: 32,
          elevation: 0, // We handle elevation with Container shadow
          items: [
            BottomNavigationBarItem(
              icon: _buildStickerIcon(
                Icons.home_rounded,
                Colors.orange,
                _currentIndex == 0,
              ),
              label: 'Home',
              tooltip: 'Home - Daily Goals',
            ),
            BottomNavigationBarItem(
              icon: _buildStickerIcon(
                Icons.assignment_rounded,
                Colors.blue,
                _currentIndex == 1,
              ),
              label: 'Quests',
              tooltip: 'Fitness Quests & Challenges',
            ),
            BottomNavigationBarItem(
              icon: _buildStickerIcon(
                Icons.sports_gymnastics_rounded,
                Colors.green,
                _currentIndex == 2,
              ),
              label: 'Play',
              tooltip: 'Activities & Workouts',
            ),
            BottomNavigationBarItem(
              icon: _buildStickerIcon(
                Icons.emoji_events_rounded,
                Colors.purple,
                _currentIndex == 3,
              ),
              label: 'Rewards',
              tooltip: 'Achievements & Rewards',
            ),
            BottomNavigationBarItem(
              icon: _buildStickerIcon(
                Icons.pets, // Changed to pet icon for kid-friendly feel
                Colors.pink,
                _currentIndex == 4,
              ),
              label: 'Buddy', // Changed from 'Potato' to 'Buddy' - will be dynamic later
              tooltip: 'Your Profile & Pet Buddy',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerIcon(IconData icon, MaterialColor color, bool isSelected) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isSelected ? color[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white,
          width: 4, // Thick white border like sticker style
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? color[600] : color[400],
        ),
      ),
    );
  }
}
