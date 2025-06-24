import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //-------------------------TAREAS-----------------------------
  /// Agregar una tarea
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

  /// Editar una tarea
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

  /// Eliminar una tarea
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
    /// Stream de tareas pendientes del usuario
  Stream<QuerySnapshot> getPendingTasksStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .where('isCompleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Stream de tareas completadas del usuario
  Stream<QuerySnapshot> getCompletedTasksStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .where('isCompleted', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Marcar tarea como completada o no completada
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

  /// Obtener las tareas del usuario (stream)
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

  /// Cantidad de tareas pendientes
  Future<int> getCantidadTareasPendientes() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .where('isCompleted', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  /// Stream de tareas filtradas por proyecto y estado (pendiente/completada)
  Stream<QuerySnapshot> getTasksByProjectStream({
    required String projectId,
    required bool isCompleted,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .where('projectId', isEqualTo: projectId)
        .where('isCompleted', isEqualTo: isCompleted)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
    /// Stream de tareas filtradas por proyecto, fase y estado (pendiente/completada)
  Stream<QuerySnapshot> getTasksByPhaseStream({
    required String projectId,
    required String phaseTitle,
    required bool isCompleted,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('userTasks')
        .where('projectId', isEqualTo: projectId)
        .where('phase', isEqualTo: phaseTitle)
        .where('isCompleted', isEqualTo: isCompleted)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  //------------------------------PROYECTOS--------------------------------
  /// Guardar un nuevo proyecto
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

    final docRef = await _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .add(projectData);

    await docRef.update({'id': docRef.id});
  }

  /// Editar un proyecto
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

  /// Eliminar un proyecto
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

  /// Obtener los proyectos del usuario (stream)
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

  /// Obtener todos los nombres de proyectos y fases
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

  /// Cantidad de proyectos activos
  Future<int> getCantidadProyectosActivos() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();
    return snapshot.docs.length;
  }

  Future<void> deletePhase({
    required String projectId,
    required Map<String, dynamic> phaseData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    final projectRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId);

    final projectSnap = await projectRef.get();
    if (projectSnap.exists && projectSnap.data() != null) {
      final phases = List<Map<String, dynamic>>.from(projectSnap['phases'] ?? []);
      phases.removeWhere((p) =>
          (p['id'] != null && phaseData['id'] != null && p['id'] == phaseData['id']) ||
          (p['title'] == phaseData['title']));
      await projectRef.update({'phases': phases});
    }
  }

  //---------------------------------USUARIO--------------------------------
  /// Verifica si existen los detalles del perfil de freelancer
  Future<bool> freelancerDetailsExists(String userId) async {
  final doc = await _db
      .collection('users')
      .doc(userId)
      .collection('profile')
      .doc('freelancerDetails')
      .get();
  return doc.exists;
}

  /// Obtener el perfil del usuario (stream)
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Crea detalles del perfil de freelancer
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

  /// Obtiene el nombre del usuario autenticado.
  Future<String> getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return 'Usuario';

    try {
      final profileDoc = await _db
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('freelancerDetails')
          .get();

      if (profileDoc.exists && profileDoc.data() != null) {
        final firstName = profileDoc.data()!['firstName'] ?? '';
        if (firstName.isNotEmpty) {
          return firstName;
        }
      }

      final doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        if (doc.data()!.containsKey('nombre') &&
            doc['nombre'] != null &&
            doc['nombre'].toString().isNotEmpty) {
          return doc['nombre'].toString();
        }
      }
    } catch (e) {
      print("Error obteniendo nombre de Firestore: $e");
    }

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null) {
      return user.email!.split('@')[0];
    }
    return 'Usuario';
  }
  
  /// Obtener detalles del freelancer
    Future<Map<String, String>?> getFreelancerDetails() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('freelancerDetails')
        .get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return {
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'address': data['address'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
    };
    }

  //---------------------FACTURACIÓN----------------------------
  /// Añadir una factura
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
      'precio': amount, 
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

  /// Obtener las facturas del usuario (stream)
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
        .collection('invoices')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  /// Obtener datos de un proyecto por ID
  Future<Map<String, dynamic>?> getProjectById(String projectId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  /// Añadir una factura completa
  Future<void> addInvoiceFull({
    required String numeroFactura,
    required String clienteNombre,
    required String clienteEmpresa,
    required String clienteEmail,
    required String clienteTelefono,
    required DateTime emissionDate,
    required DateTime dueDate,
    required String descripcionServicio,
    required double amount, 
    required String notasCondiciones,
    String? projectId,
    required String projectName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final data = {
      'numeroFactura': numeroFactura,
      'clienteNombre': clienteNombre,
      'clienteEmpresa': clienteEmpresa,
      'clienteEmail': clienteEmail,
      'clienteTelefono': clienteTelefono,
      'emissionDate': emissionDate,
      'dueDate': dueDate,
      'descripcionServicio': descripcionServicio,
      'precio': amount, 
      'notasCondiciones': notasCondiciones,
      'timestamp': FieldValue.serverTimestamp(),
      'projectId': projectId,
      'projectName': projectName,
    };
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .add(data);
  }

///--------------------------INGRESOS-------------------------
   /// Ingresos totales por proyecto
  Future<Map<String, double>> getIngresosPorProyecto() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .get();

    Map<String, double> ingresosPorProyecto = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final projectName = data['projectName'] as String? ?? 'Desconocido';
      final dynamic precio = data['precio'] ?? data['amount']; 
      double monto = 0.0;

      if (precio is int) monto = precio.toDouble();
      else if (precio is double) monto = precio;
      else if (precio is String) monto = double.tryParse(precio) ?? 0.0;

      ingresosPorProyecto.update(projectName, (value) => value + monto,
          ifAbsent: () => monto);
    }
    return ingresosPorProyecto;
  }

  /// Ingresos totales
  Future<double> getIngresosTotales() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dynamic precio = data['precio'] ?? data['amount']; 
      if (precio is int) total += precio.toDouble();
      else if (precio is double) total += precio;
      else if (precio is String) total += double.tryParse(precio) ?? 0.0;
    }
    return total;
  }

  /// Obtener el ingreso del mes actual.
  Future<double> getIngresoMensualActual() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .get();

    double ingresoMensual = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final rawFecha = data.containsKey('fechaFacturacion')
          ? data['fechaFacturacion']
          : data['emissionDate'];
      DateTime? fecha;
      if (rawFecha is Timestamp) {
        fecha = rawFecha.toDate();
      } else if (rawFecha is DateTime) {
        fecha = rawFecha;
      } else if (rawFecha is String) {
        try {
          fecha = DateTime.parse(rawFecha);
        } catch (_) {}
      }
      if (fecha != null && fecha.month == currentMonth && fecha.year == currentYear) {
        final dynamic precio = data['precio'] ?? data['amount'];
        double monto = 0.0;
        if (precio is int) monto = precio.toDouble();
        else if (precio is double) monto = precio;
        else if (precio is String) monto = double.tryParse(precio) ?? 0.0;
        ingresoMensual += monto;
      }
    }
    return ingresoMensual;
  }

  /// Obtener ingresos por mes, devolviendo una lista con los ingresos de cada mes del año.
  Future<List<double>> getIngresosPorMes() async {
    final user = _auth.currentUser;
    if (user == null) return List.filled(12, 0.0);

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .get();

    List<double> ingresosPorMes = List.filled(12, 0.0);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final rawFecha = data.containsKey('fechaFacturacion')
          ? data['fechaFacturacion']
          : data['emissionDate'];
      DateTime? fecha;
      if (rawFecha is Timestamp) {
        fecha = rawFecha.toDate();
      } else if (rawFecha is DateTime) {
        fecha = rawFecha;
      } else if (rawFecha is String) {
        try {
          fecha = DateTime.parse(rawFecha);
        } catch (_) {}
      }
      if (fecha == null) continue;
      final mes = fecha.month - 1;
      final dynamic precio = data['precio'] ?? data['amount'];
      double monto = 0.0;
      if (precio is int) monto = precio.toDouble();
      else if (precio is double) monto = precio;
      else if (precio is String) monto = double.tryParse(precio) ?? 0.0;
      ingresosPorMes[mes] += monto;
    }
    return ingresosPorMes;
  }
}