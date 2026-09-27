import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      default:
        return web; // Fallback
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBp3lrjZ4p_ca1fwOeUHhMKC7W-p5bCnHs',
    appId: '1:180588105581:web:6e76cf6aeeed195aa65464',
    messagingSenderId: '180588105581',
    projectId: 'winleaf-tea',
    authDomain: 'winleaf-tea.firebaseapp.com',
    storageBucket: 'winleaf-tea.firebasestorage.app',
    measurementId: 'G-CY05YX69MG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCqko5R8-KeA4V5CHehu2BHVQDF6j92qR8',
    appId: '1:180588105581:android:5c81c1ca6cebd8dfa65464',
    messagingSenderId: '180588105581',
    projectId: 'winleaf-tea',
    storageBucket: 'winleaf-tea.firebasestorage.app',
  );
}
