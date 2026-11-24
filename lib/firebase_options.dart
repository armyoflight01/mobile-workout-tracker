import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'PASTE_YOUR_API_KEY',
      appId: 'PASTE_YOUR_APP_ID',
      messagingSenderId: 'PASTE_YOUR_MESSAGING_SENDER_ID',
      projectId: 'russell-mobile',
      authDomain: 'russell-mobile.firebaseapp.com',
      storageBucket: 'russell-mobile.firebasestorage.app',
    );
  }
}