import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'stopwatch_screen.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const HomeScreen({super.key, required this.onSignOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = FirebaseService();

    final screens = [
      const StopwatchScreen(),
      const CalculatorScreen(),
      HistoryScreen(onSignOut: widget.onSignOut),
    ];

    final titles = [
      'Stopwatch (Run & Gym)',
      'Calorie Deficit Calculator',
      'Database & Records',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Russell Mobile',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              titles[_currentIndex],
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          // Firebase connection status chip in app bar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: service.isFirebaseAvailable
                  ? 'Connected to Firebase (russell-mobile)'
                  : 'Running locally. Configure Firebase credentials to sync.',
              child: Chip(
                avatar: Icon(
                  service.isFirebaseAvailable ? Icons.cloud_done : Icons.cloud_queue,
                  size: 16,
                  color: service.isFirebaseAvailable ? Colors.green.shade800 : Colors.orange.shade800,
                ),
                label: Text(
                  service.isFirebaseAvailable ? 'Firebase' : 'Local DB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: service.isFirebaseAvailable ? Colors.green.shade900 : Colors.orange.shade900,
                  ),
                ),
                backgroundColor: service.isFirebaseAvailable
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Stopwatch',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Deficit / BMI',
          ),
          NavigationDestination(
            icon: Icon(Icons.storage_outlined),
            selectedIcon: Icon(Icons.storage),
            label: 'Database',
          ),
        ],
      ),
    );
  }
}
