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
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZRpoSD_-7-VqkVdOmumpX1ygsu9hngM4',
    appId: '1:660937143367:android:a2f0617b74beef3271ed62',
    messagingSenderId: '660937143367',
    projectId: 'freselama-sunday-school',
    storageBucket: 'freselama-sunday-school.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJpraiAno2RfPT-aGzGg-Zalqfdg8Ei9g',
    appId: '1:660937143367:ios:810e90ac808e169271ed62',
    messagingSenderId: '660937143367',
    projectId: 'freselama-sunday-school',
    storageBucket: 'freselama-sunday-school.firebasestorage.app',
    iosBundleId: 'com.example.flutterSample',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCnpYGv9jypglL2TjkSzuljVcDOxDma-Mk',
    appId: '1:660937143367:web:c8465b3eafc3e77071ed62',
    messagingSenderId: '660937143367',
    projectId: 'freselama-sunday-school',
    authDomain: 'freselama-sunday-school.firebaseapp.com',
    storageBucket: 'freselama-sunday-school.firebasestorage.app',
    measurementId: 'G-THGG4Q2SDJ',
  );
}
