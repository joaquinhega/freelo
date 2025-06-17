import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'widgets/Footer.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<QuerySnapshot> _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = _firestoreService.getUserTasksStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const Footer(currentIndex: 1),
      body: StreamBuilder<QuerySnapshot>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes tareas aún.'));
          }
          final tasks = snapshot.data!.docs;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(task['title'] ?? ''),
                  subtitle: Text(task['description'] ?? ''),
                  trailing: Icon(
                    task['isCompleted'] == true
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task['isCompleted'] == true ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    // Aquí podrías navegar a detalles o marcar como completada
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/nueva-tarea');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}