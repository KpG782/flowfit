import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../models/running_session.dart';
import '../../../providers/running_session_provider.dart';
import '../../../providers/workout_flow_provider.dart';

// ─── Design tokens from spec ───────────────────────────────────────────────
const _kPrimary   = Color(0xFF0A69FF);
const _kBg        = Color(0xFFF5F7FA);
const _kText      = Color(0xFF1F2224);
const _kLabel     = Color(0xFF8A8D90);

// Emotion definitions
const _emotions = [
  _Emotion('Happy',  'happy',  Color(0xFFFFB800)),
  _Emotion('Chill',  'chill',  Color(0xFF22C55E)),
  _Emotion('Hype',   'hype',   Color(0xFFFF5A4E)),
  _Emotion('Focus',  'focus',  Color(0xFF8B5CF6)),
  _Emotion('Sad',    'sad',    Color(0xFF5B8DEF)),
  _Emotion('Angry',  'angry',  Color(0xFFE74C3C)),
];

class _Emotion {
  final String label;
  final String value;
  final Color color;
  const _Emotion(this.label, this.value, this.color);
}

/// Record / Pre-run setup screen — full spec implementation
class RunningSetupScreen extends ConsumerStatefulWidget {
  const RunningSetupScreen({super.key});

  @override
  ConsumerState<RunningSetupScreen> createState() => _RunningSetupScreenState();
}

class _RunningSetupScreenState extends ConsumerState<RunningSetupScreen> {
  // Run type: "quick" = distance goal, "goal" = goal-based with pace target
  String _runType = 'quick';
  bool _isTreadmill = false;
  double _goalPaceMinKm = 6.0; // min/km
  String _selectedEmotion = 'happy';

  // Goal settings
  GoalType _goalType = GoalType.distance;
  double _targetDistance = 5.0;
  int _targetDuration = 30;
  bool _isStarting = false;

  Future<void> _startRunning() async {
    setState(() => _isStarting = true);

    try {
      final workoutFlow = ref.read(workoutFlowProvider);
      final preMood = workoutFlow.preMood;

      await ref.read(runningSessionProvider.notifier).startSession(
        goalType: _runType == 'goal' ? GoalType.distance : _goalType,
        targetDistance: _targetDistance,
        targetDuration: _runType == 'goal' ? null : (_goalType == GoalType.duration ? _targetDuration : null),
        preMood: preMood,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/workout/running/active',
          arguments: {
            'emotion': _selectedEmotion,
            'isTreadmill': _isTreadmill,
            'goalPaceMinKm': _runType == 'goal' ? _goalPaceMinKm : 0.0,
            'runType': _runType,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: SolarIconsOutline.altArrowLeft,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Set Up Run',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kText,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel('Run Type'),
                    const SizedBox(height: 10),
                    _RunTypeSelector(
                      selected: _runType,
                      onChanged: (v) => setState(() => _runType = v),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel('Mode'),
                    const SizedBox(height: 10),
                    _TreadmillToggle(
                      value: _isTreadmill,
                      onChanged: (v) => setState(() => _isTreadmill = v),
                    ),

                    if (_runType == 'goal') ...[
                      const SizedBox(height: 20),
                      _SectionLabel('Goal Pace'),
                      const SizedBox(height: 10),
                      _GoalPaceSelector(
                        paceMinKm: _goalPaceMinKm,
                        onChanged: (v) => setState(() => _goalPaceMinKm = v),
                      ),
                    ],

                    if (_runType == 'quick') ...[
                      const SizedBox(height: 20),
                      _SectionLabel('Target'),
                      const SizedBox(height: 10),
                      _TargetSelector(
                        goalType: _goalType,
                        targetDistance: _targetDistance,
                        targetDuration: _targetDuration,
                        onGoalTypeChanged: (v) => setState(() => _goalType = v),
                        onDistanceChanged: (v) => setState(() => _targetDistance = v),
                        onDurationChanged: (v) => setState(() => _targetDuration = v),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _SectionLabel('How are you feeling?'),
                    const SizedBox(height: 10),
                    _EmotionSelector(
                      selected: _selectedEmotion,
                      onChanged: (v) => setState(() => _selectedEmotion = v),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Start button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isStarting ? null : _startRunning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    disabledBackgroundColor: _kPrimary.withOpacity(0.5),
                  ),
                  child: _isStarting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start Run',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kLabel,
          letterSpacing: 0.5,
        ),
      );
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _kPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _RunTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _RunTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _RunTypeItem(
            label: 'Quick Run',
            subtitle: 'Fast & intense',
            icon: SolarIconsBold.flashCircle,
            value: 'quick',
            selected: selected,
            onTap: () => onChanged('quick'),
          ),
          _RunTypeItem(
            label: 'Goal-Based',
            subtitle: 'Steady & consistent',
            icon: SolarIconsBold.target,
            value: 'goal',
            selected: selected,
            onTap: () => onChanged('goal'),
          ),
        ],
      ),
    );
  }
}

class _RunTypeItem extends StatelessWidget {
  final String label, subtitle, value, selected;
  final IconData icon;
  final VoidCallback onTap;
  const _RunTypeItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF1F2224)),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _kText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : _kLabel,
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
}

class _TreadmillToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TreadmillToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            const Icon(SolarIconsBold.treadmill, size: 22, color: _kPrimary),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Treadmill Mode',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _kText)),
                  Text('Disables GPS tracking',
                      style: TextStyle(fontSize: 12, color: _kLabel)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _kPrimary,
            ),
          ],
        ),
      );
}

class _GoalPaceSelector extends StatelessWidget {
  final double paceMinKm;
  final ValueChanged<double> onChanged;
  const _GoalPaceSelector({required this.paceMinKm, required this.onChanged});

  String _formatPace(double v) {
    final m = v.floor();
    final s = ((v - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(SolarIconsBold.target, size: 20, color: _kPrimary),
                const SizedBox(width: 8),
                const Text('Target Pace',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _kText)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C851).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_formatPace(paceMinKm)} min/km',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF00C851)),
                  ),
                ),
              ],
            ),
            Slider(
              value: paceMinKm,
              min: 3.0,
              max: 12.0,
              divisions: 18,
              activeColor: _kPrimary,
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('3:00', style: TextStyle(fontSize: 11, color: _kLabel)),
                Text('12:00', style: TextStyle(fontSize: 11, color: _kLabel)),
              ],
            ),
          ],
        ),
      );
}

class _TargetSelector extends StatelessWidget {
  final GoalType goalType;
  final double targetDistance;
  final int targetDuration;
  final ValueChanged<GoalType> onGoalTypeChanged;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<int> onDurationChanged;

  const _TargetSelector({
    required this.goalType,
    required this.targetDistance,
    required this.targetDuration,
    required this.onGoalTypeChanged,
    required this.onDistanceChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distance / Duration tabs
            Row(
              children: [
                _TargetTab(
                    label: 'Distance',
                    isSelected: goalType == GoalType.distance,
                    onTap: () => onGoalTypeChanged(GoalType.distance)),
                const SizedBox(width: 8),
                _TargetTab(
                    label: 'Duration',
                    isSelected: goalType == GoalType.duration,
                    onTap: () => onGoalTypeChanged(GoalType.duration)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                goalType == GoalType.distance
                    ? '${targetDistance.toStringAsFixed(1)} km'
                    : '$targetDuration min',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: goalType == GoalType.distance
                  ? targetDistance
                  : targetDuration.toDouble(),
              min: goalType == GoalType.distance ? 1.0 : 5.0,
              max: goalType == GoalType.distance ? 42.0 : 180.0,
              divisions: goalType == GoalType.distance ? 82 : 35,
              activeColor: _kPrimary,
              onChanged: (v) {
                if (goalType == GoalType.distance) {
                  onDistanceChanged(v);
                } else {
                  onDurationChanged(v.round());
                }
              },
            ),
          ],
        ),
      );
}

class _TargetTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TargetTab(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimary : const Color(0xFFF2F3F4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.white : _kText,
            ),
          ),
        ),
      );
}

class _EmotionSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _EmotionSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _emotions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final e = _emotions[i];
            final isSelected = e.value == selected;
            return GestureDetector(
              onTap: () => onChanged(e.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? e.color : const Color(0xFFF2F3F4),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  e.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected ? Colors.white : _kText,
                  ),
                ),
              ),
            );
          },
        ),
      );
}

