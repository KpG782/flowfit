import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

class WearDashboard extends StatefulWidget {
  final WearShape shape;
  final WearMode mode;

  const WearDashboard({
    super.key,
    required this.shape,
    required this.mode,
  });

  @override
  State<WearDashboard> createState() => _WearDashboardState();
}

class _WearDashboardState extends State<WearDashboard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  StreamSubscription<RotaryEvent>? _rotarySubscription;

  @override
  void initState() {
    super.initState();
    // Listen to rotary input (rotating bezel on Galaxy Watch)
    try {
      _rotarySubscription = rotaryEvents.listen(_handleRotaryEvent);
    } catch (e) {
      // Rotary not available on this device
      debugPrint('Rotary input not available: $e');
    }
  }

  @override
  void dispose() {
    _rotarySubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleRotaryEvent(RotaryEvent event) {
    // Navigate pages using rotating bezel
    if (event.direction == RotaryDirection.clockwise) {
      if (_currentPage < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      if (_currentPage > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAmbient = widget.mode == WearMode.ambient;
    final isRound = widget.shape == WearShape.round;

    return WillPopScope(
      onWillPop: () async {
        // Handle back gesture (swipe from left)
        if (_currentPage > 0) {
          // Go to previous page instead of exiting
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false; // Don't exit app
        }
        return true; // Exit app if on first page
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildHomePage(isAmbient, isRound),
                _buildHeartRatePage(isAmbient, isRound),
                _buildStepsPage(isAmbient, isRound),
                _buildWorkoutPage(isAmbient, isRound),
              ],
            ),
            // Page indicator (only in active mode)
            if (!isAmbient)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: _buildPageIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentPage == index ? 8 : 6,
          height: _currentPage == index ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildHomePage(bool isAmbient, bool isRound) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isRound ? 8 : 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: isAmbient ? 28 : 40,
              color: isAmbient ? Colors.white : Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              'FlowFit',
              style: TextStyle(
                fontSize: isAmbient ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (!isAmbient) ...[
              Text(
                'Swipe or rotate',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildQuickStats(),
            ] else ...[
              Text(
                'Active',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRatePage(bool isAmbient, bool isRound) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isRound ? 8 : 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: isAmbient ? 28 : 40,
              color: isAmbient ? Colors.white : Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              '72',
              style: TextStyle(
                fontSize: isAmbient ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'BPM',
              style: TextStyle(
                fontSize: isAmbient ? 10 : 12,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (!isAmbient) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Start heart rate measurement
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Measure', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepsPage(bool isAmbient, bool isRound) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isRound ? 8 : 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: isAmbient ? 28 : 40,
              color: isAmbient ? Colors.white : Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              '5,432',
              style: TextStyle(
                fontSize: isAmbient ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Steps',
              style: TextStyle(
                fontSize: isAmbient ? 10 : 12,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (!isAmbient) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: 0.54,
                  backgroundColor: Colors.grey[800],
                  color: Colors.green,
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Goal: 10,000',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPage(bool isAmbient, bool isRound) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isRound ? 8 : 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              size: isAmbient ? 28 : 40,
              color: isAmbient ? Colors.white : Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              'Workout',
              style: TextStyle(
                fontSize: isAmbient ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isAmbient) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Start workout tracking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Start', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Last: 25 min',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(Icons.favorite, '72', 'BPM'),
        _buildStatItem(Icons.directions_walk, '5.4K', 'Steps'),
        _buildStatItem(Icons.local_fire_department, '320', 'Cal'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
