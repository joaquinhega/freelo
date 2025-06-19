import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // Controladores para edición
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _editing = false;
  bool _saving = false;

  // Define conjunto de colores consistentes
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userTasks')
          .where('projectId', isEqualTo: widget.projectId)
          .where('phase', isEqualTo: widget.phaseData['title'])
          .snapshots();
    } else {
      _tasksStream = const Stream.empty();
    }
    _nameController.text = widget.phaseData['title'] ?? '';
    _descController.text = widget.phaseData['description'] ?? '';
    _dateController.text = widget.phaseData['date'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Widget _infoField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkGrey, 
              fontFamily: 'Montserrat'), 
        ),
        const SizedBox(height: 6), 
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: lightGreen.withOpacity(0.4), 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withOpacity(0.3)), 
          ),
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(fontSize: 16, color: darkGrey, fontFamily: 'Roboto'), 
          ),
        ),
      ],
    );
  }

  Widget _editField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), 
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'), 
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: mediumGrey), 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // More rounded borders
            borderSide: BorderSide(color: primaryGreen.withOpacity(0.6)), 
          ),
          focusedBorder: OutlineInputBorder( // Focused border style
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: whiteColor, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
        ),
      ),
    );
  }

  Future<void> _savePhase() async {
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final date = _dateController.text.trim();

    if (name.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El título de la fase es obligatorio.")),
      );
      setState(() => _saving = false);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final projectRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .doc(widget.projectId);

        final projectSnap = await projectRef.get();
        if (projectSnap.exists && projectSnap.data() != null) {
          final phases = List<Map<String, dynamic>>.from(projectSnap['phases'] ?? []);
          final oldPhaseIndex = phases.indexWhere(
            (p) => (p['id'] == widget.phaseId) || ((p['title'] ?? '') == (widget.phaseData['title'] ?? '') && widget.phaseId.isEmpty),
          );

          if (oldPhaseIndex != -1) {
            final oldPhase = phases[oldPhaseIndex];
            phases.removeAt(oldPhaseIndex); 
            
            final newPhase = {
              ...oldPhase,
              'title': name,
              'description': desc,
              'date': date,
              'id': widget.phaseId.isNotEmpty ? widget.phaseId : DateTime.now().millisecondsSinceEpoch.toString(), // Ensure ID is preserved or generated
            };
            phases.add(newPhase); 

            await projectRef.update({'phases': phases});
          }
        }
      }
      setState(() {
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fase actualizada correctamente.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
    setState(() => _saving = false);
  }

  Future<void> _deletePhase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar fase?', style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
        content: const Text('¿Estás seguro que deseas eliminar esta fase? Esta acción no se puede rehacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
          ),
        ],
        elevation: 10,
      ),
    );
    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final projectRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('projects')
              .doc(widget.projectId);

          await projectRef.update({
            'phases': FieldValue.arrayRemove([widget.phaseData])
          });
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar la fase: $e")),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tarea eliminada correctamente.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar la tarea: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseName = _nameController.text;
    final phaseDescription = _descController.text;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: darkGrey), 
        title: Text(
          'Fase',
          style: const TextStyle(
              color: darkGrey, 
              fontWeight: FontWeight.bold,
              fontSize: 24, 
              fontFamily: 'Montserrat'), 
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: whiteColor, 
        elevation: 4, 
        centerTitle: false,
        toolbarHeight: 90, 
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder( 
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit, size: 26, color: primaryGreen),
              tooltip: 'Editar fase',
              onPressed: () {
                setState(() {
                  _editing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete, size: 26, color: errorRed),
            tooltip: 'Eliminar fase',
            onPressed: _deletePhase,
          ),
        ],
      ),
      backgroundColor: offWhite, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de información/edición de la fase
            Card(
              elevation: 6, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), 
              ),
              margin: EdgeInsets.zero,
              child: ExpansionTile( 
                backgroundColor: whiteColor,
                collapsedBackgroundColor: whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Text(
                  _editing ? 'Editar Información de Fase' : 'Información de la Fase',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),
                ),
                trailing: _editing
                    ? null 
                    : const Icon(Icons.keyboard_arrow_down, size: 28, color: mediumGrey), 
                children: [
                  const Divider(height: 25, thickness: 1, color: lightGreen),
                  if (_editing) ...[
                    _editField('Nombre de la fase', _nameController),
                    _editField('Descripción', _descController),
                    _editField('Fecha de entrega', _dateController), 
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _savePhase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16), 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8, 
                              shadowColor: primaryGreen.withOpacity(0.4),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: whiteColor),
                                  )
                                : const Text('Guardar', style: TextStyle(color: whiteColor, fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                          ),
                        ),
                        const SizedBox(width: 16), 
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    setState(() {
                                      _editing = false;
                                      _nameController.text = widget.phaseData['title'] ?? '';
                                      _descController.text = widget.phaseData['description'] ?? '';
                                      _dateController.text = widget.phaseData['date'] ?? '';
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16), 
                              side: BorderSide(color: mediumGrey.withOpacity(0.6), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4, // Added shadow
                              shadowColor: mediumGrey.withOpacity(0.2),
                            ),
                            child: const Text('Cancelar', style: TextStyle(color: darkGrey, fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
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
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'TAREAS DE LA FASE',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                  fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: primaryGreen));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('No hay tareas para esta fase.',
                            style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)),
                      ));
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
                      color: whiteColor,
                      elevation: 4, 
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 0), 
                      child: InkWell( 
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => DetailsTaskScreen(
                              taskData: task,
                              taskId: taskId,
                            ),
                          );
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
                                    Text(task['title'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: darkGrey,
                                            fontFamily: 'Montserrat')),
                                    if (task['project'] != null && (task['project'] as String).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text('Proyecto: ${task['project']}',
                                            style: const TextStyle(color: mediumGrey, fontSize: 14, fontFamily: 'Roboto')),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: errorRed, size: 26), 
                                    tooltip: 'Eliminar tarea',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Eliminar tarea', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                          content: const Text('¿Estás seguro de que deseas eliminar esta tarea?', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: errorRed,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          elevation: 10,
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deleteTask(taskId);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      task['isCompleted'] == true ? Icons.undo : Icons.check_circle_outline, 
                                      color: task['isCompleted'] == true ? completedOrange : primaryGreen, 
                                      size: 26, // Larger icon
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
    );
  }
}
