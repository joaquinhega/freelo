import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

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
  List<String> _projects = [];
  String? _selectedProject;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _firestoreService.getAllProjectNames();
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
    if (!_formKey.currentState!.validate() || _selectedProject == null) return;
    setState(() => _isLoading = true);

    try {
      await _firestoreService.addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        project: _selectedProject!,
        fecha: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ¡Tarea creada con éxito!'),
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Crear Tarea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva tarea',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text('Proyecto'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedProject,
                  items: _projects
                      .map((project) => DropdownMenuItem(
                            value: project,
                            child: Text(project),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProject = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Seleccione un proyecto' : null,
                  decoration: const InputDecoration(
                    hintText: 'Seleccione un proyecto',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Título'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Animación 3D',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese un título' : null,
                ),
                const SizedBox(height: 16),
                const Text('Descripción'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Detalles de la tarea',
                  ),
                  maxLines: 3,
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
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Crear tarea',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
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