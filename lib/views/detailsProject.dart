import 'package:firebase_auth/firebase_auth.dart'; // Autenticación de Firebase.
import 'package:flutter/material.dart'; // Widgets de Flutter para UI.
import 'package:cloud_firestore/cloud_firestore.dart'; // Base de datos Firestore.
import 'package:flutter/gestures.dart'; // Para PointerScrollEvent, gestos de entrada.
import '../services/firestore_service.dart'; 
import '../routes/routes.dart'; 
import 'widgets/details_task.dart'; 
import 'detailsPhase.dart'; 

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

  final FirestoreService _firestoreService = FirestoreService(); // Instancia del servicio de Firestore.

  late Stream<QuerySnapshot> _tasksStream; // Stream para tareas pendientes del proyecto.

  Map<String, dynamic> _projectData = {}; 
  String _projectId = ''; 

  // Definición de colores para la UI.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color completedOrange = Color(0xFFFFA726);

  // Inicializa el controlador del PageView y los datos del proyecto.
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    _projectData = Map<String, dynamic>.from(widget.projectData);
    _projectId = widget.projectId;

    _tasksStream = _firestoreService.getTasksByProjectStream(
      projectId: widget.projectId,
      isCompleted: false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Abre la pantalla de edición de proyecto y actualiza en Firestore si hay cambios.
  Future<void> _editProject() async {
    final result = await Navigator.pushNamed(
      context,
      Routes.edit_project,
      arguments: {'initialData': _projectData,}, // Pasa los datos actuales para editar.
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Proyecto actualizado correctamente.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      }
      setState(() => _saving = false); 
    }
  }

  // Elimina el proyecto de Firestore tras una confirmación.
  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog( 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar proyecto?', style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
        content: const Text('¿Estás seguro que deseas eliminar este proyecto? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
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
        await _firestoreService.deleteProject(
          userId: FirebaseAuth.instance.currentUser!.uid,
          projectId: _projectId,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
      }
    }
  }

  // Widget genérico para mostrar un campo de información (solo lectura).
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

  @override
  Widget build(BuildContext context) {
    final projectName = _projectData['title'] ?? 'Proyecto Desconocido'; 
    final hasPhases = _projectData['hasPhases'] ?? false; 
    final phases = (_projectData['phases'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? []; 
    final client = (_projectData.containsKey('client') && _projectData['client'] != null) ? _projectData['client'] as Map<String, dynamic> : null; 

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        leading: BackButton(color: darkGrey),
        title: Text(projectName, style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Montserrat'), overflow: TextOverflow.ellipsis),
        backgroundColor: whiteColor,
        elevation: 4,
        centerTitle: false,
        toolbarHeight: 90,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))), 
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                      title: const Text('Información del proyecto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 26, color: primaryGreen),
                        tooltip: 'Editar proyecto',
                        onPressed: _saving ? null : _editProject, 
                      ),
                      children: [
                        const Divider(height: 25, thickness: 1, color: lightGreen),
                        _infoField(label: 'NOMBRE DEL PROYECTO', value: _projectData['title'] ?? 'Sin nombre'),
                        const SizedBox(height: 16),
                        _infoField(label: 'DESCRIPCIÓN', value: _projectData['description'] ?? 'Sin descripción'),
                        const SizedBox(height: 16),
                        _infoField(label: 'FECHA DE ENTREGA', value: _projectData['date'] ?? 'N/A'),
                        if (_projectData['hasClient'] == true) ...[ 
                          const SizedBox(height: 24),
                          const Text('CLIENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkGrey, fontFamily: 'Montserrat')),
                          const SizedBox(height: 16),
                          _infoField(label: 'Nombre', value: (client?['nombre'] ?? '')),
                          const SizedBox(height: 16),
                          _infoField(label: 'Teléfono', value: (client?['telefono'] ?? '')),
                          const SizedBox(height: 16),
                          _infoField(label: 'Email', value: (client?['email'] ?? '')),
                          const SizedBox(height: 16),
                          _infoField(label: 'Notas', value: (client?['notas'] ?? '')),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon( 
                            onPressed: _deleteProject,
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
                            label: const Text('ELIMINAR PROYECTO', style: TextStyle(fontSize: 17, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPhases && phases.isNotEmpty) ...[ // Fases del proyecto (si existen).
                    const SizedBox(height: 30),
                    const Text('FASES DEL PROYECTO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
                    const SizedBox(height: 20),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            if (pointerSignal.scrollDelta.dy > 0) {
                              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                            } else if (pointerSignal.scrollDelta.dy < 0) {
                              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                            }
                          }
                        },
                        child: SizedBox(
                          height: 240,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: phases.length + 1, 
                            onPageChanged: (int page) {
                              setState(() => _currentPage = page);
                            },
                            itemBuilder: (context, index) {
                              if (index < phases.length) {
                                final phase = phases[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPhaseScreen(phaseData: phase, projectId: _projectId, phaseId: phase['id'] ?? '',)));
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [lightGreen, whiteColor], begin: Alignment.topLeft, end: Alignment.bottomRight,),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4),)],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${index + 1}. ${phase['title'] ?? 'Fase sin título'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
                                        const SizedBox(height: 12),
                                        const Text('Próximas tareas:', style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 16, fontFamily: 'Roboto')),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: StreamBuilder<QuerySnapshot>(
                                            stream: _firestoreService.getTasksByPhaseStream(
                                              projectId: _projectId,
                                              phaseTitle: phase['title'] ?? '',
                                              isCompleted: false,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen));
                                              }
                                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                                return const Text('Sin tareas activas', style: TextStyle(color: mediumGrey, fontSize: 14, fontStyle: FontStyle.italic));
                                              }
                                              final phaseTasks = snapshot.data!.docs;
                                              return ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: phaseTasks.length,
                                                itemBuilder: (context, idx) {
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                    child: Text('• ${(phaseTasks[idx].data() as Map<String, dynamic>)['title'] ?? ''}', style: const TextStyle(fontSize: 15, color: darkGrey, fontFamily: 'Roboto')),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                // Botón para agregar una nueva fase.
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await showDialog<Map<String, String>>(
                                      context: context,
                                      builder: (context) {
                                        final TextEditingController titleController = TextEditingController();
                                        final TextEditingController descController = TextEditingController();
                                        return AlertDialog( 
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Text('Nueva fase', style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))), labelStyle: TextStyle(color: mediumGrey)), style: const TextStyle(color: darkGrey, fontFamily: 'Roboto')),
                                                const SizedBox(height: 12),
                                                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))), labelStyle: TextStyle(color: mediumGrey)), style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'), maxLines: 2,),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
                                            ElevatedButton(onPressed: () {
                                                if (titleController.text.trim().isEmpty) return; 
                                                Navigator.pop(context, {'title': titleController.text.trim(), 'description': descController.text.trim(),});
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 5,),
                                              child: const Text('Agregar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                          elevation: 10,
                                        );
                                      },
                                    );
                                    if (result != null && result['title'] != null && result['title']!.isNotEmpty) {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        final projectRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('projects').doc(_projectId);
                                        await projectRef.update({
                                          'phases': FieldValue.arrayUnion([ // Añade la nueva fase al array en Firestore.
                                            {'id': DateTime.now().millisecondsSinceEpoch.toString(), 'title': result['title'], 'description': result['description'], 'date': 'N/A',}
                                          ])
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: lightGreen.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: primaryGreen, width: 2),
                                      boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3),)],
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.add_circle_outline, color: primaryGreen, size: 45),
                                          SizedBox(height: 15),
                                          Text('Nueva fase', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Montserrat'),),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        phases.length + 1, 
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: _currentPage == index ? 12.0 : 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? primaryGreen : mediumGrey.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const Text('TAREAS PENDIENTES DEL PROYECTO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>( // Sección para tareas pendientes del proyecto.
                    stream: _tasksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: primaryGreen));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No hay tareas pendientes para este proyecto.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)));
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                            child: InkWell(
                              onTap: () {
                                // Muestra los detalles de la tarea en un diálogo.
                                showDialog(context: context, builder: (context) => DetailsTaskScreen(taskData: task, taskId: taskId),);
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
                                          Text(task['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: darkGrey, fontSize: 16, fontFamily: 'Montserrat'),),
                                          if (task['phase'] != null && (task['phase'] as String).isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text('Fase: ${task['phase']}', style: TextStyle(color: mediumGrey, fontSize: 14, fontFamily: 'Roboto')),
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
                                                content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
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
                                              )
                                            );
                                            if (confirm == true) await _firestoreService.deleteTask(taskId);
                                          }
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: primaryGreen, size: 26),
                                          tooltip: 'Completar tarea',
                                          onPressed: () async {
                                            await _firestoreService.toggleTaskCompleted(taskId, true);
                                          },
                                        ),
                                      ]
                                    )
                                  ]
                                )
                              )
                            )
                          );
                        }
                      );
                    }
                  ),
                  const SizedBox(height: 30),
                  // Sección para tareas completadas del proyecto.
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
                      title: const Text(
                        'TAREAS COMPLETADAS DEL PROYECTO',
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
                        stream: _firestoreService.getTasksByProjectStream(
                          projectId: _projectId,
                          isCompleted: true,
                        ),
                        builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: primaryGreen));
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text('No hay tareas completadas para este proyecto.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)));
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
                                                if (task['phase'] != null && (task['phase'] as String).isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text('Fase: ${task['phase']}', style: TextStyle(color: mediumGrey, fontSize: 14, fontFamily: 'Roboto')),
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
                                              if (confirm == true) await _firestoreService.deleteTask(taskId);
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
                  if (_projectData['hasClient'] == true && client != null) ...[
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Envía los datos del cliente y del proyecto a la pantalla de facturación
                          Navigator.pushNamed(
                            context,
                            '/facturacion',
                            arguments: {
                              'projectId': _projectId,
                              'projectName': _projectData['title'] ?? '',
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3), // Azul
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: const Color(0xFF2196F3).withOpacity(0.3),
                        ).copyWith(
                          overlayColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.white.withOpacity(0.2);
                              }
                              return const Color(0xFF2196F3);
                            },
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                        label: const Text(
                          'FACTURAR',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}