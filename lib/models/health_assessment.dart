class HealthAssessment {
  final String id;
  final String userId;
  final double weightKg;
  final double heightCm;
  final int age;
  final String gender; // 'Male' or 'Female'
  final double bmi;
  final String category; // 'Thin / Underweight', 'Normal', 'Overweight', 'Obesity'
  final double maintenanceCalories;
  final double targetDeficitCalories;
  final DateTime timestamp;

  HealthAssessment({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.bmi,
    required this.category,
    required this.maintenanceCalories,
    required this.targetDeficitCalories,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'age': age,
      'gender': gender,
      'bmi': bmi,
      'category': category,
      'maintenanceCalories': maintenanceCalories,
      'targetDeficitCalories': targetDeficitCalories,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HealthAssessment.fromMap(String id, Map<String, dynamic> map) {
    return HealthAssessment(
      id: id,
      userId: map['userId'] as String? ?? 'guest',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0.0,
      age: (map['age'] as num?)?.toInt() ?? 25,
      gender: map['gender'] as String? ?? 'Male',
      bmi: (map['bmi'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Normal',
      maintenanceCalories: (map['maintenanceCalories'] as num?)?.toDouble() ?? 2000.0,
      targetDeficitCalories: (map['targetDeficitCalories'] as num?)?.toDouble() ?? 1500.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
