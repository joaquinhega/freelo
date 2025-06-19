import 'package:flutter/material.dart'; // Importa la librería base de Flutter.
import '../../services/firestore_service.dart'; // Importa el servicio para interactuar con Firestore.

// `EditTaskScreen` es un StatefulWidget para permitir la edición de una tarea.
class EditTaskScreen extends StatefulWidget {
  final String taskId; // ID de la tarea a editar.
  final Map<String, dynamic> initialTaskData; // Datos iniciales de la tarea para prellenar el formulario.

  const EditTaskScreen({
    super.key,
    required this.taskId,
    required this.initialTaskData,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState(); // Crea el estado del widget.
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave global para validar el formulario.
  final TextEditingController _titleController = TextEditingController(); // Controlador para el campo de título.
  final TextEditingController _descriptionController = TextEditingController(); // Controlador para el campo de descripción.

  final FirestoreService _firestoreService = FirestoreService(); // Instancia del servicio Firestore.

  bool _isLoading = false; // Bandera para controlar el estado de carga.
  List<Map<String, dynamic>> _projects = []; // Lista de proyectos disponibles.
  Map<String, dynamic>? _selectedProjectData; // Datos del proyecto seleccionado.
  String? _selectedProjectTitle; // Título del proyecto seleccionado.
  String? _selectedPhase; // Fase seleccionada (si aplica).

  @override
  void initState() {
    super.initState();
    _loadProjects(); // Carga los proyectos al inicializar el widget.
    // Inicializa los controladores con los datos de la tarea recibida.
    _titleController.text = widget.initialTaskData['title'] ?? '';
    _descriptionController.text = widget.initialTaskData['description'] ?? '';
    _selectedProjectTitle = widget.initialTaskData['project'];
    _selectedPhase = widget.initialTaskData['phase'];
  }

  // Carga todos los proyectos con sus fases desde Firestore.
  Future<void> _loadProjects() async {
    final projects = await _firestoreService.getAllProjectsWithPhases();
    setState(() {
      _projects = projects;
      // Si ya hay un proyecto seleccionado, busca sus datos completos.
      if (_selectedProjectTitle != null) {
        _selectedProjectData = _projects.firstWhere(
          (p) => p['title'] == _selectedProjectTitle,
          orElse: () => {}, // Retorna un mapa vacío si no se encuentra.
        );
      }
    });
  }

  @override
  void dispose() {
    // Limpia los controladores de texto para evitar fugas de memoria.
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Guarda los cambios en la tarea.
  Future<void> _saveTask() async {
    // Valida el formulario y asegura que un proyecto esté seleccionado.
    if (!_formKey.currentState!.validate() || _selectedProjectTitle == null) {
      return;
    }
    // Si el proyecto tiene fases y no se seleccionó una, muestra una advertencia.
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

    setState(() => _isLoading = true); // Activa el indicador de carga.

    try {
      // Llama al servicio de Firestore para actualizar la tarea con los nuevos datos.
      await _firestoreService.updateTask(
        taskId: widget.taskId,
        data: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'project': _selectedProjectTitle!,
          'phase': _selectedProjectData != null && _selectedProjectData!['hasPhases'] == true
              ? _selectedPhase
              : null, // Asigna la fase solo si el proyecto la requiere.
        },
      );
      if (mounted) {
        // Muestra un mensaje de éxito y cierra la pantalla.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Tarea actualizada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna `true` indicando éxito.
      }
    } catch (e) {
      print('[edit_task] Error al editar tarea: $e'); // Imprime el error en la consola.
      if (mounted) {
        // Muestra un mensaje de error si la actualización falla.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al editar la tarea: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // Desactiva el indicador de carga.
    }
  }

  @override
  Widget build(BuildContext context) { // Corregido: `BuildContext: Context` a `BuildContext context`
    // Calcula el ancho y alto máximo del diálogo basado en el tamaño de la pantalla.
    final maxWidth = MediaQuery.of(context).size.width * 0.95;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            minWidth: 320,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey, // Asocia la clave del formulario.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Editar Tarea',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context), // Cierra el diálogo.
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Campo de texto para el título de la tarea.
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Ingrese un título' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Proyecto'),
                  const SizedBox(height: 6),
                  // Dropdown para seleccionar el proyecto.
                  DropdownButtonFormField<String>(
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
                    validator: (value) =>
                        value == null ? 'Seleccione un proyecto' : null,
                    decoration: const InputDecoration(
                      hintText: 'Seleccione un proyecto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  // Muestra el Dropdown de fases solo si el proyecto seleccionado las tiene.
                  if (_selectedProjectData != null && _selectedProjectData!['hasPhases'] == true) ...[
                    const SizedBox(height: 16),
                    const Text('Fase'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedPhase,
                      items: (_selectedProjectData!['phases'] as List)
                          .map<DropdownMenuItem<String>>((phase) => DropdownMenuItem<String>(
                                value: phase['title'] as String,
                                child: Text(phase['title'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPhase = value;
                        });
                      },
                      validator: (value) =>
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
                  // Campo de texto para la descripción de la tarea.
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Detalles de la tarea',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    minLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading // Muestra un indicador de carga o el botón.
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
                              'Guardar Cambios',
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