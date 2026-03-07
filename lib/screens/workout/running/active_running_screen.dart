import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:provider/provider.dart' as provider;
import 'dart:async';
import '../../../providers/running_session_provider.dart';
import '../../../models/running_session.dart';
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

class _ActiveRunningScreenState extends ConsumerState<ActiveRunningScreen>
    with SingleTickerProviderStateMixin {
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

  // Route args
  String _emotion = '';
  bool _isTreadmill = false;
  double _goalPaceMinKm = 0;
  String _runType = 'quick';

  // UI state
  bool _isSaving = false;
  bool _showAlert = false;
  String _alertMessage = '';
  bool _alertIsWarning = true;
  Timer? _alertTimer;

  // Alert slide animation
  late AnimationController _alertAnimController;
  late Animation<Offset> _alertSlide;

  @override
  void initState() {
    super.initState();
    _alertAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _alertSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _alertAnimController,
      curve: Curves.easeOut,
    ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasStartedDetection) {
        _hasStartedDetection = true;
        _startContinuousDetection();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _emotion = args['emotion'] as String? ?? '';
      _isTreadmill = args['isTreadmill'] as bool? ?? false;
      _goalPaceMinKm = (args['goalPaceMinKm'] as num?)?.toDouble() ?? 0;
      _runType = args['runType'] as String? ?? 'quick';
    }
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
      
      // Schedule next detection
      _scheduleNextDetection(15);
    } catch (e) {
      print('❌ Detection failed: $e');
      _scheduleNextDetection(10);
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _heartRateSubscription?.cancel();
    _detectionTimer?.cancel();
    _alertTimer?.cancel();
    _alertAnimController.dispose();
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

  Color _hrZoneColor(int? hr) {
    if (hr == null) return const Color(0xFFBDBDBD);
    if (hr < 100) return const Color(0xFF10B981);
    if (hr < 150) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  int? _calcCadence(RunningSession session) {
    final steps = session.steps;
    final secs = session.durationSeconds;
    if (steps == null || secs == null || secs == 0) return null;
    return (steps / (secs / 60)).round();
  }

  void _showAlertBanner(String message, {bool isWarning = true}) {
    setState(() {
      _alertMessage = message;
      _alertIsWarning = isWarning;
      _showAlert = true;
    });
    _alertAnimController.forward(from: 0);
    _alertTimer?.cancel();
    _alertTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _alertAnimController.reverse().then((_) {
          if (mounted) setState(() => _showAlert = false);
        });
      }
    });
  }

  void _showBackConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave session?'),
        content: const Text('Your run progress will be lost if you go back without saving.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Running'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacementNamed('/dashboard');
            },
            child: const Text('Leave & Discard'),
          ),
        ],
      ),
    );
  }

  void _showEndRunDialog(RunningSession session) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'End Run?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _previewMetric('Distance', '${session.currentDistance.toStringAsFixed(2)} km'),
                  _previewMetric('Time', _formatTime(session.durationSeconds)),
                  _previewMetric('Pace', '${_formatPace(session.avgPace)}/km'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep Going'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _endAndSave();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0A69FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save & End'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _endAndSave() async {
    setState(() => _isSaving = true);
    final notifier = ref.read(runningSessionProvider.notifier);
    await notifier.endSession();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/workout/running/summary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(runningSessionProvider);

    if (session == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0A69FF))),
      );
    }

    final isPaused = session.status == WorkoutStatus.paused;
    final currentLoc = session.routePoints.isNotEmpty ? session.routePoints.last : null;
    final effHR = _currentHeartRate ?? session.avgHeartRate;
    final hrColor = _hrZoneColor(effHR);
    final cadence = _calcCadence(session);

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _showBackConfirmDialog(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _buildMap(session, currentLoc)),
            Positioned.fill(child: _buildGradient()),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_showAlert)
                    SlideTransition(
                      position: _alertSlide,
                      child: _buildAlertBanner(),
                    ),
                  _buildTopBar(isPaused),
                  const Spacer(),
                  if (_goalPaceMinKm > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildGoalPaceIndicator(session),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildPaceDisplay(session),
                  const Spacer(),
                  _buildStatsCard(session, hrColor, effHR, cadence),
                  const SizedBox(height: 8),
                  _buildMusicCard(),
                  const SizedBox(height: 8),
                  _buildControls(isPaused, session),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_isSaving) _buildSavingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _alertIsWarning ? const Color(0xFFFF9800) : const Color(0xFF00C851),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _alertIsWarning ? SolarIconsBold.danger : SolarIconsBold.checkCircle,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _alertMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isPaused) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showBackConfirmDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF0A69FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(SolarIconsOutline.altArrowLeft, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isPaused ? const Color(0xFFFF9800) : const Color(0xFF00C851),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  isPaused ? 'PAUSED' : 'RUNNING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/trackertest'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(SolarIconsBold.cpu, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPaceIndicator(RunningSession session) {
    final current = session.avgPace;
    final isOnTrack = current == null || current <= _goalPaceMinKm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnTrack ? const Color(0xFF00C851) : const Color(0xFFFF9800),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnTrack ? SolarIconsBold.checkCircle : SolarIconsBold.danger,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Goal ${_formatPace(_goalPaceMinKm)} /km',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceDisplay(RunningSession session) {
    return Column(
      children: [
        Text(
          _formatPace(session.avgPace),
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A69FF),
            letterSpacing: -2,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'min / km',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }



  Widget _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.65),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.9),
          ],
          stops: const [0.0, 0.25, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildMap(RunningSession session, LatLng? currentLoc) {
    if (session.routePoints.isEmpty || _isTreadmill) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isTreadmill ? Icons.fitness_center : SolarIconsBold.mapPoint,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _isTreadmill ? 'Treadmill mode — GPS disabled' : 'Waiting for GPS signal...',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return FlutterMap(
      mapController: _mapController ??= MapController(),
      options: MapOptions(
        initialCenter: currentLoc ?? const LatLng(0, 0),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.pulsify',
        ),
        if (session.routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: session.routePoints,
                strokeWidth: 5,
                color: const Color(0xFF0A69FF),
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),
        if (currentLoc != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentLoc,
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A69FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
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

  Widget _buildStatsCard(
    RunningSession session,
    Color hrColor,
    int? effHR,
    int? cadence,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Distance', '${session.currentDistance.toStringAsFixed(2)}', 'km', const Color(0xFF0A69FF)),
          _statDivider(),
          _statItem('Duration', _formatTime(session.durationSeconds), '', const Color(0xFFFF9800)),
          _statDivider(),
          _statItem('Cadence', cadence != null ? '$cadence' : '--', 'spm', const Color(0xFF8B5CF6)),
          _statDivider(),
          _statItem('HR', effHR != null ? '$effHR' : '--', 'bpm', hrColor),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, String unit, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8A8D90),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
  }

  Widget _buildMusicCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No music playing',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  'Connect a music app to see playback',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_outline_rounded, color: Colors.white38, size: 28),
        ],
      ),
    );
  }

  Widget _buildControls(bool isPaused, RunningSession session) {
    final notifier = ref.read(runningSessionProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPaused) {
                  notifier.resumeSession();
                } else {
                  notifier.pauseSession();
                }
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A69FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPaused ? SolarIconsBold.playCircle : SolarIconsBold.pauseCircle,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPaused ? 'Resume' : 'Pause',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showEndRunDialog(session),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white38, width: 1.5),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_circle_outlined, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Text('End', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A69FF)),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Saving your run...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2224),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Processing run data',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A8D90)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewMetric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A69FF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A8D90)),
        ),
      ],
    );
  }
}

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
    
    // Define colors and icons for each mode
    Color modeColor = Colors.green;
    IconData modeIcon = SolarIconsBold.leaf;
    
    switch (activity.label) {
      case 'Stress':
        modeColor = Colors.red;
        modeIcon = SolarIconsBold.danger;
        break;
      case 'Cardio':
        modeColor = Colors.orange;
        modeIcon = SolarIconsBold.heartPulse;
        break;
      case 'Strength':
        modeColor = Colors.green;
        modeIcon = SolarIconsBold.leaf;
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
          
          // Stress metric
          _buildProbabilityBar(
            'Stress',
            stressProb,
            Colors.red,
            SolarIconsBold.danger,
          ),
          const SizedBox(height: 8),
          
          // Cardio metric
          _buildProbabilityBar(
            'Cardio',
            cardioProb,
            Colors.orange,
            SolarIconsBold.heartPulse,
          ),
          const SizedBox(height: 8),
          
          // Strength metric
          _buildProbabilityBar(
            'Strength',
            strengthProb,
            Colors.green,
            SolarIconsBold.leaf,
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
