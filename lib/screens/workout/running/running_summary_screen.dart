import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../widgets/mood_transformation_card.dart';
import '../../../providers/running_session_provider.dart';
import '../../../models/running_session.dart';

/// Post-run summary with 3-tab layout: Overview, Music, Running analytics
class RunningSummaryScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const RunningSummaryScreen({
    super.key,
    this.sessionId,
  });

  @override
  ConsumerState<RunningSummaryScreen> createState() => _RunningSummaryScreenState();
}

class _RunningSummaryScreenState extends ConsumerState<RunningSummaryScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _tabController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _fitMapToRoute() {
    final session = ref.read(runningSessionProvider);
    if (session == null || session.routePoints.isEmpty) return;

    // Calculate bounds
    double minLat = session.routePoints.first.latitude;
    double maxLat = session.routePoints.first.latitude;
    double minLng = session.routePoints.first.longitude;
    double maxLng = session.routePoints.first.longitude;

    for (final point in session.routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
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

  int? _calcCadence(RunningSession session) {
    final steps = session.steps;
    final secs = session.durationSeconds;
    if (steps == null || secs == null || secs == 0) return null;
    return (steps / (secs / 60)).round();
  }

  Future<void> _saveToHistory() async {
    setState(() => _isSaving = true);
    try {
      final session = ref.read(runningSessionProvider);
      if (session != null) {
        await ref.read(workoutSessionServiceProvider).saveSession(session);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Workout saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareAchievement() async {
    final session = ref.read(runningSessionProvider);
    if (session == null) return;
    Navigator.of(context).pushNamed(
      '/workout/running/share',
      arguments: {'session': session},
    );
  }

  void _discardSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard session?'),
        content: const Text('This run will not be saved. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(runningSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Complete')),
        body: const Center(child: Text('No session data available')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(session),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(session),
                  _buildMusicTab(),
                  _buildRunningTab(session),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RunningSession session) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(SolarIconsOutline.altArrowLeft, color: Color(0xFF1F2224), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Session Complete',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2224),
                ),
              ),
              Text(
                _formatDate(session.startTime),
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8D90)),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A69FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'GREAT RUN!',
              style: TextStyle(
                color: Color(0xFF0A69FF),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF0A69FF),
        unselectedLabelColor: const Color(0xFF8A8D90),
        indicatorColor: const Color(0xFF0A69FF),
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Music'),
          Tab(text: 'Running'),
        ],
      ),
    );
  }

  // === OVERVIEW TAB ===

  Widget _buildOverviewTab(RunningSession session) {
    final cadence = _calcCadence(session);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRunCompletionCard(session),
          const SizedBox(height: 16),
          MoodTransformationCard(
            preMood: session.preMood,
            postMood: session.postMood,
            moodChange: session.moodChange,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(session, cadence),
          if (session.routePoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRouteMapCard(session),
          ],
          const SizedBox(height: 16),
          _buildPostRunActions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRunCompletionCard(RunningSession session) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            session.currentDistance.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A69FF),
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const Text(
            'km',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8A8D90),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryMetric('Duration', _formatTime(session.durationSeconds)),
              _summaryMetricDivider(),
              _summaryMetric('Avg Pace', '${_formatPace(session.avgPace)}/km'),
              _summaryMetricDivider(),
              _summaryMetric('Calories', session.caloriesBurned != null ? '${session.caloriesBurned}' : '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2224),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8A8D90)),
        ),
      ],
    );
  }

  Widget _summaryMetricDivider() {
    return Container(width: 1, height: 32, color: const Color(0xFFEEEEEE));
  }

  Widget _buildMetricRow(RunningSession session, int? cadence) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            'Steps',
            session.steps != null ? '${session.steps}' : '--',
            '',
            SolarIconsBold.runFast,
            const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            'Avg HR',
            session.avgHeartRate != null ? '${session.avgHeartRate}' : '--',
            'bpm',
            SolarIconsBold.heart,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            'Cadence',
            cadence != null ? '$cadence' : '--',
            'spm',
            SolarIconsBold.clockCircle,
            const Color(0xFF0A69FF),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 1),
                  child: Text(
                    unit,
                    style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8D90)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMapCard(RunningSession session) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Your Route',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2224),
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: session.routePoints.isNotEmpty
                    ? session.routePoints.first
                    : const LatLng(0, 0),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.pulsify',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: session.routePoints,
                      strokeWidth: 4,
                      color: const Color(0xFF0A69FF),
                    ),
                  ],
                ),
                if (session.routePoints.length >= 2)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: session.routePoints.first,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C851),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                        ),
                      ),
                      Marker(
                        point: session.routePoints.last,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.stop, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostRunActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveToHistory,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0A69FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Run',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _shareAchievement,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0A69FF), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(SolarIconsBold.share, color: Color(0xFF0A69FF), size: 18),
            label: const Text(
              'Share Achievement',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A69FF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _discardSession,
          child: const Text(
            'Discard Run',
            style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // === MUSIC TAB ===

  Widget _buildMusicTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.music_note_rounded, size: 36, color: Color(0xFF8A8D90)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No music data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2224),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect a music app before your next run\nto see playback history here.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8A8D90)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // === RUNNING ANALYTICS TAB ===

  Widget _buildRunningTab(RunningSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPaceCard(session),
          const SizedBox(height: 16),
          _buildHRCard(session),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaceCard(RunningSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(SolarIconsBold.speedometer, color: Color(0xFF0A69FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pace Analysis',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2224),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _analysisMetric(
                  'Avg Pace',
                  '${_formatPace(session.avgPace)}/km',
                  const Color(0xFF0A69FF),
                ),
              ),
              Expanded(
                child: _analysisMetric(
                  'Distance',
                  '${session.currentDistance.toStringAsFixed(2)} km',
                  const Color(0xFF00C851),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF8A8D90)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Per-km pace splits will be available in a future update.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A8D90)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHRCard(RunningSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(SolarIconsBold.heart, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Heart Rate',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2224),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _analysisMetric(
                  'Avg HR',
                  session.avgHeartRate != null ? '${session.avgHeartRate} bpm' : '--',
                  const Color(0xFFEF4444),
                ),
              ),
              Expanded(
                child: _analysisMetric(
                  'Max HR',
                  session.maxHeartRate != null ? '${session.maxHeartRate} bpm' : '--',
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          if (session.heartRateZones != null && session.heartRateZones!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildHRZones(session.heartRateZones!),
          ],
        ],
      ),
    );
  }

  Widget _buildHRZones(Map<String, int> zones) {
    final totalSeconds = zones.values.fold<int>(0, (s, v) => s + v);
    if (totalSeconds == 0) return const SizedBox.shrink();

    final zoneColors = {
      'zone1': Colors.blue,
      'zone2': Colors.green,
      'zone3': Colors.yellow.shade700,
      'zone4': Colors.orange,
      'zone5': Colors.red,
    };
    final zoneNames = {
      'zone1': 'Zone 1 (50–60%)',
      'zone2': 'Zone 2 (60–70%)',
      'zone3': 'Zone 3 (70–80%)',
      'zone4': 'Zone 4 (80–90%)',
      'zone5': 'Zone 5 (90–100%)',
    };

    return Column(
      children: zones.entries.map((e) {
        final pct = (e.value / totalSeconds * 100).round();
        final mins = e.value ~/ 60;
        final color = zoneColors[e.key] ?? Colors.grey;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    zoneNames[e.key] ?? e.key,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1F2224)),
                  ),
                  Text(
                    '$mins min • $pct%',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8A8D90)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _analysisMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8A8D90)),
        ),
      ],
    );
  }

  // === HELPERS ===

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetrics(ThemeData theme, dynamic session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Avg Pace',
                  '${_formatPace(session.avgPace)} /km',
                  Icons.speed,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Avg HR',
                  session.avgHeartRate != null 
                      ? '${session.avgHeartRate} bpm'
                      : '--',
                  Icons.favorite,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Calories',
                  session.caloriesBurned != null 
                      ? '${session.caloriesBurned} cal'
                      : '--',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRouteMap(ThemeData theme, dynamic session) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Your Route',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: session.routePoints.isNotEmpty 
                    ? session.routePoints.first 
                    : const LatLng(0, 0),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pulsify.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: session.routePoints,
                      strokeWidth: 4,
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
                // Start marker
                if (session.routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: session.routePoints.first,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      // End marker
                      Marker(
                        point: session.routePoints.last,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateZones(ThemeData theme, dynamic session) {
    final zones = session.heartRateZones!;
    final totalSeconds = zones.values.fold<int>(0, (int sum, int val) => sum + val);

    if (totalSeconds == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heart Rate Zones',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...zones.entries.map((entry) {
            final percentage = (entry.value / totalSeconds * 100).round();
            final minutes = entry.value ~/ 60;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getZoneName(entry.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '$minutes min ($percentage%)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getZoneColor(entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getZoneName(String zone) {
    switch (zone) {
      case 'zone1':
        return 'Zone 1 (50-60%)';
      case 'zone2':
        return 'Zone 2 (60-70%)';
      case 'zone3':
        return 'Zone 3 (70-80%)';
      case 'zone4':
        return 'Zone 4 (80-90%)';
      case 'zone5':
        return 'Zone 5 (90-100%)';
      default:
        return zone;
    }
  }

  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'zone1':
        return Colors.blue;
      case 'zone2':
        return Colors.green;
      case 'zone3':
        return Colors.yellow[700]!;
      case 'zone4':
        return Colors.orange;
      case 'zone5':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveToHistory,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save to History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _shareAchievement,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.share, color: theme.colorScheme.primary),
            label: Text(
              'Share Achievement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
