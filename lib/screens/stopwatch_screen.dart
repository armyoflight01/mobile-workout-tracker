import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/firebase_service.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  String _selectedMode = 'Run'; // 'Run' or 'Gym'
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _milliseconds = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _milliseconds = _stopwatch.elapsedMilliseconds;
        });
      }
    });
  }

  void _pauseTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _resetTimer() {
    _stopwatch.reset();
    _timer?.cancel();
    setState(() {
      _milliseconds = 0;
    });
  }

  // Calories estimation formula
  // Run MET: ~9.8 (~11.5 kcal/min for 70kg person)
  // Gym MET: ~6.0 (~7.0 kcal/min for 70kg person)
  double get _estimatedCalories {
    final minutes = _milliseconds / 60000.0;
    if (_selectedMode == 'Run') {
      return minutes * 11.5;
    } else {
      return minutes * 7.0;
    }
  }

  String _formatTime(int ms) {
    final hundreds = (ms ~/ 100) % 10;
    final seconds = (ms ~/ 1000) % 60;
    final minutes = (ms ~/ (1000 * 60)) % 60;
    final hours = (ms ~/ (1000 * 60 * 60));

    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hoursStr:$minutesStr:$secondsStr.$hundreds';
    }
    return '$minutesStr:$secondsStr.$hundreds';
  }

  Future<void> _saveWorkout() async {
    final durationSec = _milliseconds ~/ 1000;
    if (durationSec < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercise session too short to record (must be at least 5 seconds).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final service = FirebaseService();
    final log = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: service.userId,
      mode: _selectedMode,
      durationSeconds: durationSec,
      caloriesBurned: double.parse(_estimatedCalories.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    );

    final success = await service.saveWorkout(log);
    if (!mounted) return;
    setState(() => _isSaving = false);

    _resetTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success
                    ? 'Saved $_selectedMode workout (${log.formattedDuration}, ${log.caloriesBurned} kcal) to database!'
                    : 'Saved locally in workout history!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = _stopwatch.isRunning;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Selector: Run vs Gym
          Text(
            'Choose Exercise Mode',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'Run',
                label: Text('Run (Cardio)'),
                icon: Icon(Icons.directions_run_rounded),
              ),
              ButtonSegment<String>(
                value: 'Gym',
                label: Text('Gym (Workout)'),
                icon: Icon(Icons.fitness_center_rounded),
              ),
            ],
            selected: {_selectedMode},
            onSelectionChanged: (Set<String> newSelection) {
              if (!isRunning) {
                setState(() => _selectedMode = newSelection.first);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pause or reset stopwatch to switch mode.')),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Stopwatch Display Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: _selectedMode == 'Run'
                      ? [Colors.blue.shade900, Colors.blue.shade700]
                      : [Colors.deepOrange.shade900, Colors.deepOrange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedMode == 'Run' ? Icons.directions_run : Icons.fitness_center,
                        color: Colors.white70,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_selectedMode Stopwatch',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatTime(_milliseconds),
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${_estimatedCalories.toStringAsFixed(1)} kcal burned',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button
              IconButton.filledTonal(
                onPressed: _milliseconds > 0 ? _resetTimer : null,
                iconSize: 32,
                padding: const EdgeInsets.all(16),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reset',
              ),
              const SizedBox(width: 20),

              // Play / Pause Button
              IconButton.filled(
                onPressed: isRunning ? _pauseTimer : _startTimer,
                iconSize: 44,
                padding: const EdgeInsets.all(20),
                icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                tooltip: isRunning ? 'Pause' : 'Start',
              ),
              const SizedBox(width: 20),

              // Save to Database Button
              IconButton.filledTonal(
                onPressed: (_milliseconds > 0 && !_isSaving) ? _saveWorkout : null,
                iconSize: 32,
                padding: const EdgeInsets.all(16),
                icon: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                tooltip: 'Save to Database',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isRunning
                ? 'Stopwatch is running...'
                : (_milliseconds > 0
                    ? 'Paused. Click cloud icon to save to database.'
                    : 'Tap Play to start exercise timer.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 32),

          // Quick Recent Workouts Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Workouts',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Auto-synced with Database',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: FirebaseService(),
            builder: (context, _) {
              final workouts = FirebaseService().localWorkouts;
              if (workouts.isEmpty) {
                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No workouts recorded yet. Start exercising above!'),
                    ),
                  ),
                );
              }
              return Column(
                children: workouts.take(4).map((w) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: w.mode == 'Run'
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        child: Icon(
                          w.mode == 'Run' ? Icons.directions_run : Icons.fitness_center,
                          color: w.mode == 'Run' ? Colors.blue.shade800 : Colors.deepOrange.shade800,
                        ),
                      ),
                      title: Text(
                        '${w.mode} Session',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${w.formattedDuration} • ${w.timestamp.month}/${w.timestamp.day} ${w.timestamp.hour.toString().padLeft(2, '0')}:${w.timestamp.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Text(
                        '${w.caloriesBurned} kcal',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
