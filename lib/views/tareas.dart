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

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color completedOrange = Color(0xFFF57C00);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        title: const Text(
          'Tareas',
          style: TextStyle(
            color: darkGrey,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            fontFamily: 'Montserrat',
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: whiteColor,
        elevation: 4,
        centerTitle: false,
        toolbarHeight: 90,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      bottomNavigationBar: const Footer(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => const Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(24),
              child: NewTaskScreen(),
            ),
          );
        },
        backgroundColor: primaryGreen,
        foregroundColor: whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 8,
        highlightElevation: 12,
        splashColor: lightGreen,
        child: const Icon(Icons.add, size: 30),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No tienes tareas aún.',
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic),
              ),
            );
          }

          final allTasks = snapshot.data!.docs;
          final tasks = allTasks.where((task) =>
            task['isCompleted'] == null || task['isCompleted'] == false
          ).toList();

          if (tasks.isEmpty) {
            return Center(
              child: Text(
                'No tienes tareas pendientes.',
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final taskData = task.data() as Map<String, dynamic>;
                    final taskId = task.id;

                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      color: whiteColor,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => DetailsTaskScreen(
                              taskData: taskData,
                              taskId: taskId,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      taskData['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: darkGrey,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      taskData['project'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: mediumGrey,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorRed, size: 26),
                                    tooltip: 'Eliminar tarea',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                          content: const Text('¿Estás seguro de que deseas eliminar esta tarea?', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Eliminar', style: TextStyle(color: errorRed, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          elevation: 10,
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _firestoreService.deleteTask(taskId);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      taskData['isCompleted'] == true ? Icons.undo : Icons.check_circle_outline,
                                      color: taskData['isCompleted'] == true ? completedOrange : primaryGreen,
                                      size: 26,
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
                            ],
                          ),
                        ),
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