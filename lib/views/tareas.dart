import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importante para obtener el UID del usuario
import 'new_tarea.dart'; 

import 'widgets/Footer.dart'; 

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  Stream<QuerySnapshot>? _tasksStream;

  @override
  void initState() {
    super.initState();
    _initializeTasksStream();
  }

  void _initializeTasksStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksStream = FirebaseFirestore.instance
          .collection('tasks') // ¡Colección 'tasks' para consistencia con reglas!
          .doc(user.uid) // Documento con la UID del usuario autenticado
          .collection('userTasks') // Subcolección de las tareas del usuario
          .orderBy('timestamp', descending: true) // Opcional: ordenar por fecha
          .snapshots();
    } else {
      print('DEBUG: No hay usuario autenticado. No se pueden cargar las tareas.');
      // Si no hay usuario, puedes devolver un stream vacío o mostrar un error en la UI.
      // Aquí, establecemos un stream vacío para que el StreamBuilder no falle.
      _tasksStream = Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: _tasksStream == null
          ? const Center(child: CircularProgressIndicator()) // Muestra cargando si el stream aún no se inicializó
          : StreamBuilder<QuerySnapshot>(
              stream: _tasksStream, // Usa el stream inicializado
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar tareas: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tienes tareas aún. ¡Crea una!'));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Asegúrate de que los nombres de los campos ('title', 'client')
                    // coincidan con los que guardas en NewTaskScreen.
                    return _taskTile(
                      data['title'] ?? '',
                      data['client'] ?? '',
                    );
                  }).toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega a la pantalla para crear una nueva tarea
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NewTaskScreen()),
          ).then((_) {
            // Opcional: Re-inicializar el stream si necesitas forzar un refresh
            // aunque snapshots() ya maneja cambios en tiempo real.
            // _initializeTasksStream();
          });
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const Footer(
        currentIndex: 1, // Asegúrate de que este índice sea el correcto para la navegación.
      ),
    );
  }

  Widget _taskTile(String title, String client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(title),
        subtitle: Text(client),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}