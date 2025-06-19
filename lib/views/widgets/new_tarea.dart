import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
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
  }

  Future<void> _loadProjects() async {
    final projects = await _firestoreService.getAllProjectsWithPhases();
    setState(() {
      _projects = projects;
    });
  }

  @override
  void dispose() {
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
      await _firestoreService.addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        project: _selectedProjectTitle!,
        fecha: DateTime.now(),
        phase: _selectedProjectData != null && _selectedProjectData!['hasPhases'] == true
            ? _selectedPhase
            : null,
            projectId: _selectedProjectData!['id'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tarea creada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la tarea: $e'),
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
                        'Crear Nueva Tarea',
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
                      hintText: 'Animación 3D',
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
                        'Crear Tarea',
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