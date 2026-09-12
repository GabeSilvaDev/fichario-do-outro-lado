import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCu-z8XGW7I7sZukFpBgVNXUBBZkfLH974',
    appId: '1:484442516229:web:22da29b65a159cc926256c',
    messagingSenderId: '484442516229',
    projectId: 'ordem-paranormal-mesa',
    authDomain: 'ordem-paranormal-mesa.firebaseapp.com',
    storageBucket: 'ordem-paranormal-mesa.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdq60MKPHtz2FQD5NZhPaA0qopPTSGtao',
    appId: '1:484442516229:android:bdcafc50f4e18a4026256c',
    messagingSenderId: '484442516229',
    projectId: 'ordem-paranormal-mesa',
    storageBucket: 'ordem-paranormal-mesa.firebasestorage.app',
  );
}
