import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_tarea.dart';

class DetailsTaskScreen extends StatelessWidget {
  final Map<String, dynamic> taskData;
  final String taskId;

  const DetailsTaskScreen({
    super.key,
    required this.taskData,
    required this.taskId,
  });

  // Define a consistent color palette based on green and white
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep Green (from logo)
  static const Color lightGreen = Color(0xFFE8F5E9); // Very light green for subtle backgrounds/accents
  static const Color whiteColor = Colors.white; // Pure white
  static const Color offWhite = Color(0xFFF0F2F5); // Slightly off-white for background
  static const Color darkGrey = Color(0xFF212121); // Dark grey for primary text
  static const Color mediumGrey = Color(0xFF616161); // Medium grey for secondary text
  static const Color accentBlue = Color(0xFF2196F3); // A touch of blue for emphasis (e.g., info icons)
  static const Color warningOrange = Color(0xFFFF9800); // Orange for warnings
  static const Color softGrey = Color(0xFFE0E0E0); // Lighter grey for subtle backgrounds

  @override
  Widget build(BuildContext context) {
    final title = taskData['title'] ?? 'Sin título';
    final description = taskData['description'] ?? 'Sin descripción';
    final project = taskData['project'] ?? 'Sin proyecto';
    final phase = taskData['phase'] ?? null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Material(
        color: whiteColor, // White background for the dialog
        borderRadius: BorderRadius.circular(24), // More rounded corners
        elevation: 10, // Added elevation for a lifted effect
        shadowColor: Colors.black.withOpacity(0.3), // More prominent shadow
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0), // Increased padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24, // Larger title
                          fontWeight: FontWeight.bold,
                          color: darkGrey, // Darker title color
                          fontFamily: 'Montserrat', // Modern font
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 26, color: primaryGreen), // Larger icon, green color
                      tooltip: 'Editar tarea', // Tooltip for better UX
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => EditTaskScreen(
                            taskId: taskId,
                            initialTaskData: taskData,
                          ),
                        );
                        if (result == true && context.mounted) {
                          Navigator.pop(context, true); // Cierra details si se editó
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28, color: mediumGrey), // Larger close icon
                      tooltip: 'Cerrar', // Tooltip for better UX
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Increased spacing
                Text(
                  project,
                  style: const TextStyle(
                    fontSize: 17, // Larger font size
                    color: mediumGrey, // Medium grey for project
                    fontFamily: 'Roboto', // Consistent font
                    fontWeight: FontWeight.w500, // Slightly bolder
                  ),
                ),
                if (phase != null && phase.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fase: $phase',
                    style: const TextStyle(
                      fontSize: 16, // Consistent font size
                      color: mediumGrey, // Medium grey for phase
                      fontFamily: 'Roboto', // Consistent font
                    ),
                  ),
                ],
                const SizedBox(height: 20), // More vertical space
                Container(
                  padding: const EdgeInsets.all(16), // Increased padding
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: softGrey, // Lighter grey background
                    borderRadius: BorderRadius.circular(12), // More rounded corners
                    border: Border.all(color: lightGreen.withOpacity(0.5)), // Subtle border
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: darkGrey, 
                      fontFamily: 'Roboto', 
                      height: 1.5, 
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
