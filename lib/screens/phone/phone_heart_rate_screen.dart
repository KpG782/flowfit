import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tracked_data.dart';

/// Screen for displaying heart rate data received from Galaxy Watch
/// Shows real-time BPM, IBI values, and connection status
class PhoneHeartRateScreen extends StatefulWidget {
  const PhoneHeartRateScreen({super.key});

  @override
  State<PhoneHeartRateScreen> createState() => _PhoneHeartRateScreenState();
}

class _PhoneHeartRateScreenState extends State<PhoneHeartRateScreen> {
  static const EventChannel _eventChannel =
      EventChannel('com.flowfit.phone/heartrate');
  static const EventChannel _sensorBatchEventChannel =
      EventChannel('com.flowfit.phone/sensor_data');

  final List<TrackedData> _receivedData = [];
  StreamSubscription? _subscription;
  StreamSubscription? _sensorBatchSubscription;
  bool _isConnected = false;
  DateTime? _lastDataTime;
  
  // Test mode state
  bool _isTestMode = false;
  Map<String, dynamic>? _lastSensorBatch;
  int _totalBatchesReceived = 0;

  @override
  void initState() {
    super.initState();
    _listenToWatchData();
    _listenToSensorBatches();
  }

  void _listenToWatchData() {
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (data) {
        try {
          // Android sends data as Map directly, not as JSON string
          final jsonData = data is String ? jsonDecode(data) : data;

          setState(() {
            _isConnected = true;
            _lastDataTime = DateTime.now();

            if (jsonData is List) {
              // Batch data
              final batch = jsonData
                  .map((item) => TrackedData.fromJson(Map<String, dynamic>.from(item as Map)))
                  .toList();
              _receivedData.addAll(batch);
              
              // Keep only last 100 readings
              if (_receivedData.length > 100) {
                _receivedData.removeRange(0, _receivedData.length - 100);
              }
            } else {
              // Single data point
              final trackedData = TrackedData.fromJson(Map<String, dynamic>.from(jsonData as Map));
              _receivedData.add(trackedData);
              
              // Keep only last 100 readings
              if (_receivedData.length > 100) {
                _receivedData.removeAt(0);
              }
            }
          });
        } catch (e) {
          debugPrint('Error parsing watch data: $e');
        }
      },
      onError: (error) {
        debugPrint('Error receiving watch data: $error');
        setState(() {
          _isConnected = false;
        });
      },
    );
  }

  void _listenToSensorBatches() {
    _sensorBatchSubscription = _sensorBatchEventChannel.receiveBroadcastStream().listen(
      (data) {
        try {
          final jsonData = data as Map;
          
          setState(() {
            _lastSensorBatch = Map<String, dynamic>.from(jsonData);
            _totalBatchesReceived++;
            _isConnected = true;
            _lastDataTime = DateTime.now();
          });
          
          debugPrint('📦 Received sensor batch: ${_lastSensorBatch?['count']} samples, BPM: ${_lastSensorBatch?['bpm']}');
        } catch (e) {
          debugPrint('Error parsing sensor batch: $e');
        }
      },
      onError: (error) {
        debugPrint('Error receiving sensor batch: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sensorBatchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Heart Rate Data'),
        actions: [
          // Test mode toggle
          IconButton(
            onPressed: () {
              setState(() {
                _isTestMode = !_isTestMode;
              });
            },
            icon: Icon(
              _isTestMode ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            tooltip: 'Test Mode',
          ),
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.watch : Icons.watch_off,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _receivedData.isEmpty
          ? _buildEmptyState()
          : _buildDataList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.watch,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No data received yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start heart rate tracking on your watch',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    // Show most recent data first
    final reversedData = _receivedData.reversed.toList();
    final latestData = reversedData.isNotEmpty ? reversedData.first : null;

    return Column(
      children: [
        // Test mode display
        if (_isTestMode) ...[
          _buildTestModeDisplay(),
          const Divider(),
        ],
        
        // Large BPM display at top
        if (latestData != null) _buildLatestBpmCard(latestData),
        
        // Data freshness indicator
        if (_lastDataTime != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: ${_formatTimestamp(_lastDataTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        
        const Divider(),
        
        // List of all readings
        if (!_isTestMode)
          Expanded(
            child: ListView.builder(
              itemCount: reversedData.length,
              itemBuilder: (context, index) {
                final data = reversedData[index];
                return _buildDataTile(data, index == 0);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLatestBpmCard(TrackedData data) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Current Heart Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${data.hr}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (data.ibiValues.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'IBI: ${data.ibiValues.take(5).join(", ")}${data.ibiValues.length > 5 ? "..." : ""} ms',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(TrackedData data, bool isLatest) {
    return ListTile(
      leading: Icon(
        Icons.favorite,
        color: isLatest ? Colors.red : Colors.grey,
      ),
      title: Text(
        'HR: ${data.hr} bpm',
        style: TextStyle(
          fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: data.ibiValues.isNotEmpty
          ? Text('IBI: ${data.ibiValues.take(4).join(", ")}${data.ibiValues.length > 4 ? "..." : ""} ms')
          : const Text('No IBI data'),
      trailing: isLatest
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Latest',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTestModeDisplay() {
    final batch = _lastSensorBatch;
    
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Test Mode - Sensor Batch Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (batch != null) ...[
              _buildTestRow('Total Batches Received', '$_totalBatchesReceived'),
              _buildTestRow('Sample Count', '${batch['count'] ?? '--'}'),
              _buildTestRow('Heart Rate', '${batch['bpm'] ?? '--'} bpm'),
              _buildTestRow('Sample Rate', '${batch['sample_rate'] ?? '--'} Hz'),
              _buildTestRow('Timestamp', '${batch['timestamp'] ?? '--'}'),
              const SizedBox(height: 12),
              const Text(
                'Accelerometer Samples (first 3):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              if (batch['accelerometer'] != null) ...[
                ..._buildAccelerometerSamples(batch['accelerometer'] as List),
              ] else
                const Text('No accelerometer data', style: TextStyle(color: Colors.grey)),
            ] else
              const Text(
                'No sensor batch received yet',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccelerometerSamples(List samples) {
    final widgets = <Widget>[];
    final samplesToShow = samples.take(3).toList();
    
    for (var i = 0; i < samplesToShow.length; i++) {
      final sample = samplesToShow[i] as List;
      if (sample.length >= 3) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              'Sample ${i + 1}: X=${(sample[0] as num).toStringAsFixed(2)}, '
              'Y=${(sample[1] as num).toStringAsFixed(2)}, '
              'Z=${(sample[2] as num).toStringAsFixed(2)} m/s²',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
        );
      }
    }
    
    if (samples.length > 3) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '... and ${samples.length - 3} more samples',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
