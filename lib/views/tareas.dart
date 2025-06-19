import 'package:flutter/material.dart'; // Importa la biblioteca fundamental de Flutter para construir interfaces de usuario.
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Cloud Firestore, la base de datos NoSQL de Firebase.
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
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color completedOrange = Color(0xFFF57C00); // Color para tareas completadas.

  @override
  Widget build(BuildContext context) {
    // Scaffold proporciona la estructura visual básica de la pantalla.
    return Scaffold(
      backgroundColor: offWhite, // Color de fondo de la pantalla.
      appBar: AppBar(
        // Configuración de la barra de aplicación en la parte superior.
        title: const Text(
          'Tareas', // Título de la AppBar.
          style: TextStyle(
            color: darkGrey,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            fontFamily: 'Montserrat',
          ),
        ),
        automaticallyImplyLeading: false, // Deshabilita el botón de retroceso automático.
        backgroundColor: whiteColor, // Color de fondo de la AppBar.
        elevation: 4, // Sombra de la AppBar.
        centerTitle: false, // Alineación del título.
        toolbarHeight: 90, // Altura de la barra de herramientas.
        surfaceTintColor: Colors.transparent, // Color de la superficie cuando hay desplazamiento.
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Bordes redondeados en la parte inferior de la AppBar.
          ),
        ),
      ),
      bottomNavigationBar: const Footer(currentIndex: 1), // Barra de navegación inferior con el índice de la pestaña de Tareas.
      floatingActionButton: FloatingActionButton(
        // Botón flotante para añadir nuevas tareas.
        onPressed: () {
          // Muestra un diálogo al presionar el botón flotante.
          showDialog(
            context: context,
            barrierDismissible: true, // Permite cerrar el diálogo tocando fuera de él.
            builder: (context) => const Dialog(
              backgroundColor: Colors.transparent, // Fondo transparente para el diálogo.
              insetPadding: EdgeInsets.all(24), // Espaciado interior del diálogo.
              child: NewTaskScreen(), // Contenido del diálogo: el widget para crear nuevas tareas.
            ),
          );
        },
        backgroundColor: primaryGreen, // Color de fondo del botón.
        foregroundColor: whiteColor, // Color del icono del botón.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Bordes redondeados del botón.
        ),
        elevation: 8, // Sombra del botón.
        highlightElevation: 12, // Sombra cuando está presionado.
        splashColor: lightGreen, // Color de la "onda" al tocar el botón.
        child: const Icon(Icons.add, size: 30), // Icono de añadir.
      ),
      body: StreamBuilder<QuerySnapshot>(
        // StreamBuilder escucha cambios en una colección de Firestore en tiempo real.
        stream: _firestoreService.getUserTasksStream(), // Obtiene el stream de tareas del usuario.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Si el stream está esperando datos, muestra un indicador de carga.
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Si no hay datos o la lista de documentos está vacía, muestra un mensaje.
            return Center(
              child: Text(
                'No tienes tareas aún.',
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic),
              ),
            );
          }

          final allTasks = snapshot.data!.docs; // Obtiene todos los documentos de tareas.
          // Filtra las tareas para mostrar solo las que no están completadas (isCompleted es null o false).
          final tasks = allTasks.where((task) =>
              task['isCompleted'] == null || task['isCompleted'] == false
          ).toList();

          if (tasks.isEmpty) {
            // Si después de filtrar no hay tareas pendientes, muestra un mensaje específico.
            return Center(
              child: Text(
                'No tienes tareas pendientes.',
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic),
              ),
            );
          }

          // Si hay tareas pendientes, las muestra en una lista.
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  itemCount: tasks.length, // Número de tareas a mostrar.
                  itemBuilder: (context, index) {
                    final task = tasks[index]; // Obtiene el documento de la tarea actual.
                    final taskData = task.data() as Map<String, dynamic>; // Datos de la tarea como mapa.
                    final taskId = task.id; // ID del documento de la tarea.

                    return Card(
                      // Tarjeta para mostrar cada tarea.
                      elevation: 6, // Sombra de la tarjeta.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Bordes redondeados.
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10), // Margen de la tarjeta.
                      color: whiteColor, // Color de fondo de la tarjeta.
                      child: InkWell(
                        // Permite que la tarjeta sea "tappable" (se pueda tocar).
                        onTap: () {
                          // Al tocar la tarjeta, muestra un diálogo con los detalles de la tarea.
                          showDialog(
                            context: context,
                            builder: (context) => DetailsTaskScreen(
                              taskData: taskData, // Pasa los datos de la tarea al widget de detalles.
                              taskId: taskId, // Pasa el ID de la tarea.
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15), // Bordes redondeados para el efecto de toque.
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      taskData['title'] ?? '', // Título de la tarea.
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: darkGrey,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      taskData['project'] ?? '', // Proyecto al que pertenece la tarea.
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
                                // Botones de acción (eliminar y completar/deshacer).
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    // Botón para eliminar la tarea.
                                    icon: const Icon(Icons.delete, color: errorRed, size: 26),
                                    tooltip: 'Eliminar tarea',
                                    onPressed: () async {
                                      // Muestra un diálogo de confirmación antes de eliminar.
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                          content: const Text('¿Estás seguro de que deseas eliminar esta tarea?', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false), // Botón Cancelar.
                                              child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true), // Botón Eliminar.
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
                                        await _firestoreService.deleteTask(taskId); // Llama al servicio para eliminar la tarea.
                                      }
                                    },
                                  ),
                                  IconButton(
                                    // Botón para marcar como completada o pendiente.
                                    icon: Icon(
                                      taskData['isCompleted'] == true ? Icons.undo : Icons.check_circle_outline, // Cambia el icono según el estado.
                                      color: taskData['isCompleted'] == true ? completedOrange : primaryGreen, // Cambia el color según el estado.
                                      size: 26,
                                    ),
                                    tooltip: taskData['isCompleted'] == true
                                        ? 'Marcar como pendiente'
                                        : 'Completar tarea', // Texto del tooltip.
                                    onPressed: () async {
                                      await _firestoreService.toggleTaskCompleted(
                                        taskId,
                                        !(taskData['isCompleted'] == true), // Alterna el estado de `isCompleted`.
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