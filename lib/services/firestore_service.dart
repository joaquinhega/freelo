import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Guardar una nueva tarea con proyecto, duración y fecha
  Future<void> addTask({
    required String title,
    required String description,
    required String project,
    required DateTime fecha,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No autenticado');
    await _db
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .add({
          'title': title,
          'description': description,
          'project': project,
          'fecha': fecha,
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

  // Guardar un nuevo proyecto
  Future<void> addProject({
    required String title,
    String? description,
    String? date,
    bool hasPhases = false,
    List<Map<String, String>>? phases,
    bool hasClient = false,
    Map<String, String>? clientInfo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    Map<String, dynamic> projectData = {
      'title': title,
      'description': description ?? '',
      'date': date ?? '',
      'hasPhases': hasPhases,
      'phases': phases ?? [],
      'hasClient': hasClient,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (hasClient && clientInfo != null) {
      projectData['client'] = clientInfo;
    }

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .add(projectData);
  }

  // Obtener stream de proyectos del usuario autenticado
  Stream<QuerySnapshot> getProjectsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Obtener todos los nombres de proyectos del usuario autenticado
  Future<List<String>> getAllProjectNames() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();
    return snapshot.docs.map((doc) => doc['title'] as String).toList();
  }

  // Obtener el perfil del usuario como stream
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Crear documento freelancerDetails al registrar usuario
  Future<void> createFreelancerDetails(
    String userId, {
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String address = '',
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('freelancerDetails')
        .set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'address': address,
        });
  }

  // Actualizar un proyecto existente
  Future<void> updateProject({
    required String userId,
    required String projectId,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .update(data);
  }

  // Eliminar un proyecto existente
  Future<void> deleteProject({
    required String userId,
    required String projectId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .delete();
  }
}