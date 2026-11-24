import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBGgsVoPa7ne86-zYaD_RswE0Qsrc8vj1Q',
      appId: '1:680905115110:web:ad039d85fa9b610d8b8227',
      messagingSenderId: '680905115110',
      projectId: 'russell-mobile',
      authDomain: 'russell-mobile.firebaseapp.com',
      storageBucket: 'russell-mobile.firebasestorage.app',
    );
  }
}