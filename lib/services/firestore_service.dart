import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Guardar una nueva tarea
  Future<void> addTask({
    required String title,
    required String client,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No autenticado');
    await _db
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .add({
          'title': title,
          'client': client,
          'description': description ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'isCompleted': false,
        });
  }

  // Obtener stream de tareas del usuario autenticado
  Stream<QuerySnapshot> getUserTasksStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
    Future<void> addClient({
    required String nombre,
    required String email,
    String? telefono,
    String? notas,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No autenticado');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .add({
          'nombre': nombre,
          'email': email,
          'telefono': telefono ?? '',
          'notas': notas ?? '',
          'fecha': FieldValue.serverTimestamp(),
        });
  }

  // Obtener stream de clientes
  Stream<QuerySnapshot> getClientsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('clients')
        .orderBy('nombre')
        .snapshots();
  }
}