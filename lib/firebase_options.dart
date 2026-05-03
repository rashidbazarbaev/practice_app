// ⚠️  ВАЖНО: Этот файл нужно заменить своими данными Firebase!
//
// Как получить этот файл:
// 1. Установите FlutterFire CLI:
//    dart pub global activate flutterfire_cli
//
// 2. Создайте проект на https://console.firebase.google.com
//    - Включите Authentication → Email/Password и Google
//    - Создайте Firestore Database (режим test для разработки)
//
// 3. Запустите в папке проекта:
//    flutterfire configure
//
// Команда автоматически создаст этот файл с вашими данными.
//
// ─────────────────────────────────────────────────────────────────────────────
// Временная заглушка для компиляции без Firebase:

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAaFE2g2iv2wqEM4taIqIGWeP8j0rV5pGk',
    appId: '1:463972160093:android:bfde1337e5d3bff279b3b4',
    messagingSenderId: '463972160093',
    projectId: 'bazarbaev-kasymov',
    storageBucket: 'bazarbaev-kasymov.firebasestorage.app',
  );

  // ⚠️ Замените эти значения своими из Firebase Console!

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCn40GjuDwoYHnmUB2igfTgbWgWFGdhYJc',
    appId: '1:463972160093:ios:abfe43b0f6a1d8b479b3b4',
    messagingSenderId: '463972160093',
    projectId: 'bazarbaev-kasymov',
    storageBucket: 'bazarbaev-kasymov.firebasestorage.app',
    iosBundleId: 'com.example.practiceUniversity',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    authDomain: 'your-project-id.firebaseapp.com',
  );
}