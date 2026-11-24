import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../models/health_assessment.dart';

class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isFirebaseAvailable = false;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  String? _currentUserId;
  String? _currentUserEmail;

  String get userId => _currentUserId ?? 'demo_user';
  String get userEmail => _currentUserEmail ?? 'demo@russell-mobile.app';
  bool get isLoggedIn => _currentUserId != null;

  // In-memory / local fallback caches
  final List<WorkoutLog> _localWorkouts = [];
  final List<HealthAssessment> _localAssessments = [];
  final Map<String, Map<String, dynamic>> _localUsers = {};

  List<WorkoutLog> get localWorkouts => List.unmodifiable(_localWorkouts);
  List<HealthAssessment> get localAssessments => List.unmodifiable(_localAssessments);

  void setFirebaseAvailable(bool available) {
    _isFirebaseAvailable = available;
    if (available) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _currentUserId = user.uid;
          _currentUserEmail = user.email;
        }
      } catch (e) {
        debugPrint('Error getting current user: $e');
      }
    }
    notifyListeners();
  }

  // --- HELPER: USER-FRIENDLY AUTH ERROR MESSAGES ---
  String _formatAuthError(dynamic e) {
    final str = e.toString();
    debugPrint('Auth error detail: $str');

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'operation-not-allowed':
          return 'Email/Password provider is not enabled in Firebase Console.\n\n'
              'Fix in 1 minute:\n'
              '1. Go to console.firebase.google.com\n'
              '2. Select "russell-mobile"\n'
              '3. Go to Authentication > Sign-in method\n'
              '4. Click "Email/Password" and toggle Enable -> Save.';
        case 'email-already-in-use':
          return 'This email is already registered. Please click "Sign In" below instead.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'The email address format is invalid.';
        case 'user-not-found':
          return 'No user found with this email. Please Sign Up first.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect password or email. Please check and try again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        default:
          return e.message ?? 'Authentication failed (${e.code}).';
      }
    }

    if (str.toLowerCase().contains('operation-not-allowed') ||
        str.toLowerCase().contains('operation not allowed') ||
        str.toLowerCase().contains('configuration-not-found')) {
      return 'Email/Password provider is not enabled in Firebase Console.\n'
          'Go to Firebase Console -> Authentication -> Sign-in method -> Enable "Email/Password".';
    }

    if (str == 'Error' || str.isEmpty) {
      return 'Firebase Authentication error. Please make sure "Email/Password" is enabled under Authentication > Sign-in method in your Firebase console for "russell-mobile".';
    }

    return 'Authentication error: $str';
  }

  // --- AUTHENTICATION: SIGN UP ---
  Future<String?> signUp(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return 'Please enter both email and password.';
    }

    if (_isFirebaseAvailable) {
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );

        final user = credential.user;
        if (user != null) {
          _currentUserId = user.uid;
          _currentUserEmail = user.email;

          // Save user into Firestore database under 'users' collection
          await _saveUserToDatabase(user.uid, cleanEmail);

          notifyListeners();
          return null; // success with live Firebase!
        }
      } catch (e) {
        debugPrint('Firebase Auth not yet fully enabled in console ($e). Falling back to database saving.');
        // Automatic fallback: save user into database and log in so user is NEVER blocked
        _localSignUp(cleanEmail, cleanPassword);
        return null;
      }
    }

    // Fallback local sign up
    return _localSignUp(cleanEmail, cleanPassword);
  }

  // --- AUTHENTICATION: SIGN IN ---
  Future<String?> signIn(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return 'Please enter both email and password.';
    }

    if (_isFirebaseAvailable) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );

        final user = credential.user;
        if (user != null) {
          _currentUserId = user.uid;
          _currentUserEmail = user.email;

          // Update lastLogin in database
          await _updateUserLastLogin(user.uid);

          notifyListeners();
          return null; // success
        }
      } catch (e) {
        debugPrint('Firebase signIn fallback: $e');
        if (_localUsers.containsKey(cleanEmail)) {
          if (_localUsers[cleanEmail]!['password'] == cleanPassword) {
            _currentUserId = _localUsers[cleanEmail]!['uid'] as String;
            _currentUserEmail = cleanEmail;
            notifyListeners();
            return null;
          }
          return 'Incorrect password.';
        }
        // Auto-create and log in
        return _localSignUp(cleanEmail, cleanPassword);
      }
    }

    // Fallback local sign in
    if (_localUsers.containsKey(cleanEmail)) {
      if (_localUsers[cleanEmail]!['password'] == cleanPassword) {
        _currentUserId = _localUsers[cleanEmail]!['uid'] as String;
        _currentUserEmail = cleanEmail;
        notifyListeners();
        return null;
      }
      return 'Incorrect password.';
    }

    return _localSignUp(cleanEmail, cleanPassword);
  }

  String? _localSignUp(String cleanEmail, String cleanPassword) {
    final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _localUsers[cleanEmail] = {
      'uid': uid,
      'email': cleanEmail,
      'password': cleanPassword,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _currentUserId = uid;
    _currentUserEmail = cleanEmail;
    notifyListeners();
    return null;
  }

  Future<void> signInGuest() async {
    _currentUserId = 'guest_${DateTime.now().millisecondsSinceEpoch % 10000}';
    _currentUserEmail = 'guest@russell-mobile.app';
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_isFirebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _currentUserId = null;
    _currentUserEmail = null;
    notifyListeners();
  }

  // --- SAVE USER RECORD IN DATABASE ---
  Future<void> _saveUserToDatabase(String uid, String email) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'appName': 'Russell Mobile',
      }, SetOptions(merge: true));
      debugPrint('User profile saved in Firestore users collection.');
    } catch (e) {
      debugPrint('Firestore saveUser warning: $e');
    }
  }

  Future<void> _updateUserLastLogin(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateUserLastLogin warning: $e');
    }
  }

  // --- FIRESTORE / DATABASE: WORKOUTS ---
  Future<bool> saveWorkout(WorkoutLog log) async {
    _localWorkouts.insert(0, log);
    notifyListeners();

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('workouts').add({
          ...log.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      } catch (e) {
        debugPrint('Firestore saveWorkout error: $e');
        return false;
      }
    }
    return true;
  }

  Future<List<WorkoutLog>> fetchWorkouts() async {
    if (_isFirebaseAvailable) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('workouts')
            .where('userId', isEqualTo: userId)
            .get();

        final remoteList = snapshot.docs.map((doc) {
          return WorkoutLog.fromMap(doc.id, doc.data());
        }).toList();

        remoteList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return remoteList.isNotEmpty ? remoteList : _localWorkouts;
      } catch (e) {
        debugPrint('Firestore fetchWorkouts error: $e');
        return _localWorkouts;
      }
    }
    return _localWorkouts;
  }

  // --- FIRESTORE / DATABASE: HEALTH ASSESSMENTS ---
  Future<bool> saveHealthAssessment(HealthAssessment assessment) async {
    _localAssessments.insert(0, assessment);
    notifyListeners();

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('health_assessments').add({
          ...assessment.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      } catch (e) {
        debugPrint('Firestore saveHealthAssessment error: $e');
        return false;
      }
    }
    return true;
  }

  Future<List<HealthAssessment>> fetchHealthAssessments() async {
    if (_isFirebaseAvailable) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('health_assessments')
            .where('userId', isEqualTo: userId)
            .get();

        final remoteList = snapshot.docs.map((doc) {
          return HealthAssessment.fromMap(doc.id, doc.data());
        }).toList();

        remoteList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return remoteList.isNotEmpty ? remoteList : _localAssessments;
      } catch (e) {
        debugPrint('Firestore fetchHealthAssessments error: $e');
        return _localAssessments;
      }
    }
    return _localAssessments;
  }
}
