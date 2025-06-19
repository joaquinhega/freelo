import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> initialTaskData;

  const EditTaskScreen({
    super.key,
    required this.taskId,
    required this.initialTaskData,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  // Controladores de texto para los campos del formulario
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _projects = [];
  Map<String, dynamic>? _selectedProjectData;
  String? _selectedProjectTitle;
  String? _selectedPhase;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _titleController.text = widget.initialTaskData['title'] ?? '';
    _descriptionController.text = widget.initialTaskData['description'] ?? '';
    _selectedProjectTitle = widget.initialTaskData['project'];
    _selectedPhase = widget.initialTaskData['phase'];
  }

  Future<void> _loadProjects() async { // Cargar proyectos desde Firestore
    final projects = await _firestoreService.getAllProjectsWithPhases();
    setState(() {
      _projects = projects;
      if (_selectedProjectTitle != null) {
        _selectedProjectData = _projects.firstWhere(
          (p) => p['title'] == _selectedProjectTitle,
          orElse: () => {},
        );
      }
    });
  }

  @override
  void dispose() { // Limpiar controladores al cerrar el widget
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || _selectedProjectTitle == null) {
      return;
    }
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

    setState(() => _isLoading = true);

    try {
      await _firestoreService.updateTask(
        taskId: widget.taskId,
        data: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'project': _selectedProjectTitle!,
          'phase': _selectedProjectData != null && _selectedProjectData!['hasPhases'] == true
              ? _selectedPhase
              : null,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Tarea actualizada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('[edit_task] Error al editar tarea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al editar la tarea: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              key: _formKey,
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                    child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
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