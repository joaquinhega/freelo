import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final FirestoreService _firestoreService = FirestoreService();

  late Stream<QuerySnapshot> _tasksStream;

  Map<String, dynamic> _projectData = {};
  String _projectId = '';

  // Define a consistent color palette based on green and white
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep Green (from logo)
  static const Color lightGreen = Color(0xFFE8F5E9); // Very light green for subtle backgrounds/accents
  static const Color whiteColor = Colors.white; // Pure white
  static const Color offWhite = Color(0xFFF0F2F5); // Slightly off-white for background
  static const Color darkGrey = Color(0xFF212121); // Dark grey for primary text
  static const Color mediumGrey = Color(0xFF616161); // Medium grey for secondary text
  static const Color errorRed = Color(0xFFD32F2F); // Red for errors/deletions
  static const Color completedOrange = Color(0xFFF57C00); // Orange for completed/undo
  static const Color softGrey = Color(0xFFE0E0E0); // Lighter grey for subtle backgrounds
  static const Color darkGreenGradientStart = Color(0xFF1B5E20); // Darker green for gradients
  static const Color darkGreenGradientEnd = Color(0xFF2E7D32); // Primary green for gradients


  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85); // Adjusted viewportFraction for better spacing

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
          //.orderBy('timestamp', descending: true) // Removed orderBy to prevent potential errors. Sort in-memory if needed.
          .snapshots();
    } else {
      _tasksStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        title: const Text('¿Eliminar proyecto?', style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
        content: const Text('¿Estás seguro que deseas eliminar este proyecto? Esta acción no se puede deshacer.', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5, // Added shadow
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
          ),
        ],
        elevation: 10, // Added shadow to dialog
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
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkGrey, // Changed to darkGrey
              fontFamily: 'Montserrat'), // Consistent font
        ),
        const SizedBox(height: 6), // Adjusted spacing
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Increased padding
          decoration: BoxDecoration(
            color: lightGreen.withOpacity(0.4), // Softer light green with opacity
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withOpacity(0.3)), // Subtle border
          ),
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(fontSize: 16, color: darkGrey, fontFamily: 'Roboto'), // Changed to darkGrey, consistent font
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
      backgroundColor: offWhite, // Scaffold background color
      appBar: AppBar(
        leading: BackButton(color: darkGrey), // Back button color
        title: Text(
          projectName,
          style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Montserrat'), // Title style
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: whiteColor, // App bar background
        elevation: 4, // More pronounced shadow for app bar
        centerTitle: false, // Align title to start
        toolbarHeight: 90, // Increase app bar height
        surfaceTintColor: Colors.transparent, // Remove default surface tint
        shape: const RoundedRectangleBorder( // Rounded bottom corners for app bar
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
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
                  // Información del proyecto
                  Card( // Wrapped in Card for consistent styling
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: EdgeInsets.zero,
                    child: ExpansionTile( // Using ExpansionTile for collapsible content
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
                      title: const Text(
                        'Información del proyecto',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),
                      ),
                      trailing: IconButton( 
                        icon: const Icon(Icons.edit, size: 26, color: primaryGreen),
                        tooltip: 'Editar proyecto',
                        onPressed: _saving ? null : _editProject,
                      ),
                      children: [
                        const Divider(height: 25, thickness: 1, color: lightGreen), // Visual separator
                        _infoField(label: 'NOMBRE DEL PROYECTO', value: _projectData['title'] ?? 'Sin nombre'),
                        const SizedBox(height: 16), // Increased spacing
                        _infoField(label: 'DESCRIPCIÓN', value: _projectData['description'] ?? 'Sin descripción'),
                        const SizedBox(height: 16), // Increased spacing
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
                              padding: const EdgeInsets.symmetric(vertical: 18), // Larger padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8, // Added shadow
                              shadowColor: errorRed.withOpacity(0.4),
                            ).copyWith(
                              overlayColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return whiteColor.withOpacity(0.2);
                                  }
                                  return errorRed;
                                },
                              ),
                            ),
                            icon: const Icon(Icons.delete, color: whiteColor, size: 24), // Larger icon
                            label: const Text('ELIMINAR PROYECTO',
                                style: TextStyle(fontSize: 17, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPhases && phases.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      'FASES DEL PROYECTO',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'), // Larger and bolder title
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 240, // Increased height for phases
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: phases.length + 1,
                        onPageChanged: (int page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        itemBuilder: (context, index) {
                          if (index < phases.length) {
                            final phase = phases[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailsPhaseScreen(
                                      phaseData: phase,
                                      projectId: _projectId,
                                      phaseId: phase['id'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10.0), // Increased horizontal margin
                                padding: const EdgeInsets.all(20), // Increased padding
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient( // Added gradient to phase cards
                                    colors: [lightGreen, whiteColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18), // More rounded corners
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3), // More prominent shadow
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. ${phase['title'] ?? 'Fase sin título'}',
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'), // Larger and bolder
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Próximas tareas:',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 16, fontFamily: 'Roboto'), // Green and bolder
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded( // Use Expanded to give StreamBuilder a bounded height
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth.instance.currentUser!.uid)
                                            .collection('userTasks')
                                            .where('projectId', isEqualTo: _projectId)
                                            .where('phase', isEqualTo: phase['title'])
                                            .where('isCompleted', isEqualTo: false)
                                            //.orderBy('timestamp', descending: true) // Removed orderBy
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen));
                                          }
                                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                            return const Text(
                                              'Sin tareas activas',
                                              style: TextStyle(color: mediumGrey, fontSize: 14, fontStyle: FontStyle.italic), // Italic
                                            );
                                          }
                                          final phaseTasks = snapshot.data!.docs;
                                          return ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: phaseTasks.length,
                                            itemBuilder: (context, idx) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: Text(
                                                  '• ${(phaseTasks[idx].data() as Map<String, dynamic>)['title'] ?? ''}',
                                                  style: const TextStyle(
                                                      fontSize: 15, color: darkGrey, fontFamily: 'Roboto'),
                                                ),
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
                            // Tarjeta "Nueva fase"
                            return GestureDetector(
                              onTap: () async {
                                // Modal para agregar nueva fase
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
                                            TextField(
                                              controller: titleController,
                                              decoration: const InputDecoration(
                                                labelText: 'Título',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                                labelStyle: TextStyle(color: mediumGrey),
                                              ),
                                              style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'),
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: descController,
                                              decoration: const InputDecoration(
                                                labelText: 'Descripción',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                                labelStyle: TextStyle(color: mediumGrey),
                                              ),
                                              style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'),
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (titleController.text.trim().isEmpty) return;
                                            Navigator.pop(context, {
                                              'title': titleController.text.trim(),
                                              'description': descController.text.trim(),
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryGreen,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 5,
                                          ),
                                          child: const Text('Agregar', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                      elevation: 10,
                                    );
                                  },
                                );
                                if (result != null && result['title'] != null && result['title']!.isNotEmpty) {
                                  // Agregar la nueva fase al proyecto en Firestore
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    final projectRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('projects')
                                        .doc(_projectId);

                                    await projectRef.update({
                                      'phases': FieldValue.arrayUnion([
                                        {
                                          'id': DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID for the new phase
                                          'title': result['title'],
                                          'description': result['description'],
                                          'date': 'N/A', // Assuming date is not part of add phase flow
                                        }
                                      ])
                                    });
                                    // No es necesario actualizar la UI localmente aquí, el StreamBuilder lo hará automáticamente.
                                  }
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: lightGreen.withOpacity(0.3), // Softer background for new phase card
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: primaryGreen, width: 2), // Green border
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withOpacity(0.2), // Shadow related to green
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_circle_outline, color: primaryGreen, size: 45), // Green icon
                                      SizedBox(height: 15),
                                      Text(
                                        'Nueva fase',
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        phases.length + 1, // +1 for the "Nueva fase" card
                        (index) => AnimatedContainer( // Animated dots for page indicator
                          duration: const Duration(milliseconds: 150),
                          width: _currentPage == index ? 12.0 : 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? primaryGreen // Active dot color
                                : mediumGrey.withOpacity(0.4), // Inactive dot color
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const Text(
                    'TAREAS PENDIENTES DEL PROYECTO',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'), // Larger and bolder title
                  ),
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
                            elevation: 4, // More pronounced shadow
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                            child: InkWell( // Added InkWell for ripple effect
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
                                          Text(
                                            task['title'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: darkGrey, fontSize: 16, fontFamily: 'Montserrat'),
                                          ),
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
                                          icon: const Icon(Icons.delete, color: errorRed, size: 26), // Larger, error color
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
                                              await _firestoreService.deleteTask(taskId);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            task['isCompleted'] == true ? Icons.undo : Icons.check_circle_outline, // Changed icon for better visibility
                                            color: task['isCompleted'] == true ? completedOrange : primaryGreen, // Dynamic color
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
                  const SizedBox(height: 24),
                  // Ver tareas completadas
                  Card( // Replaced ExpansionTile with a Card for a cleaner look
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: EdgeInsets.zero,
                    child: ExpansionTile( // Kept ExpansionTile for expand/collapse functionality
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
                      title: const Text(
                        'Ver tareas completadas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat'),
                      ),
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('userTasks')
                              .where('projectId', isEqualTo: widget.projectId)
                              .where('isCompleted', isEqualTo: true)
                              //.orderBy('timestamp', descending: true) // Removed orderBy
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: primaryGreen));
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text('No hay tareas completadas para este proyecto.', style: TextStyle(color: mediumGrey, fontSize: 16, fontStyle: FontStyle.italic)),
                              );
                            }
                            final completedTasks = snapshot.data!.docs;
                            return Column(
                              children: completedTasks.map((doc) {
                                final task = doc.data() as Map<String, dynamic>;
                                return ListTile(
                                  title: Text(
                                    task['title'] ?? '',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: mediumGrey,
                                      fontFamily: 'Roboto',
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: (task['phase'] != null && (task['phase'] as String).isNotEmpty)
                                      ? Text(
                                          'Fase: ${task['phase']}',
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: mediumGrey,
                                            fontFamily: 'Roboto',
                                            fontSize: 14,
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
                  ),
                  const SizedBox(height: 24), // Increased spacing
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
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 18), // Larger padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8, // Added shadow
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
                      icon: const Icon(Icons.receipt_long, color: whiteColor, size: 24), // Larger icon
                      label: const Text(
                        'FACTURAR PROYECTO',
                        style: TextStyle(fontSize: 17, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
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