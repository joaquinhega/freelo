import 'package:flutter/material.dart'; // Importa la librería fundamental de Flutter.
import '../../services/firestore_service.dart'; // Importa el servicio para interactuar con Firestore.

// `NewTaskScreen` es un StatefulWidget para la creación de nuevas tareas.
class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState(); // Crea el estado del widget.
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para validar el formulario.
  final TextEditingController _titleController = TextEditingController(); // Controlador para el título de la tarea.
  final TextEditingController _descriptionController = TextEditingController(); // Controlador para la descripción.

  final FirestoreService _firestoreService = FirestoreService(); // Instancia del servicio Firestore.

  bool _isLoading = false; // Bandera para indicar si se está realizando una operación de guardado.
  List<Map<String, dynamic>> _projects = []; // Lista de proyectos disponibles para asociar la tarea.
  Map<String, dynamic>? _selectedProjectData; // Datos del proyecto actualmente seleccionado.
  String? _selectedProjectTitle; // Título del proyecto seleccionado.
  String? _selectedPhase; // Fase seleccionada dentro del proyecto (si aplica).

  @override
  void initState() {
    super.initState();
    _loadProjects(); // Carga los proyectos disponibles al inicializar el widget.
  }

  // Carga la lista de proyectos del usuario desde Firestore, incluyendo información sobre fases.
  Future<void> _loadProjects() async {
    final projects = await _firestoreService.getAllProjectsWithPhases();
    setState(() {
      _projects = projects; // Actualiza la lista de proyectos en el estado.
    });
  }

  @override
  void dispose() {
    // Libera los recursos de los controladores de texto para evitar fugas de memoria.
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Función asíncrona para guardar la nueva tarea en Firestore.
  Future<void> _saveTask() async {
    // Valida el formulario y verifica que se haya seleccionado un proyecto.
    if (!_formKey.currentState!.validate() || _selectedProjectTitle == null) {
      return;
    }
    // Si el proyecto seleccionado tiene fases y no se ha elegido una, muestra un error.
    if (_selectedProjectData != null &&
        _selectedProjectData!['hasPhases'] == true &&
        (_selectedPhase == null || _selectedPhase!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una fase'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true); // Muestra el indicador de carga.

    try {
      // Llama al servicio de Firestore para añadir la nueva tarea.
      await _firestoreService.addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        project: _selectedProjectTitle!,
        fecha: DateTime.now(), // La fecha de creación de la tarea es la actual.
        phase: _selectedProjectData != null && _selectedProjectData!['hasPhases'] == true
            ? _selectedPhase // Asigna la fase si el proyecto la requiere.
            : null,
        projectId: _selectedProjectData!['id'], // ID del proyecto asociado.
      );
      if (mounted) {
        // Muestra un mensaje de éxito y cierra la pantalla si la operación fue exitosa.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tarea creada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Cierra el modal y retorna `true` indicando éxito.
      }
    } catch (e) {
      // Si ocurre un error, muestra un mensaje de error.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la tarea: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // Oculta el indicador de carga.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula el ancho y alto máximos para el diálogo/modal.
    final maxWidth = MediaQuery.of(context).size.width * 0.95;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Center( // Centra el contenido en la pantalla.
      child: Material( // Un widget que aplica estilos de Material Design.
        color: Colors.transparent, // Fondo transparente.
        child: Container( // Contenedor principal del formulario.
          constraints: BoxConstraints( // Define las restricciones de tamaño del contenedor.
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            minWidth: 320,
          ),
          padding: const EdgeInsets.all(24), // Relleno interno.
          decoration: BoxDecoration(
            color: Colors.white, // Color de fondo del formulario.
            borderRadius: BorderRadius.circular(24), // Bordes redondeados.
          ),
          child: SingleChildScrollView( // Permite el desplazamiento si el contenido es demasiado largo.
            child: Form( // Widget de formulario para validación de campos.
              key: _formKey, // Asigna la clave para el formulario.
              child: Column( // Organiza los campos verticalmente.
                mainAxisSize: MainAxisSize.min, // Ocupa el espacio vertical mínimo.
                crossAxisAlignment: CrossAxisAlignment.start, // Alinea los elementos al inicio.
                children: [
                  Row( // Fila para el título del modal y el botón de cerrar.
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Crear Nueva Tarea', // Título del modal.
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context), // Cierra el modal.
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), // Espacio vertical.
                  TextFormField( // Campo de texto para el título de la tarea.
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Animación 3D',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => // Validador: el título no puede estar vacío.
                        value == null || value.isEmpty ? 'Ingrese un título' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Proyecto'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>( // Selector de proyecto.
                    value: _selectedProjectTitle,
                    items: _projects
                        .map<DropdownMenuItem<String>>((project) => DropdownMenuItem<String>(
                              value: project['title'],
                              child: Text(project['title']),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProjectTitle = value;
                        // Actualiza los datos del proyecto seleccionado y resetea la fase.
                        _selectedProjectData = _projects.firstWhere((p) => p['title'] == value);
                        _selectedPhase = null;
                      });
                    },
                    validator: (value) => // Validador: debe seleccionar un proyecto.
                        value == null ? 'Seleccione un proyecto' : null,
                    decoration: const InputDecoration(
                      hintText: 'Seleccione un proyecto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  // Muestra el selector de fase solo si el proyecto seleccionado tiene fases.
                  if (_selectedProjectData != null && _selectedProjectData!['hasPhases'] == true) ...[
                    const SizedBox(height: 16),
                    const Text('Fase'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>( // Selector de fase.
                      value: _selectedPhase,
                      items: (_selectedProjectData!['phases'] as List)
                          .map<DropdownMenuItem<String>>((phase) => DropdownMenuItem<String>(
                                value: phase['title'] as String,
                                child: Text(phase['title'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPhase = value; // Actualiza la fase seleccionada.
                        });
                      },
                      validator: (value) => // Validador: debe seleccionar una fase.
                          value == null ? 'Seleccione una fase' : null,
                      decoration: const InputDecoration(
                        hintText: 'Seleccione una fase',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Descripción'),
                  const SizedBox(height: 6),
                  TextFormField( // Campo de texto para la descripción de la tarea.
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Detalles de la tarea',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4, // Permite hasta 4 líneas.
                    minLines: 2, // Mínimo 2 líneas.
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, // El botón ocupa todo el ancho disponible.
                    child: _isLoading // Muestra un indicador de carga o el botón de guardar.
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveTask, // Llama a la función para guardar la tarea.
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF4CAF50), // Color de fondo verde.
                              foregroundColor: Colors.white, // Color de texto blanco.
                            ),
                            child: const Text(
                              'Crear Tarea', // Texto del botón.
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}