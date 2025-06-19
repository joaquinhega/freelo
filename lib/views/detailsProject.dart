import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../routes/routes.dart';
import 'widgets/details_task.dart';

class DetailsProjectScreen extends StatefulWidget {
  final Map<String, dynamic> projectData;
  final String projectId;

  const DetailsProjectScreen({
    super.key,
    required this.projectData,
    required this.projectId,
  });

  @override
  State<DetailsProjectScreen> createState() => _DetailsProjectScreenState();
}

class _DetailsProjectScreenState extends State<DetailsProjectScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _saving = false;

  final FirestoreService _firestoreService = FirestoreService();

  late Stream<QuerySnapshot> _tasksStream;

  Map<String, dynamic> _projectData = {};
  String _projectId = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);

    _projectData = Map<String, dynamic>.from(widget.projectData);
    _projectId = widget.projectId;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userTasks')
          .where('projectId', isEqualTo: widget.projectId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      _tasksStream = const Stream.empty();
    }
  }

  Future<void> _editProject() async {
    final result = await Navigator.pushNamed(
      context,
      Routes.edit_project,
      arguments: {
        'initialData': _projectData,
      },
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() => _saving = true);
      try {
        await _firestoreService.updateProject(
          userId: FirebaseAuth.instance.currentUser!.uid,
          projectId: _projectId,
          data: result,
        );
        setState(() {
          _projectData = {..._projectData, ...result};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proyecto actualizado correctamente.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
      }
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('¿Eliminar proyecto?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro que deseas eliminar este proyecto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestoreService.deleteProject(
          userId: FirebaseAuth.instance.currentUser!.uid,
          projectId: _projectId,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: $e")),
        );
      }
    }
  }

  Widget _infoField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: TextStyle(fontSize: 16, color: Colors.grey[900]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectName = _projectData['title'] ?? 'Proyecto Desconocido';
    final hasPhases = _projectData['hasPhases'] ?? false;
    final phases = (_projectData['phases'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final client = (_projectData.containsKey('client') && _projectData['client'] != null)
        ? _projectData['client'] as Map<String, dynamic>
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          projectName,
          style: const TextStyle(color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExpansionTile(
                    title: const Text(
                      'Información del proyecto',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoField(label: 'NOMBRE DEL PROYECTO', value: _projectData['title'] ?? 'Sin nombre'),
                            const SizedBox(height: 8),
                            _infoField(label: 'DESCRIPCIÓN', value: _projectData['description'] ?? 'Sin descripción'),
                            const SizedBox(height: 8),
                            _infoField(label: 'FECHA DE ENTREGA', value: _projectData['date'] ?? 'N/A'),
                            if (_projectData['hasClient'] == true) ...[
                              const SizedBox(height: 16),
                              const Text('CLIENTE', style: TextStyle(fontWeight: FontWeight.bold)),
                              _infoField(label: 'Nombre', value: (_projectData['client']?['nombre'] ?? '')),
                              _infoField(label: 'Teléfono', value: (_projectData['client']?['telefono'] ?? '')),
                              _infoField(label: 'Email', value: (_projectData['client']?['email'] ?? '')),
                              _infoField(label: 'Notas', value: (_projectData['client']?['notas'] ?? '')),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _saving ? null : _editProject,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    label: const Text('EDITAR',
                                        style: TextStyle(fontSize: 16, color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _deleteProject,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    label: const Text('ELIMINAR',
                                        style: TextStyle(fontSize: 16, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasPhases && phases.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'FASES',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: phases.length,
                        onPageChanged: (int page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        itemBuilder: (context, index) {
                          final phase = phases[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F2EA),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${phase['title'] ?? 'Fase sin título'}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Entrega: ${_projectData['date'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Próximas tareas:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        phases.length,
                        (index) => Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'TAREAS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _tasksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No hay tareas para este proyecto.'));
                      }

                      final tasks = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index].data() as Map<String, dynamic>;
                          final taskId = tasks[index].id;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(task['title'] ?? ''),
                              subtitle: (task['phase'] != null && (task['phase'] as String).isNotEmpty)
                                  ? Text('Fase: ${task['phase']}')
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Eliminar tarea',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Eliminar tarea'),
                                          content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _firestoreService.deleteTask(taskId);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      task['isCompleted'] == true ? Icons.undo : Icons.check,
                                      color: task['isCompleted'] == true ? Colors.orange : Colors.green,
                                    ),
                                    tooltip: task['isCompleted'] == true
                                        ? 'Marcar como pendiente'
                                        : 'Completar tarea',
                                    onPressed: () async {
                                      await _firestoreService.toggleTaskCompleted(
                                        taskId,
                                        !(task['isCompleted'] == true),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => DetailsTaskScreen(
                                    taskData: task,
                                    taskId: taskId,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ExpansionTile(
                    title: const Text(
                      'Ver tareas completadas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('userTasks')
                            .where('projectId', isEqualTo: widget.projectId)
                            .where('isCompleted', isEqualTo: true)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('No hay tareas completadas.'),
                            );
                          }
                          final completedTasks = snapshot.data!.docs;
                          // Usar Column en vez de ListView.builder para evitar problemas de scroll anidado
                          return Column(
                            children: completedTasks.map((doc) {
                              final task = doc.data() as Map<String, dynamic>;
                              return ListTile(
                                title: Text(
                                  task['title'] ?? '',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                subtitle: (task['phase'] != null && (task['phase'] as String).isNotEmpty)
                                    ? Text(
                                        'Fase: ${task['phase']}',
                                        style: const TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : null,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          Routes.facturacion,
                          arguments: {
                            'projectId': _projectId,
                            'projectName': projectName,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text(
                        'Facturar',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}