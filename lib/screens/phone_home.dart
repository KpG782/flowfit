import 'package:flutter/material.dart';
import 'dart:async';
import '../models/heart_rate_data.dart';
import '../services/phone_data_listener.dart';

class PhoneHomePage extends StatefulWidget {
  const PhoneHomePage({super.key});

  @override
  State<PhoneHomePage> createState() => _PhoneHomePageState();
}

class _PhoneHomePageState extends State<PhoneHomePage> {
  final PhoneDataListener _dataListener = PhoneDataListener();
  
  List<HeartRateData> _heartRateHistory = [];
  HeartRateData? _latestHeartRate;
  bool _isConnected = false;
  String _statusMessage = 'Waiting for watch data...';
  
  StreamSubscription? _heartRateSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeDataListener();
  }
  
  void _initializeDataListener() {
    // Listen for heart rate data from watch
    _heartRateSubscription = _dataListener.heartRateStream.listen(
      (heartRateData) {
        setState(() {
          _latestHeartRate = heartRateData;
          _heartRateHistory.insert(0, heartRateData);
          
          // Keep only last 50 readings
          if (_heartRateHistory.length > 50) {
            _heartRateHistory = _heartRateHistory.sublist(0, 50);
          }
          
          _isConnected = true;
          _statusMessage = 'Receiving data from watch';
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'Error: $error';
          _isConnected = false;
        });
      },
    );
    
    // Start listening for watch data
    _dataListener.startListening();
  }
  
  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _dataListener.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar.large(
            title: const Text('FlowFit'),
            actions: [
              IconButton(
                icon: Icon(
                  _isConnected ? Icons.watch : Icons.watch_off_outlined,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isConnected 
                        ? 'Connected to Galaxy Watch' 
                        : 'Watch not connected'),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Current Heart Rate Card
                _buildCurrentHeartRateCard(colorScheme),
                
                const SizedBox(height: 16),
                
                // Stats Row
                _buildStatsRow(colorScheme),
                
                const SizedBox(height: 16),
                
                // Status Card
                _buildStatusCard(colorScheme),
                
                const SizedBox(height: 16),
                
                // Recent Readings
                _buildRecentReadingsCard(colorScheme),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _heartRateHistory.clear();
            _latestHeartRate = null;
            _statusMessage = 'Cleared history';
          });
        },
        icon: const Icon(Icons.clear_all),
        label: const Text('Clear'),
      ),
    );
  }
  
  Widget _buildCurrentHeartRateCard(ColorScheme colorScheme) {
    final bpm = _latestHeartRate?.bpm;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Heart Rate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (bpm != null) ...[
              Text(
                '$bpm',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'BPM',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildHeartRateZone(bpm, colorScheme),
            ] else ...[
              Icon(
                Icons.heart_broken_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No data yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeartRateZone(int bpm, ColorScheme colorScheme) {
    String zone;
    Color zoneColor;
    
    if (bpm < 60) {
      zone = 'Resting';
      zoneColor = Colors.blue;
    } else if (bpm < 100) {
      zone = 'Light';
      zoneColor = Colors.green;
    } else if (bpm < 140) {
      zone = 'Moderate';
      zoneColor = Colors.orange;
    } else if (bpm < 170) {
      zone = 'Hard';
      zoneColor = Colors.deepOrange;
    } else {
      zone = 'Maximum';
      zoneColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: zoneColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zoneColor, width: 2),
      ),
      child: Text(
        zone,
        style: TextStyle(
          color: zoneColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildStatsRow(ColorScheme colorScheme) {
    final avgBpm = _heartRateHistory.isNotEmpty
        ? _heartRateHistory
            .where((d) => d.bpm != null)
            .map((d) => d.bpm!)
            .reduce((a, b) => a + b) ~/
            _heartRateHistory.where((d) => d.bpm != null).length
        : 0;
    
    final maxBpm = _heartRateHistory.isNotEmpty
        ? _heartRateHistory
            .where((d) => d.bpm != null)
            .map((d) => d.bpm!)
            .reduce((a, b) => a > b ? a : b)
        : 0;
    
    final minBpm = _heartRateHistory.isNotEmpty
        ? _heartRateHistory
            .where((d) => d.bpm != null)
            .map((d) => d.bpm!)
            .reduce((a, b) => a < b ? a : b)
        : 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Average', '$avgBpm', Icons.show_chart, colorScheme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Max', '$maxBpm', Icons.arrow_upward, colorScheme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Min', '$minBpm', Icons.arrow_downward, colorScheme),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard(ColorScheme colorScheme) {
    return Card(
      color: _isConnected 
          ? colorScheme.primaryContainer 
          : colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.info_outline,
              color: _isConnected 
                  ? colorScheme.onPrimaryContainer 
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'Connected' : 'Waiting',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _isConnected 
                          ? colorScheme.onPrimaryContainer 
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isConnected 
                          ? colorScheme.onPrimaryContainer 
                          : colorScheme.onSurfaceVariant,
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
  
  Widget _buildRecentReadingsCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Readings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${_heartRateHistory.length} readings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_heartRateHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.watch,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No readings yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start tracking on your watch',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _heartRateHistory.length > 10 ? 10 : _heartRateHistory.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final data = _heartRateHistory[index];
                  final timeAgo = _getTimeAgo(data.timestamp);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '${data.bpm ?? '--'}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text('${data.bpm ?? '--'} BPM'),
                    subtitle: Text(
                      'IBI: ${data.ibiValues.length} values • $timeAgo',
                    ),
                    trailing: Icon(
                      Icons.favorite,
                      color: colorScheme.primary.withOpacity(0.5),
                      size: 20,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
