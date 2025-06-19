import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registrar nuevo usuario email y contraseña
  Future<User?> register(String email, String password, {String? nombre}) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (nombre != null && nombre.isNotEmpty) {
        await cred.user?.updateDisplayName(nombre);
      }
      return cred.user;
    } catch (e) {
      print('Error al registrar usuario: $e');
      return null;
    }
  }
  //Iniciar sesión con email y contraseña
  Future<User?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return null;
    }
  }
  // Iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error en Google Sign-In: $e');
      return null;
    }
  }
  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
  // devuelve el usuario actual
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}