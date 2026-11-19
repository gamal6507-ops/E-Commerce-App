import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      _ =>
        throw UnsupportedError(
          'This platform needs its own Firebase app registration',
        ),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAwWnyZ7OireyRT-eyOKlD3iwJGSXylGnE',
    appId: '1:1076199940056:web:c036cb16ebf44edab1dcad',
    messagingSenderId: '1076199940056',
    projectId: 'verve-store-gamal6507',
    storageBucket: 'verve-store-gamal6507.firebasestorage.app',
    authDomain: 'verve-store-gamal6507.firebaseapp.com',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAaOeNV_YyEJmn1DCc4Q-3EqBeEzA7wLuc',
    appId: '1:1076199940056:android:8acc0d60c388472fb1dcad',
    messagingSenderId: '1076199940056',
    projectId: 'verve-store-gamal6507',
    storageBucket: 'verve-store-gamal6507.firebasestorage.app',
  );
  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCYEM19-F1cTAPwH2iGi7PsrwK7ZqYL-i4',
    appId: '1:1076199940056:ios:5619fb939f72ccf3b1dcad',
    messagingSenderId: '1076199940056',
    projectId: 'verve-store-gamal6507',
    storageBucket: 'verve-store-gamal6507.firebasestorage.app',
    iosBundleId: 'com.example.eCommercApp',
  );
}
