import 'package:flutter/material.dart';
import 'edit_tarea.dart';

class DetailsTaskScreen extends StatelessWidget {
  final Map<String, dynamic> taskData;
  final String taskId;

  const DetailsTaskScreen({
    super.key,
    required this.taskData,
    required this.taskId,
  });

  // Colores de la app
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9); 
  static const Color whiteColor = Colors.white; 
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121); 
  static const Color mediumGrey = Color(0xFF616161); 
  static const Color accentBlue = Color(0xFF2196F3); 
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color softGrey = Color(0xFFE0E0E0); 

  @override
  Widget build(BuildContext context) {
    // Extraer datos de la tarea
    final title = taskData['title'] ?? 'Sin título';
    final description = taskData['description'] ?? 'Sin descripción';
    final project = taskData['project'] ?? 'Sin proyecto';
    final phase = taskData['phase'] ?? null;

    return Dialog( // Modal para mostrar los detalles de la tarea
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Material( // Aplica estilos
        color: whiteColor, 
        borderRadius: BorderRadius.circular(24), 
        elevation: 10, 
        shadowColor: Colors.black.withOpacity(0.3), 
        child: SingleChildScrollView( // Permite scroll si el contenido es grande
          child: Padding( //Permite agregar espacio alrededor del contenido
            padding: const EdgeInsets.all(28.0), 
            child: Column( // Contenido principal del modal
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [//sirve para alinear los widgets en una fila
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: darkGrey, 
                          fontFamily: 'Montserrat',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 26, color: primaryGreen), 
                      tooltip: 'Editar tarea', 
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
                          Navigator.pop(context, true); 
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28, color: mediumGrey), 
                      tooltip: 'Cerrar', 
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project,
                  style: const TextStyle(
                    fontSize: 17, 
                    color: mediumGrey, 
                    fontFamily: 'Roboto', 
                    fontWeight: FontWeight.w500, 
                  ),
                ),
                if (phase != null && phase.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fase: $phase',
                    style: const TextStyle(
                      fontSize: 16, 
                      color: mediumGrey,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
                const SizedBox(height: 20), 
                Container(
                  padding: const EdgeInsets.all(16), 
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: softGrey, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: lightGreen.withOpacity(0.5)), 
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
