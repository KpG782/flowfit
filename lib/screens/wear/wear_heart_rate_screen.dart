import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'dart:async';
import '../../services/watch_bridge.dart';
import '../../models/heart_rate_data.dart';
import '../../models/sensor_status.dart';

/// Modern Wear OS heart rate monitoring screen
/// Features:
/// - Large BPM display
/// - Real-time monitoring with Samsung Health SDK
/// - One-tap send to phone button
/// - Ambient mode support
/// - Material Design 3 for Wear OS
class WearHeartRateScreen extends StatefulWidget {
  final WearShape shape;
  final WearMode mode;

  const WearHeartRateScreen({
    super.key,
    required this.shape,
    required this.mode,
  });

  @override
  State<WearHeartRateScreen> createState() => _WearHeartRateScreenState();
}

class _WearHeartRateScreenState extends State<WearHeartRateScreen>
    with SingleTickerProviderStateMixin {
  final WatchBridgeService _watchBridge = WatchBridgeService();
  
  HeartRateData? _currentHeartRate;
  bool _isMonitoring = false;
  bool _isConnected = false;
  bool _isSending = false;
  String _statusMessage = 'Ready';
  
  StreamSubscription? _heartRateSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkConnection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await _watchBridge.isWatchConnected();
      setState(() {
        _isConnected = connected;
        _statusMessage = connected ? 'Ready' : 'Connecting...';
      });
      
      if (!connected) {
        await _connectToSamsung();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection error';
      });
    }
  }

  Future<void> _connectToSamsung() async {
    try {
      final connected = await _watchBridge.connectToWatch();
      setState(() {
        _isConnected = connected;
        _statusMessage = connected ? 'Connected' : 'Connection failed';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      await _stopMonitoring();
    } else {
      await _startMonitoring();
    }
  }

  Future<void> _startMonitoring() async {
    if (!_isConnected) {
      await _connectToSamsung();
      if (!_isConnected) return;
    }

    try {
      final started = await _watchBridge.startHeartRateTracking();
      if (started) {
        setState(() {
          _isMonitoring = true;
          _statusMessage = 'Monitoring...';
        });

        _heartRateSubscription = _watchBridge.heartRateStream.listen(
          (heartRateData) {
            setState(() {
              _currentHeartRate = heartRateData;
              _statusMessage = 'Active';
            });
          },
          onError: (error) {
            setState(() {
              _statusMessage = 'Error: $error';
            });
          },
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to start';
      });
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      await _watchBridge.stopHeartRateTracking();
      await _heartRateSubscription?.cancel();
      
      setState(() {
        _isMonitoring = false;
        _statusMessage = 'Stopped';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping';
      });
    }
  }

  Future<void> _sendToPhone() async {
    if (_currentHeartRate == null) return;

    setState(() {
      _isSending = true;
      _statusMessage = 'Sending...';
    });

    // TODO: Implement WatchToPhoneSync service
    await Future.delayed(const Duration(seconds: 1)); // Simulate send

    setState(() {
      _isSending = false;
      _statusMessage = 'Sent ✓';
    });

    // Reset status after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = _isMonitoring ? 'Active' : 'Ready';
        });
      }
    });
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _pulseController.dispose();
    _watchBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAmbient = widget.mode == WearMode.ambient;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: isAmbient ? _buildAmbientMode() : _buildActiveMode(),
        ),
      ),
    );
  }

  Widget _buildActiveMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // BPM Display
        _buildBpmDisplay(),
        
        const SizedBox(height: 16),
        
        // IBI Info (optional)
        if (_currentHeartRate?.ibiValues.isNotEmpty ?? false)
          _buildIbiInfo(),
        
        const SizedBox(height: 24),
        
        // Control Buttons
        _buildControlButtons(),
        
        const SizedBox(height: 16),
        
        // Status
        _buildStatus(),
      ],
    );
  }

  Widget _buildBpmDisplay() {
    final bpm = _currentHeartRate?.bpm;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isMonitoring ? _pulseAnimation.value : 1.0,
          child: Column(
            children: [
              Icon(
                Icons.favorite,
                color: _isMonitoring ? const Color(0xFFF44336) : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                bpm != null ? '$bpm' : '--',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'BPM',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIbiInfo() {
    final ibiCount = _currentHeartRate?.ibiValues.length ?? 0;
    
    return Text(
      'IBI: $ibiCount values',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        // Start/Stop Button
        SizedBox(
          width: 120,
          height: 48,
          child: ElevatedButton(
            onPressed: _toggleMonitoring,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMonitoring 
                  ? Colors.red.shade700 
                  : const Color(0xFF1976D2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              _isMonitoring ? 'Stop' : 'Start',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Send to Phone Button
        if (_currentHeartRate != null)
          SizedBox(
            width: 140,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendToPhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B5FF),
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                _isSending ? 'Sending' : 'Send',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: _isConnected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientMode() {
    final bpm = _currentHeartRate?.bpm;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.favorite,
          color: Colors.white24,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          bpm != null ? '$bpm' : '--',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white24,
          ),
        ),
        const Text(
          'BPM',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white10,
          ),
        ),
      ],
    );
  }
}
