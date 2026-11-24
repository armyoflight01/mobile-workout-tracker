import 'package:flutter/material.dart';
import '../models/health_assessment.dart';
import '../services/firebase_service.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '175');
  final _ageController = TextEditingController(text: '25');

  String _gender = 'Male';
  double _activityMultiplier = 1.375; // Lightly active
  int _deficitAmount = 500; // -500 kcal/day

  double? _bmi;
  String? _category;
  Color? _categoryColor;
  double? _maintenanceCalories;
  double? _targetDeficitCalories;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);

    if (weight == null || height == null || age == null || height <= 0 || weight <= 0) {
      return;
    }

    // BMI calculation: weight (kg) / (height (m) ^ 2)
    final heightMeters = height / 100.0;
    final bmiVal = weight / (heightMeters * heightMeters);

    String cat;
    Color color;
    if (bmiVal < 18.5) {
      cat = 'Thin / Underweight';
      color = Colors.lightBlue.shade700;
    } else if (bmiVal < 25.0) {
      cat = 'Normal Weight';
      color = Colors.green.shade700;
    } else if (bmiVal < 30.0) {
      cat = 'Overweight';
      color = Colors.orange.shade800;
    } else {
      cat = 'Obesity';
      color = Colors.red.shade700;
    }

    // BMR Mifflin-St Jeor formula
    double bmr;
    if (_gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    final tdee = bmr * _activityMultiplier;
    final target = (tdee - _deficitAmount).clamp(1200.0, 5000.0);

    setState(() {
      _bmi = bmiVal;
      _category = cat;
      _categoryColor = color;
      _maintenanceCalories = tdee;
      _targetDeficitCalories = target;
    });
  }

  Future<void> _saveAssessment() async {
    if (_bmi == null || _category == null || _maintenanceCalories == null || _targetDeficitCalories == null) {
      return;
    }

    setState(() => _isSaving = true);
    final service = FirebaseService();
    final assessment = HealthAssessment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: service.userId,
      weightKg: double.parse(_weightController.text),
      heightCm: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      gender: _gender,
      bmi: double.parse(_bmi!.toStringAsFixed(1)),
      category: _category!,
      maintenanceCalories: double.parse(_maintenanceCalories!.toStringAsFixed(0)),
      targetDeficitCalories: double.parse(_targetDeficitCalories!.toStringAsFixed(0)),
      timestamp: DateTime.now(),
    );

    final success = await service.saveHealthAssessment(assessment);
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success
                    ? 'Saved assessment (${assessment.category}, Deficit: ${assessment.targetDeficitCalories.toInt()} kcal) to database!'
                    : 'Saved assessment locally in history!',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Body Weight & Calorie Deficit Calculator',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Calculates BMI category (Thin, Normal, Obesity) and your daily calorie deficit target.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Inputs Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Weight in Kilograms
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              suffixText: 'kg',
                              prefixIcon: Icon(Icons.monitor_weight_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Height in Centimeters
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              suffixText: 'cm',
                              prefixIcon: Icon(Icons.height),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Age
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age (years)',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Gender
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _gender = val);
                                _calculate();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Activity Level
                    DropdownButtonFormField<double>(
                      value: _activityMultiplier,
                      decoration: const InputDecoration(
                        labelText: 'Daily Activity Level',
                        prefixIcon: Icon(Icons.directions_walk_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1.2, child: Text('Sedentary (Little or no exercise)')),
                        DropdownMenuItem(value: 1.375, child: Text('Light (Exercise 1-3 days/week)')),
                        DropdownMenuItem(value: 1.55, child: Text('Moderate (Exercise 3-5 days/week)')),
                        DropdownMenuItem(value: 1.725, child: Text('Very Active (Hard exercise 6-7 days/week)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _activityMultiplier = val);
                          _calculate();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    // Deficit Level
                    DropdownButtonFormField<int>(
                      value: _deficitAmount,
                      decoration: const InputDecoration(
                        labelText: 'Target Deficit Goal',
                        prefixIcon: Icon(Icons.trending_down_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 300, child: Text('Mild Deficit (-300 kcal/day)')),
                        DropdownMenuItem(value: 500, child: Text('Standard Fat Loss (-500 kcal/day, ~0.5kg/wk)')),
                        DropdownMenuItem(value: 700, child: Text('Aggressive Deficit (-700 kcal/day)')),
                        DropdownMenuItem(value: 0, child: Text('Maintain Weight (0 deficit)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _deficitAmount = val);
                          _calculate();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Results Card
            if (_bmi != null) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Status Classification Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: (_categoryColor ?? Colors.blue).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _categoryColor ?? Colors.blue, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.health_and_safety_rounded, color: _categoryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Category: $_category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics Grid
                      Row(
                        children: [
                          Expanded(
                            child: _metricBox(
                              title: 'Body Mass Index (BMI)',
                              value: _bmi!.toStringAsFixed(1),
                              subtitle: _bmiCategoryTip(_bmi!),
                              color: _categoryColor ?? Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricBox(
                              title: 'Target Calories',
                              value: '${_targetDeficitCalories!.toInt()} kcal',
                              subtitle: 'Per Day for Deficit',
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _metricBox(
                              title: 'Maintenance Calories',
                              value: '${_maintenanceCalories!.toInt()} kcal',
                              subtitle: 'TDEE to maintain weight',
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricBox(
                              title: 'Daily Deficit Cut',
                              value: '-$_deficitAmount kcal',
                              subtitle: 'Energy deficit/day',
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveAssessment,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: const Text(
                          'Save Assessment to Database',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _bmiCategoryTip(double bmi) {
    if (bmi < 18.5) return 'Thin (< 18.5)';
    if (bmi < 25.0) return 'Healthy Normal (18.5-24.9)';
    if (bmi < 30.0) return 'Overweight (25-29.9)';
    return 'Obesity (≥ 30)';
  }

  Widget _metricBox({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
