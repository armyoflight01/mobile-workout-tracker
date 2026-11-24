import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe Firebase initialization
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey != 'PASTE_YOUR_API_KEY') {
      await Firebase.initializeApp(options: options);
      FirebaseService().setFirebaseAvailable(true);
    } else {
      debugPrint('Firebase options contain placeholder keys. Running in offline/demo mode.');
      FirebaseService().setFirebaseAvailable(false);
    }
  } catch (e) {
    debugPrint('Firebase initializeApp caught: $e');
    FirebaseService().setFirebaseAvailable(false);
  }

  runApp(const RussellMobileApp());
}

class RussellMobileApp extends StatefulWidget {
  const RussellMobileApp({super.key});

  @override
  State<RussellMobileApp> createState() => _RussellMobileAppState();
}

class _RussellMobileAppState extends State<RussellMobileApp> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _firebaseService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _firebaseService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Russell Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Sporty Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: _firebaseService.isLoggedIn
          ? HomeScreen(onSignOut: () => setState(() {}))
          : AuthScreen(onAuthenticated: () => setState(() {})),
    );
  }
}
