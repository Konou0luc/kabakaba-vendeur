import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web non configuré');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase non configuré pour ${defaultTargetPlatform.runtimeType}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMGHfFELXCulFmGsQtoFtSWrNEd05Ju3g',
    appId: '1:234320774252:android:f1c774010c3a4341f60449',
    messagingSenderId: '234320774252',
    projectId: 'kabakaba-43a55',
    storageBucket: 'kabakaba-43a55.firebasestorage.app',
  );
}
