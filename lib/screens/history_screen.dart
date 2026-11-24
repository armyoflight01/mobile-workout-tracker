import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/health_assessment.dart';
import '../services/firebase_service.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const HistoryScreen({super.key, required this.onSignOut});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<WorkoutLog> _workouts = [];
  List<HealthAssessment> _assessments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final service = FirebaseService();
    final w = await service.fetchWorkouts();
    final a = await service.fetchHealthAssessments();
    if (!mounted) return;
    setState(() {
      _workouts = w;
      _assessments = a;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = FirebaseService();

    return Column(
      children: [
        // User Profile & Status Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.userEmail,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          service.isFirebaseAvailable ? Icons.check_circle : Icons.storage_rounded,
                          size: 14,
                          color: service.isFirebaseAvailable ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.isFirebaseAvailable
                              ? 'Connected to Firebase Firestore'
                              : 'Local DB (Synced upon login)',
                          style: TextStyle(
                            fontSize: 12,
                            color: service.isFirebaseAvailable ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: () async {
                  await service.signOut();
                  widget.onSignOut();
                },
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'BMI & Calorie Deficit'),
          ],
        ),

        // Tab Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Workouts List
                      _buildWorkoutsList(),
                      // Assessments List
                      _buildAssessmentsList(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWorkoutsList() {
    if (_workouts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(Icons.timer_off_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No workouts saved in database yet.'),
                SizedBox(height: 4),
                Text('Use the Stopwatch to record Run or Gym exercises!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final w = _workouts[index];
        final isRun = w.mode == 'Run';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isRun ? Colors.blue.withValues(alpha: 0.2) : Colors.deepOrange.withValues(alpha: 0.2),
              child: Icon(
                isRun ? Icons.directions_run : Icons.fitness_center,
                color: isRun ? Colors.blue.shade800 : Colors.deepOrange.shade800,
              ),
            ),
            title: Text(
              '${w.mode} Exercise',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Duration: ${w.formattedDuration}\nDate: ${w.timestamp.year}-${w.timestamp.month.toString().padLeft(2, '0')}-${w.timestamp.day.toString().padLeft(2, '0')} ${w.timestamp.hour.toString().padLeft(2, '0')}:${w.timestamp.minute.toString().padLeft(2, '0')}',
            ),
            isThreeLine: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${w.caloriesBurned} kcal',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssessmentsList() {
    if (_assessments.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No assessments saved in database yet.'),
                SizedBox(height: 4),
                Text('Use the Calculator tab to assess BMI & Deficit!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final a = _assessments[index];
        Color catColor = Colors.green;
        if (a.category.contains('Thin')) catColor = Colors.lightBlue.shade700;
        if (a.category.contains('Overweight')) catColor = Colors.orange.shade800;
        if (a.category.contains('Obesity')) catColor = Colors.red.shade700;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: catColor),
                      ),
                      child: Text(
                        a.category,
                        style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${a.timestamp.month}/${a.timestamp.day} ${a.timestamp.hour.toString().padLeft(2, '0')}:${a.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weight: ${a.weightKg} kg (${a.heightCm} cm)', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('BMI: ${a.bmi}', style: TextStyle(fontWeight: FontWeight.bold, color: catColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TDEE: ${a.maintenanceCalories.toInt()} kcal', style: TextStyle(color: Colors.grey.shade700)),
                    Text(
                      'Deficit Target: ${a.targetDeficitCalories.toInt()} kcal/day',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
