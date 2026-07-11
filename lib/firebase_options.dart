import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('This platform is not configured.');
    }
  }

  // 1. YOUR REAL WEB CONFIGURATION KEYS
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDl53-L7PkFAq17rFdPB1S1x8-yTixT7IQ', // Hand-copied from your screen!
    appId: '1:1234567890:web:androidBypassAppId', // Standard setup fallback string
    messagingSenderId: '1234567890',
    projectId: 'wanderlog-713d3',
    authDomain: 'wanderlog-713d3.firebaseapp.com',
    storageBucket: 'wanderlog-713d3.appspot.com',
  );

  // 2. YOUR ANDROID CONFIGURATION KEYS
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDl53-L7PkFAq17rFdPB1S1x8-yTixT7IQ', // Uses the same unified master API key
    appId: '1:1234567890:android:androidBypassAppId',
    messagingSenderId: '1234567890',
    projectId: 'wanderlog-713d3',
    storageBucket: 'wanderlog-713d3.appspot.com',
  );
}


// import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

// class DefaultFirebaseOptions {
//   static FirebaseOptions get currentPlatform {
//     if (kIsWeb) {
//       return web;
//     }
//     switch (defaultTargetPlatform) {
//       case TargetPlatform.android:
//         return android;
//       case TargetPlatform.iOS:
//         return ios;
//       default:
//         return web; // Fallback to web configuration
//     }
//   }

//   static const FirebaseOptions web = FirebaseOptions(
//     apiKey: 'AIzaSyFakeKey_BypassTerminalError_WanderLog_Web',
//     appId: '1:1234567890:web:1234567890',
//     messagingSenderId: '1234567890',
//     projectId: 'wanderlog-713d3',
//     authDomain: 'wanderlog-713d3.firebaseapp.com',
//     storageBucket: 'wanderlog-713d3.appspot.com',
//   );

//   static const FirebaseOptions android = FirebaseOptions(
//     apiKey: 'AIzaSyFakeKey_BypassTerminalError_WanderLog',
//     appId: '1:1234567890:android:1234567890',
//     messagingSenderId: '1234567890',
//     projectId: 'wanderlog-713d3',
//     storageBucket: 'wanderlog-713d3.appspot.com',
//   );

//   static const FirebaseOptions ios = FirebaseOptions(
//     apiKey: 'AIzaSyFakeKey_BypassTerminalError_WanderLog_iOS',
//     appId: '1:1234567890:ios:1234567890',
//     messagingSenderId: '1234567890',
//     projectId: 'wanderlog-713d3',
//     storageBucket: 'wanderlog-713d3.appspot.com',
//     iosBundleId: 'com.example.wanderLog',
//   );
// }