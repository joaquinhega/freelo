import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Registrar usuario
  Future<User?> register(String email, String password) async {
    try{
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch(e){
      print('Error al registrar usuario: $e');
      return null;
    }
  }
  //Login
  Future<User?> login(String email, String password) async {
    try{
      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch(e){
      print('Error al iniciar sesión: $e');
      return null;
    }
  }
  //Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
  //Get Usuario actual
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}