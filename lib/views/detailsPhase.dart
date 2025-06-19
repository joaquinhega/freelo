import 'package:cloud_firestore/cloud_firestore.dart'; // Para interactuar con Firestore (base de datos).
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart'; // Librería principal de Flutter para UI.
import '../../services/firestore_service.dart'; 
import 'widgets/details_task.dart'; 

class DetailsPhaseScreen extends StatefulWidget {
  final Map<String, dynamic> phaseData; // Datos de la fase actual.
  final String projectId; // ID del proyecto al que pertenece la fase.
  final String phaseId; // ID de la fase.

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
  late Stream<QuerySnapshot> _tasksStream; // Stream para tareas de esta fase.

  // Controladores de texto para editar la fase.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _editing = false; // Estado de edición de la fase.
  bool _saving = false; // Estado de guardado.

  // Definición de colores principales para la UI.
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
    // Inicializa el stream de tareas y los controladores de texto con los datos de la fase.
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
    // Libera los controladores de texto al cerrar la pantalla.
    _nameController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Widget para mostrar un campo de información (no editable).
  Widget _infoField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkGrey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: lightGreen.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
          child: Text(value.isEmpty ? 'N/A' : value, style: const TextStyle(color: darkGrey)),
        ),
      ],
    );
  }

  // Widget para mostrar un campo de texto editable.
  Widget _editField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: whiteColor,
      ),
    );
  }

  // Guarda los cambios de la fase en Firestore.
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
              'date': _dateController.text.trim(),
              'id': widget.phaseId.isNotEmpty ? widget.phaseId : DateTime.now().millisecondsSinceEpoch.toString(),
            };
            phases.add(newPhase);
            await projectRef.update({'phases': phases}); // Actualiza el array de fases en el proyecto.
          }
        }
      }
      setState(() => _editing = false); // Sale del modo edición.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fase actualizada.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    }
    setState(() => _saving = false);
  }

  // Elimina la fase del proyecto.
  Future<void> _deletePhase() async {
    final confirm = await showDialog<bool>( // Pide confirmación al usuario.
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar fase?'),
        content: const Text('¿Estás seguro? Esta acción no se puede rehacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final projectRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('projects').doc(widget.projectId);
          await projectRef.update({'phases': FieldValue.arrayRemove([widget.phaseData])}); // Elimina la fase del array.
        }
        if (mounted) Navigator.of(context).pop(); // Regresa a la pantalla anterior.
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
      }
    }
  }

  // Elimina una tarea específica.
  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId); // Llama al servicio de Firestore para eliminar.
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
        title: const Text('Fase', style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold)),
        backgroundColor: whiteColor,
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit, color: primaryGreen), tooltip: 'Editar', onPressed: () => setState(() => _editing = true)), // Botón para activar edición.
          IconButton(icon: const Icon(Icons.delete, color: errorRed), tooltip: 'Eliminar fase', onPressed: _deletePhase), // Botón para eliminar fase.
        ],
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
              child: ExpansionTile( // Sección expandible para información de la fase.
                title: Text(_editing ? 'Editar Fase' : 'Información de la Fase', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: _editing ? null : const Icon(Icons.keyboard_arrow_down),
                children: [
                  const Divider(height: 25),
                  if (_editing) ...[ // Muestra campos editables y botones si está editando.
                    _editField('Nombre', _nameController),
                    _editField('Descripción', _descController),
                    _editField('Fecha', _dateController),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: _saving ? null : _savePhase, child: _saving ? const CircularProgressIndicator() : const Text('Guardar'))),
                        const SizedBox(width: 16),
                        Expanded(child: OutlinedButton(onPressed: _saving ? null : () => setState(() => _editing = false), child: const Text('Cancelar'))),
                      ],
                    ),
                  ] else ...[ // Muestra campos de solo lectura si no está editando.
                    _infoField(label: 'NOMBRE', value: phaseName),
                    const SizedBox(height: 16),
                    _infoField(label: 'DESCRIPCIÓN', value: phaseDescription),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('TAREAS DE LA FASE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkGrey)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>( // Muestra las tareas de la fase en tiempo real.
              stream: _tasksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay tareas para esta fase.'));
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
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () {
                          showDialog(context: context, builder: (context) => DetailsTaskScreen(taskData: task, taskId: taskId));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    if (task['project'] != null && (task['project'] as String).isNotEmpty)
                                      Text('Proyecto: ${task['project']}', style: const TextStyle(color: mediumGrey, fontSize: 14)),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.delete, color: errorRed), onPressed: () async {
                                final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Eliminar tarea'), content: const Text('¿Seguro?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí'))]));
                                if (confirm == true) await _deleteTask(taskId);
                              }),
                              IconButton(icon: Icon(task['isCompleted'] == true ? Icons.undo : Icons.check_circle_outline, color: task['isCompleted'] == true ? completedOrange : primaryGreen), onPressed: () async {
                                await _firestoreService.toggleTaskCompleted(taskId, !(task['isCompleted'] == true));
                              }),
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