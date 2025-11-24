import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/watch_bridge.dart';
import '../../models/heart_rate_data.dart';
import '../../models/sensor_status.dart';

/// Watch-side UI for Galaxy Watch 6
/// Displays live heart rate data being captured from the watch sensors
/// This runs on the watch itself and shows what the user sees on their wrist
class HeartRateWatchScreen extends StatefulWidget {
  const HeartRateWatchScreen({super.key});

  @override
  State<HeartRateWatchScreen> createState() => _HeartRateWatchScreenState();
}

class _HeartRateWatchScreenState extends State<HeartRateWatchScreen> {
  final WatchBridgeService _watchBridge = WatchBridgeService();
  
  StreamSubscription<HeartRateData>? _heartRateSubscription;
  HeartRateData? _currentHeartRate;
  bool _isTracking = false;
  
  // Animation controller for pulsing heart icon
  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _stopTracking();
    _watchBridge.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      final started = await _watchBridge.startHeartRateTracking();
      
      if (!started) return;

      _heartRateSubscription = _watchBridge.heartRateStream.listen(
        (heartRateData) {
          setState(() {
            _currentHeartRate = heartRateData;
            
            // Trigger pulse animation on new reading
            if (heartRateData.status == SensorStatus.active) {
              _triggerPulse();
            }
          });
        },
      );

      setState(() {
        _isTracking = true;
      });
    } catch (e) {
      // Handle error silently on watch
      debugPrint('Error starting tracking: $e');
    }
  }

  Future<void> _stopTracking() async {
    await _heartRateSubscription?.cancel();
    await _watchBridge.stopHeartRateTracking();
    setState(() {
      _isTracking = false;
    });
  }

  void _triggerPulse() {
    setState(() {
      _isPulsing = true;
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPulsing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing heart icon
            AnimatedScale(
              scale: _isPulsing ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Icon(
                Icons.favorite,
                size: 60,
                color: _isTracking ? Colors.red : Colors.grey,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Large BPM display
            Text(
              '${_currentHeartRate?.bpm ?? '--'}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // BPM label
            const Text(
              'BPM',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status indicator
            _buildStatusDot(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    final status = _currentHeartRate?.status ?? SensorStatus.inactive;
    
    Color dotColor;
    switch (status) {
      case SensorStatus.active:
        dotColor = Colors.green;
        break;
      case SensorStatus.inactive:
        dotColor = Colors.grey;
        break;
      case SensorStatus.error:
        dotColor = Colors.red;
        break;
      case SensorStatus.unavailable:
        dotColor = Colors.orange;
        break;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status == SensorStatus.active ? 'TRACKING' : 'INACTIVE',
          style: TextStyle(
            fontSize: 12,
            color: dotColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
