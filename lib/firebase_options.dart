// Arquivo gerado pelo FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [FirebaseOptions] padrão para uso com seus aplicativos Firebase.
///
/// Exemplo:
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
      throw UnsupportedError(
        'DefaultFirebaseOptions não foram configuradas para web - '
            'você pode reconfigurar isso executando o FlutterFire CLI novamente.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions não foram configuradas para ios - '
              'você pode reconfigurar isso executando o FlutterFire CLI novamente.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions não foram configuradas para macos - '
              'você pode reconfigurar isso executando o FlutterFire CLI novamente.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions não foram configuradas para windows - '
              'você pode reconfigurar isso executando o FlutterFire CLI novamente.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions não foram configuradas para linux - '
              'você pode reconfigurar isso executando o FlutterFire CLI novamente.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não são suportadas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_FuXA8KQtN7A9eGU2PxsENxPAQD8VqnY',
    appId: '1:1079998412784:android:d808c4bdc02d9fa6040f35',
    messagingSenderId: '1079998412784',
    projectId: 'color-sort-master-e822e',
    storageBucket: 'color-sort-master-e822e.firebasestorage.app',
  );
}