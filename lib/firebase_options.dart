import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Esta clase, `DefaultFirebaseOptions`, está diseñada para proporcionar las configuraciones de Firebase
// específicas para cada plataforma (web, Android, iOS, etc.).
// Generalmente es generada automáticamente por FlutterFire CLI (Firebase Command Line Interface).
class DefaultFirebaseOptions {
  // `currentPlatform` es un getter estático que devuelve las opciones de Firebase
  // adecuadas para la plataforma en la que se está ejecutando la aplicación.
  static FirebaseOptions get currentPlatform {
    // Comprueba si la aplicación se está ejecutando en un navegador web.
    if (kIsWeb) {
      return web; // Si es web, devuelve las opciones de Firebase para la web.
    }
    // Utiliza un `switch` para determinar la plataforma de destino actual.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android; // Si es Android, devuelve las opciones de Firebase para Android.
      case TargetPlatform.iOS:
        // Si es iOS, lanza un error. Esto indica que las opciones para iOS no han sido configuradas.
        // El mensaje sugiere ejecutar `flutterfire configure` nuevamente para generarlas.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        // Si es macOS, lanza un error similar, indicando que la configuración no está disponible.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        // Si es Windows, lanza un error similar.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        // Si es Linux, lanza un error similar.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        // Para cualquier otra plataforma no contemplada, lanza un error genérico de incompatibilidad.
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Opciones de Firebase para la plataforma web.
  // Estos valores son sensibles y deben mantenerse seguros, no compartirlos públicamente.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCpg2EXqDDGrJ0RPZJtGBhE3QwqIzndSpM', // Clave de API para autenticar solicitudes a Firebase.
    appId: '1:578213470663:web:001478c0255deba89179e2', // ID único de la aplicación web de Firebase.
    messagingSenderId: '578213470663', // ID del remitente para Firebase Cloud Messaging.
    projectId: 'freelo-5dee5', // ID del proyecto de Firebase.
    authDomain: 'freelo-5dee5.firebaseapp.com', // Dominio de autenticación para Firebase Auth.
    storageBucket: 'freelo-5dee5.firebasestorage.app', // Bucket de almacenamiento para Firebase Storage.
  );

  // Opciones de Firebase para la plataforma Android.
  // Estos valores también son sensibles.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCIW424DsbTrny48_4rN4PUV79-GyZLtUw', // Clave de API para Android.
    appId: '1:578213470663:android:042ae3adc937f87a9179e2', // ID único de la aplicación Android de Firebase.
    messagingSenderId: '578213470663', // ID del remitente para Firebase Cloud Messaging en Android.
    projectId: 'freelo-5dee5', // ID del proyecto de Firebase.
    storageBucket: 'freelo-5dee5.firebasestorage.app', // Bucket de almacenamiento para Firebase Storage en Android.
  );
}