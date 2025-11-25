import 'package:flutter/material.dart';

/// Example: How to add Profile navigation to your existing screens
/// 
/// Add this to your AppBar actions in any screen:
/// 
/// ```dart
/// AppBar(
///   title: const Text('Your Screen'),
///   actions: [
///     IconButton(
///       icon: const Icon(Icons.person),
///       onPressed: () {
///         Navigator.pushNamed(context, '/profile');
///       },
///     ),
///   ],
/// )
/// ```
/// 
/// Or add it to a bottom navigation bar:
/// 
/// ```dart
/// BottomNavigationBar(
///   items: const [
///     BottomNavigationBarItem(
///       icon: Icon(Icons.home),
///       label: 'Home',
///     ),
///     BottomNavigationBarItem(
///       icon: Icon(Icons.bar_chart),
///       label: 'Stats',
///     ),
///     BottomNavigationBarItem(
///       icon: Icon(Icons.person),
///       label: 'Profile',
///     ),
///   ],
///   onTap: (index) {
///     if (index == 2) {
///       Navigator.pushNamed(context, '/profile');
///     }
///   },
/// )
/// ```

class ExampleHomeWithProfile extends StatefulWidget {
  const ExampleHomeWithProfile({super.key});

  @override
  State<ExampleHomeWithProfile> createState() => _ExampleHomeWithProfileState();
}

class _ExampleHomeWithProfileState extends State<ExampleHomeWithProfile> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowFit'),
        actions: [
          // Quick access to profile from AppBar
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to FlowFit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person),
              label: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          // Navigate based on selection
          switch (index) {
            case 0:
              // Home - already here
              break;
            case 1:
              // Stats/Dashboard
              Navigator.pushNamed(context, '/dashboard');
              break;
            case 2:
              // Profile
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
