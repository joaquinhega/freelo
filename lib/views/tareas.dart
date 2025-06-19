import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'widgets/new_tarea.dart';
import 'widgets/details_task.dart';
import 'widgets/Footer.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const Footer(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => const NewTaskScreen(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes tareas aún.'));
          }

          final allTasks = snapshot.data!.docs;
          final tasks = allTasks.where((task) =>
            task['isCompleted'] == null || task['isCompleted'] == false
          ).toList();

          if (tasks.isEmpty) {
            return const Center(child: Text('No tienes tareas pendientes.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final taskData = task.data() as Map<String, dynamic>;
                    final taskId = task.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(taskData['title'] ?? ''),
                        subtitle: Text(taskData['project'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar tarea',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar tarea'),
                                    content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _firestoreService.deleteTask(taskId);
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                taskData['isCompleted'] == true ? Icons.undo : Icons.check,
                                color: taskData['isCompleted'] == true ? Colors.orange : Colors.green,
                              ),
                              tooltip: taskData['isCompleted'] == true
                                  ? 'Marcar como pendiente'
                                  : 'Completar tarea',
                              onPressed: () async {
                                await _firestoreService.toggleTaskCompleted(
                                  taskId,
                                  !(taskData['isCompleted'] == true),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => DetailsTaskScreen(
                              taskData: taskData,
                              taskId: taskId,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}