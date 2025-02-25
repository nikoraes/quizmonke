// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDRv_ac0eAZm7a6OONr2MZHohFCRAw3J4w',
    appId: '1:232118707051:web:b8cd7d6a115fd08e7aa22e',
    messagingSenderId: '232118707051',
    projectId: 'schoolscan-4c8d8',
    authDomain: 'schoolscan-4c8d8.firebaseapp.com',
    storageBucket: 'schoolscan-4c8d8.appspot.com',
    measurementId: 'G-QM81SFHWWY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDd7qzOMItFNRhqXtb0kvR6eRCRgh8THJE',
    appId: '1:232118707051:android:81e87b1e525bd48e7aa22e',
    messagingSenderId: '232118707051',
    projectId: 'schoolscan-4c8d8',
    storageBucket: 'schoolscan-4c8d8.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBjITqNBVZWRZQfI3GkQ8flWFakWIgHYO8',
    appId: '1:232118707051:ios:9ec54cf336f489317aa22e',
    messagingSenderId: '232118707051',
    projectId: 'schoolscan-4c8d8',
    storageBucket: 'schoolscan-4c8d8.appspot.com',
    androidClientId: '232118707051-796atbm9s2oq60b7pskb7dmqtjno8kf8.apps.googleusercontent.com',
    iosClientId: '232118707051-2drv8ehlpcadhv1dsthcjvfav2mv0k6v.apps.googleusercontent.com',
    iosBundleId: 'com.raes.quizmonke',
  );
}
