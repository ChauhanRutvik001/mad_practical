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
      case TargetPlatform.macOS:
        return macos;
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
          'DefaultFirebaseOptions have not been configured for $defaultTargetPlatform - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8SrTTByiZ2MUfHvPRfSOzzlcfAyim1Fw',
    appId: '1:761045487891:android:75265432a3286f33720ae6',
    messagingSenderId: '761045487891',
    projectId: 'airbnb-app-b0e9e',
    authDomain: 'airbnb-app-b0e9e.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8SrTTByiZ2MUfHvPRfSOzzlcfAyim1Fw',
    appId: '1:761045487891:android:75265432a3286f33720ae6',
    messagingSenderId: '761045487891',
    projectId: 'airbnb-app-b0e9e',
    storageBucket: 'airbnb-app-b0e9e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA8SrTTByiZ2MUfHvPRfSOzzlcfAyim1Fw',
    appId: '1:761045487891:android:75265432a3286f33720ae6',
    messagingSenderId: '761045487891',
    projectId: 'airbnb-app-b0e9e',
    storageBucket: 'airbnb-app-b0e9e.appspot.com',
    iosClientId: '761045487891-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',
    iosBundleId: 'com.example.airbnbApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA8SrTTByiZ2MUfHvPRfSOzzlcfAyim1Fw',
    appId: '1:761045487891:android:75265432a3286f33720ae6',
    messagingSenderId: '761045487891',
    projectId: 'airbnb-app-b0e9e',
    storageBucket: 'airbnb-app-b0e9e.appspot.com',
    iosClientId: '761045487891-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',
    iosBundleId: 'com.example.airbnbApp',
  );
} 