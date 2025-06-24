import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'widgets/details_task.dart';

class DetailsPhaseScreen extends StatefulWidget {
  final Map<String, dynamic> phaseData;
  final String projectId;
  final String phaseId;

  const DetailsPhaseScreen({
    super.key,
    required this.phaseData,
    required this.projectId,
    required this.phaseId,
  });

  @override
  State<DetailsPhaseScreen> createState() => _DetailsPhaseScreenState();
}

class _DetailsPhaseScreenState extends State<DetailsPhaseScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late Stream<QuerySnapshot> _tasksStream;
  late Stream<QuerySnapshot> _completedTasksStream;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _editing = false;
  bool _saving = false;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color completedOrange = Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.phaseData['title'] ?? '';
    _descController.text = widget.phaseData['description'] ?? '';
    _initTaskStreams();
  }

  void _initTaskStreams() {
    // Centraliza la consulta de tareas usando FirestoreService para evitar redundancia
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksStream = _firestoreService.getTasksByPhaseStream(
        projectId: widget.projectId,
        phaseTitle: widget.phaseData['title'],
        isCompleted: false,
      );
      _completedTasksStream = _firestoreService.getTasksByPhaseStream(
        projectId: widget.projectId,
        phaseTitle: widget.phaseData['title'],
        isCompleted: true,
      );
    } else {
      _tasksStream = const Stream.empty();
      _completedTasksStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Widget _infoField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: lightGreen.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withOpacity(0.3)),
          ),
          child: Text(value.isEmpty ? 'N/A' : value, style: const TextStyle(fontSize: 16, color: darkGrey, fontFamily: 'Roboto')),
        ),
      ],
    );
  }

  Widget _editField(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: lightGreen.withOpacity(0.4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(fontSize: 16, color: darkGrey, fontFamily: 'Roboto'),
        ),
      ],
    );
  }

  Future<void> _savePhase() async {
    setState(() => _saving = true);
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El título es obligatorio.")));
      setState(() => _saving = false);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final projectRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('projects').doc(widget.projectId);
        final projectSnap = await projectRef.get();
        if (projectSnap.exists && projectSnap.data() != null) {
          final phases = List<Map<String, dynamic>>.from(projectSnap['phases'] ?? []);
          final oldPhaseIndex = phases.indexWhere((p) => (p['id'] == widget.phaseId) || ((p['title'] ?? '') == (widget.phaseData['title'] ?? '') && widget.phaseId.isEmpty));

          if (oldPhaseIndex != -1) {
            final oldPhase = phases[oldPhaseIndex];
            phases.removeAt(oldPhaseIndex);
            final newPhase = {
              ...oldPhase,
              'title': name,
              'description': _descController.text.trim(),
              'id': widget.phaseId.isNotEmpty ? widget.phaseId : DateTime.now().millisecondsSinceEpoch.toString(),
            };
            phases.add(newPhase);
            await projectRef.update({'phases': phases});
          }
        }
      }
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fase actualizada.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    }
    setState(() => _saving = false);
  }

  Future<void> _deletePhase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar fase?', style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
        content: const Text('¿Estás seguro que deseas eliminar esta fase? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: whiteColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
          ),
        ],
        elevation: 10,
      ),
    );
    if (confirm == true) {
      try {
        await _firestoreService.deletePhase(
          projectId: widget.projectId,
          phaseData: widget.phaseData,
        );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tarea eliminada.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar tarea: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseName = _nameController.text;
    final phaseDescription = _descController.text;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: darkGrey),
        title: Text(widget.phaseData['title'] ?? 'Fase Desconocida', style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Montserrat'), overflow: TextOverflow.ellipsis),
        backgroundColor: whiteColor,
        elevation: 4,
        centerTitle: false,
        toolbarHeight: 90,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      backgroundColor: offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                backgroundColor: whiteColor,
                collapsedBackgroundColor: whiteColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Text(
                  _editing ? 'Editar Fase' : 'Información de la Fase',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 26, color: primaryGreen),
                  tooltip: 'Editar fase',
                  onPressed: _saving ? null : () => setState(() => _editing = true),
                ),
                children: [
                  const Divider(height: 25, thickness: 1, color: lightGreen),
                  if (_editing) ...[
                    _editField('NOMBRE DE LA FASE', _nameController),
                    const SizedBox(height: 16),
                    _editField('DESCRIPCIÓN', _descController, maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _savePhase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 8,
                              shadowColor: primaryGreen.withOpacity(0.4),
                            ).copyWith(
                              overlayColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return whiteColor.withOpacity(0.2);
                                  }
                                  return primaryGreen;
                                },
                              ),
                            ),
                            child: _saving
                                ? const CircularProgressIndicator(color: whiteColor)
                                : const Text('GUARDAR', style: TextStyle(fontSize: 17, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => setState(() => _editing = false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: const BorderSide(color: primaryGreen, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('CANCELAR', style: TextStyle(fontSize: 17, color: primaryGreen, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _infoField(label: 'NOMBRE DE LA FASE', value: phaseName),
                    const SizedBox(height: 16),
                    _infoField(label: 'DESCRIPCIÓN', value: phaseDescription),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _deletePhase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorRed,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: errorRed.withOpacity(0.4),
                      ).copyWith(overlayColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return whiteColor.withOpacity(0.2);
                            }
                            return errorRed;
                          },
                        ),
                      ),
                      icon: const Icon(Icons.delete, color: whiteColor, size: 24),
                      label: const Text('ELIMINAR FASE', style: TextStyle(fontSize: 17, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('TAREAS DE LA FASE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkGrey, fontFamily: 'Montserrat')),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryGreen));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay tareas pendientes para esta fase.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)));
                }

                final tasks = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index].data() as Map<String, dynamic>;
                    final taskId = tasks[index].id;
                    final isCompleted = task['isCompleted'] == true;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: whiteColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          showDialog(context: context, builder: (context) => DetailsTaskScreen(taskData: task, taskId: taskId));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        color: isCompleted ? mediumGrey : darkGrey,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: errorRed, size: 26),
                                tooltip: 'Eliminar tarea',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                      content: const Text('¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: errorRed,
                                            foregroundColor: whiteColor,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          ),
                                          child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                      elevation: 10,
                                    ),
                                  );
                                  if (confirm == true) await _deleteTask(taskId);
                                },
                              ),
                              IconButton(
                                icon: Icon(isCompleted ? Icons.undo : Icons.check_circle_outline, color: isCompleted ? completedOrange : primaryGreen, size: 26),
                                tooltip: isCompleted ? 'Marcar como pendiente' : 'Marcar como completada',
                                onPressed: () async {
                                  await _firestoreService.toggleTaskCompleted(taskId, !isCompleted);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                backgroundColor: whiteColor,
                collapsedBackgroundColor: whiteColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: const Text(
                  'TAREAS COMPLETADAS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGrey,
                    fontFamily: 'Montserrat',
                  ),
                ),
                trailing: const Icon(Icons.keyboard_arrow_down, color: darkGrey),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _completedTasksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: primaryGreen));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No hay tareas completadas para esta fase.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)));
                      }

                      final completedTasks = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: completedTasks.length,
                        itemBuilder: (context, index) {
                          final task = completedTasks[index].data() as Map<String, dynamic>;
                          final taskId = completedTasks[index].id;
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: whiteColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                showDialog(context: context, builder: (context) => DetailsTaskScreen(taskData: task, taskId: taskId));
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              decoration: TextDecoration.lineThrough,
                                              color: mediumGrey,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: errorRed, size: 26),
                                      tooltip: 'Eliminar tarea',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                            content: const Text('¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: errorRed,
                                                  foregroundColor: whiteColor,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                ),
                                                child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                            elevation: 10,
                                          ),
                                        );
                                        if (confirm == true) await _deleteTask(taskId);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.undo, color: completedOrange, size: 26),
                                      tooltip: 'Marcar como pendiente',
                                      onPressed: () async {
                                        await _firestoreService.toggleTaskCompleted(taskId, false);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}