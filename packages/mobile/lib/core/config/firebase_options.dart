// Config for the `balance-forward-dev` Firebase project (bundle/package id
// com.balanceforward.app.{ios,android} — the org-unbranded convention shared
// with vehicle-vitals/wishlist-wizard, not com.nelsongrey.*). The project ID
// is permanent once created. Web and macOS remain
// unconfigured — packages/web (React) is the web client, and macOS isn't a
// TRD §1.2-supported platform.
// Environment is selected at build time via `--dart-define=FIREBASE_ENV=dev
// |staging|prod` (matches wishlist-wizard's pattern); only 'dev' is wired up
// so far — staging/prod need their own app registrations before release.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String firebaseEnv = String.fromEnvironment(
    'FIREBASE_ENV',
    defaultValue: 'dev',
  );

  static const FirebaseOptions _dev_android = FirebaseOptions(
    apiKey: 'AIzaSyDDixYBYwcGpjyAeTxyJi32ydsgqY9dy5E',
    appId: '1:752167886309:android:42d8e9ed0867a9b0d3e30c',
    messagingSenderId: '752167886309',
    projectId: 'balance-forward-dev',
    storageBucket: 'balance-forward-dev.firebasestorage.app',
  );

  static const FirebaseOptions _dev_ios = FirebaseOptions(
    apiKey: 'AIzaSyDNmIEFue4_SGvB-zrsd_HMkKckpACpRXo',
    appId: '1:752167886309:ios:deed6b31c703aa4fd3e30c',
    messagingSenderId: '752167886309',
    projectId: 'balance-forward-dev',
    storageBucket: 'balance-forward-dev.firebasestorage.app',
    iosBundleId: 'com.balanceforward.app.ios',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — use '
        'packages/web (React) instead of the Flutter web target.',
      );
    }
    if (firebaseEnv != 'dev') {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for '
        '$firebaseEnv — only \'dev\' is wired up so far.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _dev_android;
      case TargetPlatform.iOS:
        return _dev_ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for '
          '$defaultTargetPlatform.',
        );
    }
  }
}
