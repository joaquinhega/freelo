import 'package:flutter/material.dart'; // Importa la biblioteca fundamental de Flutter para construir interfaces de usuario.
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Cloud Firestore, la base de datos NoSQL de Firebase.
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Auth para autenticación de usuarios.
import '../services/firestore_service.dart'; // Importa un servicio personalizado para interactuar con Firestore.
import 'widgets/new_tarea.dart'; // Importa el widget para crear nuevas tareas.
import 'widgets/details_task.dart'; // Importa el widget para mostrar los detalles de una tarea.
import 'widgets/Footer.dart'; // Importa el widget de pie de página (barra de navegación inferior).


// Definición de la pantalla de Tareas como un StatefulWidget para manejar el estado.
class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key}); // Constructor de la clase.

  @override
  State<TareasScreen> createState() => _TareasScreenState(); // Crea el estado asociado a esta pantalla.
}

// Clase de estado para la pantalla de Tareas.
class _TareasScreenState extends State<TareasScreen> {
  // Instancia del servicio de Firestore para realizar operaciones de base de datos.
  final FirestoreService _firestoreService = FirestoreService();

  // Definición de una paleta de colores para la interfaz de usuario.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color completedOrange = Color(0xFFF57C00);

  late Stream<QuerySnapshot> _tasksStream; // Stream para tareas pendientes.
  late Stream<QuerySnapshot> _completedTasksStream; // Stream para tareas completadas.

@override
void initState() {
  super.initState();
  _tasksStream = _firestoreService.getPendingTasksStream();
  _completedTasksStream = _firestoreService.getCompletedTasksStream();
}

  // Elimina una tarea de Firestore.
  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarea eliminada correctamente.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar la tarea: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: darkGrey),
        title: const Text(
          'Mis Tareas',
          style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Montserrat'),
        ),
        backgroundColor: whiteColor,
        elevation: 4,
        centerTitle: false,
        toolbarHeight: 90,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      backgroundColor: offWhite,
      body: StreamBuilder<QuerySnapshot>(
        stream: _tasksStream, // Escucha los cambios en las tareas pendientes.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('No tienes tareas pendientes.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic))),
                  const SizedBox(height: 30),
                  // ExpansionTile para tareas completadas
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: EdgeInsets.zero,
                    child: ExpansionTile(
                      backgroundColor: whiteColor,
                      collapsedBackgroundColor: whiteColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: const Text(
                        'TAREAS COMPLETADAS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGrey,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_down, color: darkGrey),
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: _completedTasksStream,
                          builder: (context, completedSnapshot) {
                            if (completedSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: primaryGreen));
                            }
                            if (completedSnapshot.hasError) {
                              return Center(child: Text('Error: ${completedSnapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                            }
                            if (!completedSnapshot.hasData || completedSnapshot.data!.docs.isEmpty) {
                              return const Center(child: Text('No hay tareas completadas.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)));
                            }

                            final completedTasks = completedSnapshot.data!.docs;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: completedTasks.length,
                              itemBuilder: (context, index) {
                                final task = completedTasks[index].data() as Map<String, dynamic>;
                                final taskId = completedTasks[index].id;
                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  color: whiteColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(context: context, builder: (context) => DetailsTaskScreen(taskData: task, taskId: taskId));
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    decoration: TextDecoration.lineThrough,
                                                    color: mediumGrey,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: errorRed, size: 26),
                                            tooltip: 'Eliminar tarea',
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                                  content: const Text('¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: errorRed, 
                                                        foregroundColor: whiteColor, 
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                      ),
                                                      child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)), 
                                                    ),
                                                  ],
                                                  elevation: 10,
                                                ),
                                              );
                                              if (confirm == true) await _deleteTask(taskId);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.undo, color: completedOrange, size: 26),
                                            tooltip: 'Marcar como pendiente',
                                            onPressed: () async {
                                              await _firestoreService.toggleTaskCompleted(taskId, false);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data!.docs;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TAREAS PENDIENTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkGrey, fontFamily: 'Montserrat')),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index].data() as Map<String, dynamic>;
                    final taskId = tasks[index].id;
                    final isCompleted = task['isCompleted'] == true;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: whiteColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          showDialog(context: context, builder: (context) => DetailsTaskScreen(taskData: task, taskId: taskId));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        color: isCompleted ? mediumGrey : darkGrey,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    if (task['dueDate'] != null && task['dueDate'].isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fecha: ${task['dueDate']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isCompleted ? mediumGrey : Colors.grey[600],
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: errorRed, size: 26),
                                tooltip: 'Eliminar tarea',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                      content: const Text('¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: errorRed, 
                                            foregroundColor: whiteColor, 
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          ),
                                          child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)), 
                                        ),
                                      ],
                                      elevation: 10,
                                    ),
                                  );
                                  if (confirm == true) await _deleteTask(taskId);
                                },
                              ),
                              IconButton(
                                icon: Icon(isCompleted ? Icons.undo : Icons.check_circle_outline, color: isCompleted ? completedOrange : primaryGreen, size: 26),
                                tooltip: isCompleted ? 'Marcar como pendiente' : 'Marcar como completada',
                                onPressed: () async {
                                  await _firestoreService.toggleTaskCompleted(taskId, !isCompleted);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // ExpansionTile para tareas completadas
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    backgroundColor: whiteColor,
                    collapsedBackgroundColor: whiteColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    title: const Text(
                      'TAREAS COMPLETADAS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkGrey,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_down, color: darkGrey),
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: _completedTasksStream,
                        builder: (context, completedSnapshot) {
                          if (completedSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: primaryGreen));
                          }
                          if (completedSnapshot.hasError) {
                            return Center(child: Text('Error: ${completedSnapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                          }
                          if (!completedSnapshot.hasData || completedSnapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('No hay tareas completadas.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)));
                          }

                          final completedTasks = completedSnapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completedTasks.length,
                            itemBuilder: (context, index) {
                              final task = completedTasks[index].data() as Map<String, dynamic>;
                              final taskId = completedTasks[index].id;
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                color: whiteColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(context: context, builder: (context) => DetailsTaskScreen(taskData: task, taskId: taskId));
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  decoration: TextDecoration.lineThrough,
                                                  color: mediumGrey,
                                                  fontFamily: 'Montserrat',
                                                ),
                                              ),
                                              if (task['dueDate'] != null && task['dueDate'].isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Fecha: ${task['dueDate']}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: mediumGrey,
                                                    fontFamily: 'Roboto',
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: errorRed, size: 26),
                                          tooltip: 'Eliminar tarea',
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                                content: const Text('¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: errorRed, 
                                                      foregroundColor: whiteColor, 
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                    ),
                                                    child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)), 
                                                  ),
                                                ],
                                                elevation: 10,
                                              ),
                                            );
                                            if (confirm == true) await _deleteTask(taskId);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.undo, color: completedOrange, size: 26),
                                          tooltip: 'Marcar como pendiente',
                                          onPressed: () async {
                                            await _firestoreService.toggleTaskCompleted(taskId, false);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const NewTaskScreen(); // Abre el diálogo para crear una nueva tarea.
            },
          );
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.add, color: whiteColor, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const Footer(
        currentIndex: 1, // Indica que 'Tareas' es la página actual.
      ),
    );
  }
}