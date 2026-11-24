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

  // In-memory fallback caches
  final List<WorkoutLog> _localWorkouts = [];
  final List<HealthAssessment> _localAssessments = [];

  List<WorkoutLog> get localWorkouts => List.unmodifiable(_localWorkouts);
  List<HealthAssessment> get localAssessments => List.unmodifiable(_localAssessments);

  void setFirebaseAvailable(bool available) {
    _isFirebaseAvailable = available;
    if (available) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        _currentUserEmail = user.email;
      }
    }
    notifyListeners();
  }

  // --- AUTHENTICATION ---
  Future<String?> signUp(String email, String password) async {
    if (_isFirebaseAvailable) {
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        _currentUserId = credential.user?.uid;
        _currentUserEmail = credential.user?.email;
        notifyListeners();
        return null; // success
      } on FirebaseAuthException catch (e) {
        return e.message ?? 'Sign up failed';
      } catch (e) {
        return e.toString();
      }
    } else {
      // Local fallback mode
      _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _currentUserEmail = email.trim();
      notifyListeners();
      return null;
    }
  }

  Future<String?> signIn(String email, String password) async {
    if (_isFirebaseAvailable) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        _currentUserId = credential.user?.uid;
        _currentUserEmail = credential.user?.email;
        notifyListeners();
        return null; // success
      } on FirebaseAuthException catch (e) {
        return e.message ?? 'Sign in failed';
      } catch (e) {
        return e.toString();
      }
    } else {
      // Local fallback mode
      _currentUserId = 'user_demo';
      _currentUserEmail = email.trim();
      notifyListeners();
      return null;
    }
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

        // Sort descending
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
