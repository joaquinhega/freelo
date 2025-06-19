import 'package:flutter/material.dart'; // Importa la biblioteca fundamental de Flutter para construir interfaces de usuario.
import 'edit_tarea.dart'; // Importa el widget para editar una tarea existente.

// `DetailsTaskScreen` es un widget sin estado (`StatelessWidget`)
// ya que solo muestra la información de una tarea y no mantiene ningún estado mutable interno.
class DetailsTaskScreen extends StatelessWidget {
  // `taskData` es un mapa que contiene todos los datos de la tarea a mostrar.
  final Map<String, dynamic> taskData;
  // `taskId` es el identificador único de la tarea en la base de datos (Firestore).
  final String taskId;

  // Constructor de la clase. Requiere `taskData` y `taskId` para su inicialización.
  const DetailsTaskScreen({
    super.key,
    required this.taskData,
    required this.taskId,
  });

  // Definición de una paleta de colores para mantener la consistencia en la interfaz de usuario.
  static const Color primaryGreen = Color(0xFF2E7D32); // Verde principal para elementos de acción o positivos.
  static const Color lightGreen = Color(0xFFE8F5E9); // Verde claro, posiblemente para fondos o resaltados suaves.
  static const Color whiteColor = Colors.white; // Color blanco puro.
  static const Color offWhite = Color(0xFFF0F2F5); // Un blanco ligeramente grisáceo, a menudo usado para fondos.
  static const Color darkGrey = Color(0xFF212121); // Gris oscuro para texto principal o iconos.
  static const Color mediumGrey = Color(0xFF616161); // Gris medio para texto secundario o iconos.
  static const Color accentBlue = Color(0xFF2196F3); // Azul de acento, quizás para enlaces o elementos interactivos.
  static const Color warningOrange = Color(0xFFFF9800); // Naranja para advertencias o estados especiales.
  static const Color softGrey = Color(0xFFE0E0E0); // Un gris suave, a menudo para bordes o separadores.

  @override
  Widget build(BuildContext context) {
    // Extraer datos de la tarea del mapa `taskData`.
    // Se utiliza el operador `??` para proporcionar un valor predeterminado si el campo es nulo.
    final title = taskData['title'] ?? 'Sin título'; // Título de la tarea.
    final description = taskData['description'] ?? 'Sin descripción'; // Descripción de la tarea.
    final project = taskData['project'] ?? 'Sin proyecto'; // Proyecto al que pertenece la tarea.
    final phase = taskData['phase'] ?? null; // Fase de la tarea (puede ser nulo).

    // `Dialog` es un widget que se usa para crear ventanas emergentes modales.
    return Dialog(
      backgroundColor: Colors.transparent, // Hace que el fondo del diálogo sea transparente para ver el contenido detrás.
      insetPadding: const EdgeInsets.all(24), // Define el espacio entre el borde del diálogo y el borde de la pantalla.
      child: Material( // `Material` es un widget que recorta su hijo a una forma particular y eleva su z-index.
        color: whiteColor, // Color de fondo del material (el cuerpo del diálogo).
        borderRadius: BorderRadius.circular(24), // Aplica bordes redondeados al material.
        elevation: 10, // Sombra que proyecta el material.
        shadowColor: Colors.black.withOpacity(0.3), // Color de la sombra con cierta opacidad.
        child: SingleChildScrollView( // Permite que el contenido dentro del diálogo sea desplazable si excede el tamaño.
          child: Padding( // `Padding` agrega espacio en todos los lados del contenido.
            padding: const EdgeInsets.all(28.0),
            child: Column( // `Column` organiza sus hijos en una disposición vertical.
              mainAxisSize: MainAxisSize.min, // La columna ocupará solo el espacio vertical mínimo necesario.
              crossAxisAlignment: CrossAxisAlignment.start, // Alinea los hijos de la columna al inicio (izquierda).
              children: [ // Lista de widgets hijos de la columna.
                Row( // `Row` organiza sus hijos en una disposición horizontal.
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye los hijos uniformemente con espacio entre ellos.
                  children: [
                    Expanded( // Permite que el `Text` ocupe todo el espacio horizontal disponible.
                      child: Text(
                        title, // Muestra el título de la tarea.
                        style: const TextStyle(
                          fontSize: 24, // Tamaño de fuente del título.
                          fontWeight: FontWeight.bold, // Negrita para el título.
                          color: darkGrey, // Color de texto oscuro.
                          fontFamily: 'Montserrat', // Fuente personalizada.
                        ),
                        overflow: TextOverflow.ellipsis, // Si el texto es demasiado largo, lo trunca con puntos suspensivos.
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 26, color: primaryGreen), // Icono de edición.
                      tooltip: 'Editar tarea', // Texto que aparece al mantener presionado el botón.
                      onPressed: () async {
                        // Al presionar el botón de editar, muestra otro diálogo para editar la tarea.
                        final result = await showDialog(
                          context: context,
                          barrierDismissible: true, // Permite cerrar el diálogo de edición tocando fuera.
                          builder: (context) => EditTaskScreen(
                            taskId: taskId, // Pasa el ID de la tarea a la pantalla de edición.
                            initialTaskData: taskData, // Pasa los datos iniciales de la tarea para pre-rellenar el formulario.
                          ),
                        );
                        // Si la edición fue exitosa (el resultado es `true`) y el contexto sigue montado,
                        // cierra este diálogo de detalles.
                        if (result == true && context.mounted) {
                          Navigator.pop(context, true); // Cierra el diálogo actual y pasa `true` como resultado.
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28, color: mediumGrey), // Icono de cerrar.
                      tooltip: 'Cerrar', // Texto del tooltip para cerrar.
                      onPressed: () => Navigator.pop(context), // Cierra el diálogo actual al presionar.
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Espacio vertical entre el título y el proyecto.
                Text(
                  project, // Muestra el nombre del proyecto.
                  style: const TextStyle(
                    fontSize: 17,
                    color: mediumGrey,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Muestra la fase solo si no es nula y no está vacía.
                if (phase != null && phase.toString().isNotEmpty) ...[
                  const SizedBox(height: 8), // Espacio vertical antes de la fase.
                  Text(
                    'Fase: $phase', // Muestra la fase de la tarea.
                    style: const TextStyle(
                      fontSize: 16,
                      color: mediumGrey,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
                const SizedBox(height: 20), // Espacio vertical antes de la descripción.
                Container( // Un contenedor para la descripción con estilos.
                  padding: const EdgeInsets.all(16), // Relleno interno del contenedor.
                  width: double.infinity, // El contenedor ocupa todo el ancho disponible.
                  decoration: BoxDecoration( // Decoración del contenedor.
                    color: softGrey, // Color de fondo del contenedor.
                    borderRadius: BorderRadius.circular(12), // Bordes redondeados.
                    border: Border.all(color: lightGreen.withOpacity(0.5)), // Borde suave con transparencia.
                  ),
                  child: Text(
                    description, // Muestra la descripción de la tarea.
                    style: const TextStyle(
                      fontSize: 16,
                      color: darkGrey,
                      fontFamily: 'Roboto',
                      height: 1.5, // Altura de línea para una mejor legibilidad.
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Espacio vertical al final del contenido.
              ],
            ),
          ),
        ),
      ),
    );
  }
}