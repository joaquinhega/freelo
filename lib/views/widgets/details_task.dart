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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
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
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                if (phase != null && phase.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fase: $phase',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}