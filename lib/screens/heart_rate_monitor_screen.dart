import 'dart:async';
import 'package:flutter/material.dart';
import '../services/watch_bridge.dart';
import '../models/heart_rate_data.dart';
import '../models/sensor_status.dart';
import '../models/sensor_error.dart';

/// Sample screen demonstrating live heart rate monitoring
/// Shows real-time heart rate data from Galaxy Watch 6
class HeartRateMonitorScreen extends StatefulWidget {
  const HeartRateMonitorScreen({super.key});

  @override
  State<HeartRateMonitorScreen> createState() => _HeartRateMonitorScreenState();
}

class _HeartRateMonitorScreenState extends State<HeartRateMonitorScreen> {
  final WatchBridgeService _watchBridge = WatchBridgeService();
  
  StreamSubscription<HeartRateData>? _heartRateSubscription;
  HeartRateData? _currentHeartRate;
  bool _isTracking = false;
  bool _isConnected = false;
  String? _errorMessage;
  
  // Store recent heart rate values for visualization
  final List<int> _recentHeartRates = [];
  static const int _maxHistoryLength = 20;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  @override
  void dispose() {
    _stopTracking();
    _watchBridge.dispose();
    super.dispose();
  }

  /// Check if watch is connected
  Future<void> _checkConnectionStatus() async {
    try {
      final connected = await _watchBridge.isWatchConnected();
      setState(() {
        _isConnected = connected;
        if (!connected) {
          _errorMessage = 'Watch not connected. Please connect your Galaxy Watch 6.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check connection: ${e.toString()}';
      });
    }
  }

  /// Connect to the watch
  Future<void> _connectToWatch() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      // Check permissions first
      final hasPermission = await _watchBridge.requestBodySensorPermission();
      
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Body sensor permission denied. Please grant permission in settings.';
        });
        return;
      }

      // Connect to watch
      final connected = await _watchBridge.connectToWatch();
      
      setState(() {
        _isConnected = connected;
        if (!connected) {
          _errorMessage = 'Failed to connect to watch. Please ensure your Galaxy Watch 6 is paired.';
        }
      });
    } on SensorError catch (e) {
      setState(() {
        _errorMessage = '${e.message}: ${e.details}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
      });
    }
  }

  /// Start heart rate tracking
  Future<void> _startTracking() async {
    if (!_isConnected) {
      await _connectToWatch();
      if (!_isConnected) return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      // Start tracking on the watch
      final started = await _watchBridge.startHeartRateTracking();
      
      if (!started) {
        setState(() {
          _errorMessage = 'Failed to start heart rate tracking';
        });
        return;
      }

      // Subscribe to heart rate stream
      _heartRateSubscription = _watchBridge.heartRateStream.listen(
        (heartRateData) {
          setState(() {
            _currentHeartRate = heartRateData;
            
            // Add to history for visualization
            if (heartRateData.status == SensorStatus.active && heartRateData.bpm != null) {
              _recentHeartRates.add(heartRateData.bpm!);
              if (_recentHeartRates.length > _maxHistoryLength) {
                _recentHeartRates.removeAt(0);
              }
            }
          });
        },
        onError: (error) {
          setState(() {
            if (error is SensorError) {
              _errorMessage = '${error.message}: ${error.details}';
            } else {
              _errorMessage = 'Stream error: ${error.toString()}';
            }
          });
        },
      );

      setState(() {
        _isTracking = true;
      });
    } on SensorError catch (e) {
      setState(() {
        _errorMessage = '${e.message}: ${e.details}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
      });
    }
  }

  /// Stop heart rate tracking
  Future<void> _stopTracking() async {
    try {
      await _heartRateSubscription?.cancel();
      _heartRateSubscription = null;
      
      await _watchBridge.stopHeartRateTracking();
      
      setState(() {
        _isTracking = false;
        _currentHeartRate = null;
        _recentHeartRates.clear();
      });
    } on SensorError catch (e) {
      setState(() {
        _errorMessage = '${e.message}: ${e.details}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error stopping tracking: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Heart Rate Monitor'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.watch : Icons.watch_off),
            onPressed: _isConnected ? null : _connectToWatch,
            tooltip: _isConnected ? 'Connected' : 'Connect to watch',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              _buildConnectionStatusCard(),
              
              const SizedBox(height: 20),
              
              // Heart Rate Display
              Expanded(
                child: _buildHeartRateDisplay(),
              ),
              
              const SizedBox(height: 20),
              
              // Error Message
              if (_errorMessage != null)
                _buildErrorCard(),
              
              const SizedBox(height: 20),
              
              // Control Buttons
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.warning,
              color: _isConnected ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'Galaxy Watch 6 Connected' : 'Watch Not Connected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isConnected 
                        ? 'Ready to track heart rate'
                        : 'Please connect your watch',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateDisplay() {
    if (!_isTracking) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Start tracking to see live heart rate',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Large heart rate display
        _buildLargeHeartRateDisplay(),
        
        const SizedBox(height: 40),
        
        // Mini chart showing recent values
        _buildMiniChart(),
        
        const SizedBox(height: 20),
        
        // Status indicator
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildLargeHeartRateDisplay() {
    final bpm = _currentHeartRate?.bpm ?? 0;
    final isActive = _currentHeartRate?.status == SensorStatus.active;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.red.shade50 : Colors.grey.shade100,
        border: Border.all(
          color: isActive ? Colors.red : Colors.grey,
          width: 4,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 60,
            color: isActive ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            '$bpm',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.red.shade700 : Colors.grey,
            ),
          ),
          Text(
            'BPM',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    if (_recentHeartRates.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxBpm = _recentHeartRates.reduce((a, b) => a > b ? a : b);
    final minBpm = _recentHeartRates.reduce((a, b) => a < b ? a : b);
    final range = maxBpm - minBpm;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Readings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _recentHeartRates.map((bpm) {
                  final normalizedHeight = range > 0 
                      ? ((bpm - minBpm) / range) * 50 + 10
                      : 30.0;
                  
                  return Container(
                    width: 8,
                    height: normalizedHeight,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: $minBpm',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Max: $maxBpm',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final status = _currentHeartRate?.status ?? SensorStatus.inactive;
    final statusText = status.toString().split('.').last;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case SensorStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.sensors;
        break;
      case SensorStatus.inactive:
        statusColor = Colors.grey;
        statusIcon = Icons.sensors_off;
        break;
      case SensorStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case SensorStatus.unavailable:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Text(
          'Sensor: ${statusText.toUpperCase()}',
          style: TextStyle(
            fontSize: 14,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isTracking ? null : _startTracking,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Tracking'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isTracking ? _stopTracking : null,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Tracking'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }
}
