class WorkoutLog {
  final String id;
  final String userId;
  final String mode; // 'Run' or 'Gym'
  final int durationSeconds;
  final double caloriesBurned;
  final DateTime timestamp;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.mode,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.timestamp,
  });

  String get formattedDuration {
    final hours = (durationSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((durationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    if (durationSeconds >= 3600) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mode': mode,
      'durationSeconds': durationSeconds,
      'caloriesBurned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WorkoutLog.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutLog(
      id: id,
      userId: map['userId'] as String? ?? 'guest',
      mode: map['mode'] as String? ?? 'Run',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
