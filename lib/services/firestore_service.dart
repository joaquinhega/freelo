import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Variables para llamar a servicios de Firestore y FirebaseAuth
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Agregar una tarea
  Future<void> addTask({
    required String title,
    required String description,
    required String project,
    required DateTime fecha,
    String? phase,
    required String projectId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[firestore_service] No user logged in para addTask');
      return;
    }
    final data = {
      'title': title,
      'description': description,
      'project': project,
      'projectId': projectId,
      'fecha': fecha,
      if (phase != null) 'phase': phase,
      'timestamp': FieldValue.serverTimestamp(),
      'isCompleted': false,
    };
    print('[firestore_service] Guardando tarea en users/${user.uid}/userTasks: $data');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .add(data);
  }
  // Editar una tarea
  Future<void> updateTask({
    required String taskId,
    required Map<String, dynamic> data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[firestore_service] No user logged in para updateTask');
      return;
    }
    print('[firestore_service] Actualizando tarea $taskId con: $data');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .doc(taskId)
        .update(data);
  }
  // Eliminar una tarea
  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[firestore_service] No user logged in para deleteTask');
      return;
    }
    print('[firestore_service] Eliminando tarea $taskId');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .doc(taskId)
        .delete();
  }
  // Marcar tarea como completada o no completada
  Future<void> toggleTaskCompleted(String taskId, bool isCompleted) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[firestore_service] No user logged in para toggleTaskCompleted');
      return;
    }
    print('[firestore_service] Cambiando estado de tarea $taskId a completado: $isCompleted');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .doc(taskId)
        .update({'isCompleted': isCompleted});
  }
  // Obtinene las tareas del usuario
  Stream<QuerySnapshot> getUserTasksStream() {
    final user = _auth.currentUser;
    if (user == null) {
      print('[firestore_service] No user logged in para getUserTasksStream');
      return const Stream.empty();
    }
    print('[firestore_service] Escuchando todas las tareas en users/${user.uid}/userTasks');
    return _db
      .collection('users')
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
    List<Map<String, String>>? phases, // Se espera List<Map<String, String>>
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
      'phases': phases ?? [], // Asegura que sea una lista vacía si es null
      'hasClient': hasClient,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (hasClient && clientInfo != null) {
      projectData['client'] = clientInfo;
    }

    final docRef = await _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .add(projectData);

    await docRef.update({'id': docRef.id});
  }

  // Obtiene los proyectos del usuario
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

  // Obtener todos los nombres de proyectos
  Future<List<Map<String, dynamic>>> getAllProjectsWithPhases() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] as String,
        'hasPhases': data['hasPhases'] ?? false,
        'phases': (data['phases'] ?? []) as List<dynamic>,
      };
    }).toList();
  }

  // Obtener el perfil del usuario
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Crea detalles del perfil de freelancer
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

  // Editar un proyecto
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

  // Eliminar un proyecto
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

  // Añadir una factura
  Future<void> addInvoice({
    required String projectId,
    required String projectName,
    required double amount,
    required DateTime emissionDate,
    required DateTime dueDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[firestore_service] No user logged in para addInvoice');
      return;
    }
    final data = {
      'projectId': projectId,
      'projectName': projectName,
      'amount': amount,
      'emissionDate': Timestamp.fromDate(emissionDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'timestamp': FieldValue.serverTimestamp(),
    };
    print('[firestore_service] Guardando factura en users/${user.uid}/invoices: $data');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .add(data);
  }

  // Obtener las facturas del usuario
  Stream<QuerySnapshot> getInvoicesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      print('[firestore_service] No user logged in para getInvoicesStream');
      return const Stream.empty();
    }
    print('[firestore_service] Escuchando todas las facturas en users/${user.uid}/invoices');
    return _db
      .collection('users')
      .doc(user.uid)
      .collection('facturas')
      .orderBy('timestamp', descending: true)
      .snapshots();
  }
}