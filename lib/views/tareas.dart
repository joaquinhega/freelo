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

  // Define a consistent color palette based on green and white
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep Green (from logo)
  static const Color lightGreen = Color(0xFFE8F5E9); // Very light green for subtle backgrounds/accents
  static const Color whiteColor = Colors.white; // Pure white
  static const Color offWhite = Color(0xFFF0F2F5); // Slightly off-white for background
  static const Color darkGrey = Color(0xFF212121); // Dark grey for primary text
  static const Color mediumGrey = Color(0xFF616161); // Medium grey for secondary text
  static const Color errorRed = Color(0xFFD32F2F); // Red for errors/deletions
  static const Color completedOrange = Color(0xFFF57C00); // Orange for completed/undo
  static const Color softGreenGradientStart = Color(0xFF4CAF50); // Lighter green for gradients
  static const Color softGreenGradientEnd = Color(0xFF8BC34A); // Even lighter green for gradients


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        title: const Text(
          'Tareas',
          style: TextStyle(
            color: darkGrey, // AppBar title color
            fontWeight: FontWeight.bold,
            fontSize: 28, // Larger app bar title for more impact
            fontFamily: 'Montserrat', // Modern font for titles
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: whiteColor, // White app bar background
        elevation: 4, // More pronounced shadow for app bar
        centerTitle: false, // Align title to start
        toolbarHeight: 90, // Increase app bar height for better spacing
        surfaceTintColor: Colors.transparent, // Remove default surface tint
        shape: const RoundedRectangleBorder( // Rounded bottom corners for app bar
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
        backgroundColor: primaryGreen, // FAB color
        foregroundColor: whiteColor, // FAB icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Slightly rounded FAB
        ),
        elevation: 8, // Added shadow to FAB
        highlightElevation: 12, // More elevation on press
        splashColor: lightGreen, // Splash color on press
        child: const Icon(Icons.add, size: 30), // Larger icon
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
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic), // Larger and italic
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
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic), // Larger and italic
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), // Increased padding for the list
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final taskData = task.data() as Map<String, dynamic>;
                    final taskId = task.id;

                    return Card(
                      elevation: 6, // More pronounced shadow for cards
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // More rounded corners
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10), // Adjusted margin
                      color: whiteColor, // Card background color
                      child: InkWell( // Added InkWell for ripple effect on tap
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15), // Increased padding
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      taskData['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700, // Bolder title
                                        fontSize: 18, // Larger font size
                                        color: darkGrey,
                                        fontFamily: 'Montserrat', // Consistent font
                                      ),
                                    ),
                                    const SizedBox(height: 6), // Increased spacing
                                    Text(
                                      taskData['project'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15, // Consistent font size
                                        color: mediumGrey,
                                        fontFamily: 'Roboto', // Consistent font
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorRed, size: 26), // Larger icon, error color
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
                                            borderRadius: BorderRadius.circular(15), // More rounded dialog
                                          ),
                                          elevation: 10, // Added shadow to dialog
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _firestoreService.deleteTask(taskId);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      taskData['isCompleted'] == true ? Icons.undo : Icons.check_circle_outline, // Changed icon for completed state
                                      color: taskData['isCompleted'] == true ? completedOrange : primaryGreen, // Dynamic color for check/undo
                                      size: 26, // Larger icon
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
