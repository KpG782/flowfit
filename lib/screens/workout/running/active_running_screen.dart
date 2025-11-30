import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:provider/provider.dart' as provider;
import 'dart:async';
import '../../../providers/running_session_provider.dart';
import '../../../models/workout_session.dart';
import '../../../features/activity_classifier/presentation/providers.dart';
import '../../../features/activity_classifier/platform/tflite_activity_classifier.dart';
import '../../../services/phone_data_listener.dart';

/// Active running screen with real-time GPS tracking and metrics
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8
class ActiveRunningScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const ActiveRunningScreen({
    super.key,
    this.sessionId,
  });

  @override
  ConsumerState<ActiveRunningScreen> createState() => _ActiveRunningScreenState();
}

class _ActiveRunningScreenState extends ConsumerState<ActiveRunningScreen> {
  MapController? _mapController;
  bool _hasStartedDetection = false;
  
  // Sensor data collection for AI
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _heartRateSubscription;
  List<List<double>> _sensorBuffer = [];
  Timer? _detectionTimer;
  static const int _windowSize = 320;
  
  // Real-time heart rate from watch
  int? _currentHeartRate;
  
  // Coaching notification tracking
  String? _lastActivityMode;
  DateTime? _activityModeStartTime;
  Timer? _coachingNotificationTimer;
  Set<String> _shownNotifications = {};

  @override
  void initState() {
    super.initState();
    // Start continuous detection after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasStartedDetection) {
        _hasStartedDetection = true;
        _startContinuousDetection();
      }
    });
  }

  void _startContinuousDetection() async {
    final classifier = provider.Provider.of<TFLiteActivityClassifier>(context, listen: false);
    final phoneDataListener = provider.Provider.of<PhoneDataListener>(context, listen: false);
    
    // Load model if not loaded
    if (!classifier.isLoaded) {
      await classifier.loadModel();
    }

    // Start listening for watch data
    await phoneDataListener.startListening();

    // Subscribe to real-time heart rate from watch
    _heartRateSubscription = phoneDataListener.heartRateStream.listen(
      (heartRateData) {
        if (mounted) {
          setState(() {
            _currentHeartRate = heartRateData.bpm;
          });
          print('💓 Live HR from watch: ${heartRateData.bpm} bpm');
        }
      },
      onError: (error) {
        print('❌ Heart rate stream error: $error');
      },
    );

    // Subscribe to sensor batches from watch (includes accelerometer + heart rate)
    _sensorSubscription = phoneDataListener.sensorBatchStream.listen((sensorBatch) {
      // Add all samples from the batch to our buffer
      for (final sample in sensorBatch.samples) {
        if (sample.length == 4) {
          _sensorBuffer.add(sample);
          
          // Keep only last 320 samples
          if (_sensorBuffer.length > _windowSize) {
            _sensorBuffer.removeAt(0);
          }
        }
      }
      
      // Run inference when we have enough data (>= 320 samples)
      if (_sensorBuffer.length >= _windowSize) {
        _runDetection();
      }
    });

    // Schedule first detection as backup
    _scheduleNextDetection(10);
  }

  void _scheduleNextDetection(int seconds) {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) {
        _runDetection();
      }
    });
  }

  Future<void> _runDetection() async {
    if (_sensorBuffer.length < _windowSize) {
      print('🔴 Buffer not ready: ${_sensorBuffer.length}/$_windowSize samples');
      _scheduleNextDetection(5);
      return;
    }

    try {
      print('🟢 Running AI detection with ${_sensorBuffer.length} samples');
      final viewModel = provider.Provider.of<ActivityClassifierViewModel>(context, listen: false);
      final bufferCopy = List<List<double>>.from(_sensorBuffer.take(_windowSize));
      await viewModel.classify(bufferCopy);
      print('✅ AI detection completed');
      
      // Check for activity mode changes and schedule coaching notifications
      final currentActivity = viewModel.currentActivity;
      if (currentActivity != null) {
        _handleActivityModeChange(currentActivity.label);
      }
      
      // Schedule next detection
      _scheduleNextDetection(15);
    } catch (e) {
      print('❌ Detection failed: $e');
      _scheduleNextDetection(10);
    }
  }
  
  /// Handle activity mode changes and schedule coaching notifications
  void _handleActivityModeChange(String newMode) {
    // If mode changed, reset timer
    if (_lastActivityMode != newMode) {
      print('🔄 Activity mode changed: $_lastActivityMode → $newMode');
      _lastActivityMode = newMode;
      _activityModeStartTime = DateTime.now();
      
      // Cancel any pending notification
      _coachingNotificationTimer?.cancel();
      
      // Schedule notification for 10 seconds in this mode
      _coachingNotificationTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _lastActivityMode == newMode) {
          _showCoachingNotification(newMode);
        }
      });
    }
  }
  
  /// Show coaching notification based on activity mode
  void _showCoachingNotification(String mode) {
    // Create unique key for this notification to avoid duplicates
    final notificationKey = '$mode-${DateTime.now().minute}';
    
    // Don't show if already shown in this minute
    if (_shownNotifications.contains(notificationKey)) {
      return;
    }
    _shownNotifications.add(notificationKey);
    
    // Clean up old notifications (keep only last 5)
    if (_shownNotifications.length > 5) {
      _shownNotifications.remove(_shownNotifications.first);
    }
    
    String title;
    String message;
    IconData icon;
    Color color;
    
    switch (mode) {
      case 'Stress':
        title = '🔥 High Intensity Detected!';
        message = 'You\'re pushing hard! Consider slowing down to avoid burnout. Take deep breaths.';
        icon = SolarIconsBold.fire;
        color = const Color(0xFFE53935);
        break;
      case 'Cardio':
        title = '❤️ Perfect Cardio Zone!';
        message = 'Great pace! You\'re in the optimal zone for cardiovascular fitness. Keep it up!';
        icon = SolarIconsBold.heart;
        color = const Color(0xFFFF9800);
        break;
      case 'Strength':
      case 'Calm':
        title = '😊 Easy Pace Detected';
        message = 'You\'re taking it easy. Feel free to pick up the pace if you want more intensity!';
        icon = SolarIconsBold.smileCircle;
        color = const Color(0xFF4CAF50);
        break;
      default:
        return; // Don't show notification for unknown modes
    }
    
    // Show snackbar notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      print('💬 Coaching notification shown: $title');
    }
  }

  @override
  void dispose() {
    // Stop continuous detection when leaving screen
    _sensorSubscription?.cancel();
    _heartRateSubscription?.cancel();
    _detectionTimer?.cancel();
    _coachingNotificationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double distance) {
    return distance.toStringAsFixed(2);
  }

  String _formatPace(double? pace) {
    if (pace == null) return '--:--';
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showEndWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Are you sure you want to end this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // End the session properly
              final notifier = ref.read(runningSessionProvider.notifier);
              await notifier.endSession();
              
              // Navigate to summary
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/workout/running/summary');
              }
            },
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(runningSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Running')),
        body: const Center(
          child: Text('No active session'),
        ),
      );
    }

    final isPaused = session.status == WorkoutStatus.paused;
    final currentLocation = session.routePoints.isNotEmpty 
        ? session.routePoints.last 
        : null;

    return provider.Consumer<ActivityClassifierViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Full-screen map as background
                _buildFullScreenMap(session, currentLocation),
                
                // Gradient overlay for better readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.2, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Content overlay
                Column(
                  children: [
                    // Header with controls
                    _buildHeader(theme, session, isPaused),
                    
                    const Spacer(),
                    
                    // Activity mode badge (always show)
                    _buildActivityModeBadge(viewModel),
                    
                    // AI Metrics breakdown (show when detected)
                    if (viewModel.currentActivity != null)
                      _buildAIMetricsBreakdown(viewModel),
                    
                    const SizedBox(height: 16),
                    
                    // Bottom metrics panel
                    _buildBottomMetricsPanel(theme, session),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, dynamic session, bool isPaused) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(SolarIconsOutline.altArrowLeft, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              minimumSize: const Size(44, 44),
            ),
          ),
          
          const Spacer(),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPaused 
                  ? Colors.orange.withOpacity(0.9)
                  : Colors.green.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaused ? SolarIconsBold.pauseCircle : SolarIconsBold.playCircle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isPaused ? 'PAUSED' : 'RUNNING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Debug button - Navigate to AI Tracker
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/trackertest');
            },
            icon: const Icon(SolarIconsBold.cpu, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.8),
              minimumSize: const Size(44, 44),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Menu button
          IconButton(
            onPressed: () {},
            icon: const Icon(SolarIconsOutline.menuDots, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFullScreenMap(dynamic session, LatLng? currentLocation) {
    return session.routePoints.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  SolarIconsBold.mapPoint,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for GPS signal...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : FlutterMap(
            mapController: _mapController ??= MapController(),
            options: MapOptions(
              initialCenter: currentLocation ?? const LatLng(0, 0),
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flowfit.app',
              ),
              // Route polyline
              if (session.routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: session.routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF3B82F6),
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              // Current location marker
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
  }

  Widget _buildBottomMetricsPanel(ThemeData theme, dynamic session) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLargeMetric(
                'Distance',
                '${_formatDistance(session.currentDistance)}',
                'km',
                SolarIconsBold.routing2,  // Road/path icon (more intuitive)
                const Color(0xFF3B82F6),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              _buildLargeMetric(
                'Time',
                _formatTime(session.durationSeconds),
                '',
                SolarIconsBold.clockCircle,  // Clock = time (universal)
                const Color(0xFFFF9800),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              _buildLargeMetric(
                'Speed',
                _formatPace(session.avgPace),
                '/km',
                SolarIconsBold.runningRound,  // Running person = speed (intuitive)
                const Color(0xFF4CAF50),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Secondary metrics row
          Row(
            children: [
              _buildSmallMetric(
                'Heart',
                _currentHeartRate != null ? '$_currentHeartRate' : (session.avgHeartRate != null ? '${session.avgHeartRate}' : '--'),
                'bpm',
                SolarIconsBold.heart,  // Simple heart - everyone understands
                const Color(0xFFE91E63),
                isLive: _currentHeartRate != null,
              ),
              const SizedBox(width: 12),
              _buildSmallMetric(
                'Calories',
                session.caloriesBurned != null ? '${session.caloriesBurned}' : '--',
                'kcal',
                SolarIconsBold.fire,  // Fire = burning calories (universal)
                const Color(0xFFFF5722),
              ),
              const SizedBox(width: 12),
              _buildSmallMetric(
                'Steps',
                session.steps != null ? '${session.steps}' : '--',
                '',
                SolarIconsBold.runningRound,  // Running person (clear & intuitive)
                const Color(0xFF2196F3),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Control buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final isPaused = session.status == WorkoutStatus.paused;
                    if (isPaused) {
                      ref.read(runningSessionProvider.notifier).resumeSession();
                    } else {
                      ref.read(runningSessionProvider.notifier).pauseSession();
                    }
                  },
                  icon: Icon(
                    session.status == WorkoutStatus.paused 
                        ? SolarIconsBold.play 
                        : SolarIconsBold.pause,
                  ),
                  label: Text(
                    session.status == WorkoutStatus.paused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _showEndWorkoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(SolarIconsBold.stopCircle, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeMetric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        // Larger, more prominent icon with background
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.0,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMetric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color, {
    bool isLive = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: isLive ? Border.all(
            color: color.withOpacity(0.6),
            width: 2,
          ) : null,
          boxShadow: isLive ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            // Icon with live indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                if (isLive) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Value
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityModeBadge(ActivityClassifierViewModel viewModel) {
    print('🎨 Building badge - Activity: ${viewModel.currentActivity?.label}, Loading: ${viewModel.isLoading}');
    
    // Show loading state while detecting
    if (viewModel.currentActivity == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.9),
              const Color(0xFF8B5CF6).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Activity Detection',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Analyzing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final activity = viewModel.currentActivity!;
    final modeLabel = activity.label.toUpperCase();
    final confidence = activity.confidence;
    
      // Define colors and icons for each mode (kid-friendly & intuitive)
    Color modeColor = Colors.green;
    IconData modeIcon = SolarIconsBold.smileCircle;  // Happy face for calm
    
    switch (activity.label) {
      case 'Stress':
        modeColor = const Color(0xFFE53935);  // Bright red
        modeIcon = SolarIconsBold.fire;  // Fire = intense/hot
        break;
      case 'Cardio':
        modeColor = const Color(0xFFFF9800);  // Bright orange
        modeIcon = SolarIconsBold.heart;  // Heart = cardio (universal)
        break;
      case 'Strength':
      case 'Calm':
        modeColor = const Color(0xFF4CAF50);  // Bright green
        modeIcon = SolarIconsBold.smileCircle;  // Smile = good/calm
        break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            modeColor.withOpacity(0.9),
            modeColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: modeColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(modeIcon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI Activity Mode',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    modeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIMetricsBreakdown(ActivityClassifierViewModel viewModel) {
    final probabilities = viewModel.currentActivity!.probabilities;
    final stressProb = probabilities[0];
    final cardioProb = probabilities[1];
    final strengthProb = probabilities[2];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(SolarIconsBold.cpu, size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 6),
              const Text(
                'AI Detection Breakdown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Stress metric (High intensity)
          _buildProbabilityBar(
            'High Intensity',
            stressProb,
            const Color(0xFFE53935),
            SolarIconsBold.fire,  // Fire = hot/intense
          ),
          const SizedBox(height: 8),
          
          // Cardio metric (Medium intensity)
          _buildProbabilityBar(
            'Cardio Zone',
            cardioProb,
            const Color(0xFFFF9800),
            SolarIconsBold.heart,  // Heart = cardio
          ),
          const SizedBox(height: 8),
          
          // Strength/Calm metric (Low intensity)
          _buildProbabilityBar(
            'Easy Pace',
            strengthProb,
            const Color(0xFF4CAF50),
            SolarIconsBold.smileCircle,  // Smile = easy/comfortable
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBar(
    String label,
    double probability,
    Color color,
    IconData icon,
  ) {
    final percentage = (probability * 100).toStringAsFixed(1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: probability,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
