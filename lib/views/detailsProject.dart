import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../routes/routes.dart';

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
  bool _showFullDetails = false;
  bool _editing = false;
  bool _saving = false;

  final FirestoreService _firestoreService = FirestoreService();

  late Stream<QuerySnapshot> _tasksStream;

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final TextEditingController _projectDateController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientNotasController = TextEditingController();

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
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      _tasksStream = const Stream.empty();
    }
    _initControllers();
  }

  void _initControllers() {
    _projectNameController.text = _projectData['title'] ?? '';
    _projectDescriptionController.text = _projectData['description'] ?? '';
    _projectDateController.text = _projectData['date'] ?? '';
    final client = _projectData['client'] ?? {};
    _clientNameController.text = client['nombre'] ?? '';
    _clientPhoneController.text = client['telefono'] ?? '';
    _clientEmailController.text = client['email'] ?? '';
    _clientNotasController.text = client['notas'] ?? '';
  }

  void _restoreControllers() {
    _initControllers();
  }

  Future<void> _saveProjectEdits() async {
    setState(() => _saving = true);

    final updatedClient = {
      'nombre': _clientNameController.text.trim(),
      'telefono': _clientPhoneController.text.trim(),
      'email': _clientEmailController.text.trim(),
      'notas': _clientNotasController.text.trim(),
    };

    final updatedData = {
      'title': _projectNameController.text.trim(),
      'description': _projectDescriptionController.text.trim(),
      'date': _projectDateController.text.trim(),
      'client': updatedClient,
      'hasClient': true,
    };

    try {
      await _firestoreService.updateProject(
        userId: FirebaseAuth.instance.currentUser!.uid,
        projectId: _projectId,
        data: updatedData,
      );
      setState(() {
        _editing = false;
        _projectData['title'] = updatedData['title'];
        _projectData['description'] = updatedData['description'];
        _projectData['date'] = updatedData['date'];
        _projectData['client'] = updatedClient;
        _projectData['hasClient'] = true;
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

  @override
  void dispose() {
    _pageController.dispose();
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    _projectDateController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientNotasController.dispose();
    super.dispose();
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

  Widget _editField(String label, TextEditingController controller, {TextInputType? keyboardType, bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: isDate,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        onTap: isDate
            ? () async {
                FocusScope.of(context).requestFocus(FocusNode());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.text.isNotEmpty
                      ? DateTime.tryParse(controller.text.split('/').reversed.join('-')) ?? DateTime.now()
                      : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                }
              }
            : null,
      ),
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
    final hasClient = _projectData['hasClient'] ?? false;
    final client = (_projectData.containsKey('client') && _projectData['client'] != null)
        ? _projectData['client'] as Map<String, dynamic>
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          projectName,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFullDetails
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _showFullDetails = !_showFullDetails;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasPhases && phases.isNotEmpty) ...[
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
                          const SizedBox(height: 24),
                        ],
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
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    title: Text(task['title'] ?? 'Tarea sin título'),
                                    subtitle: Text(task['description'] ?? 'Sin descripción'),
                                    trailing: Checkbox(
                                      value: task['isCompleted'] ?? false,
                                      onChanged: null,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                                print('[detailsProject] Navegando a facturación con projectId=$_projectId, projectName=$projectName');
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
                ),
              );
            },
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showFullDetails ? 0 : -MediaQuery.of(context).size.height,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_showFullDetails,
              child: Opacity(
                opacity: _showFullDetails ? 1 : 0,
                child: Material(
                  color: Colors.white,
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight - 56,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          projectName,
                                          style: const TextStyle(
                                            fontSize: 22, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'DESCRIPCION',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        if (_editing)
                                          _editField('Descripción', _projectDescriptionController)
                                        else
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE6F2EA),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _projectData['description'] ?? 'Sin descripción',
                                              style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                                            ),
                                          ),
                                          if (_editing)
                                            _editField('Fecha de Entrega', _projectDateController, isDate: true)
                                          else
                                            _infoField(
                                              label: 'FECHA DE ENTREGA',
                                              value: _projectData['date'] ?? 'N/A',
                                            ),
                                        const SizedBox(height: 24),
                                        if (hasPhases && phases.isNotEmpty) ...[
                                          const Text(
                                            'FASES',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: phases.map((phase) {
                                              return Chip(
                                                label: Text(phase['title'] ?? 'Fase'),
                                                backgroundColor: const Color(0xFFE6F2EA),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  side: BorderSide.none,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        if (hasClient || _editing) ...[
                                          const Text(
                                            'CLIENTE',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE6F2EA),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: _editing
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _editField('Nombre', _clientNameController),
                                                      _editField('Teléfono', _clientPhoneController, keyboardType: TextInputType.phone),
                                                      _editField('Email', _clientEmailController, keyboardType: TextInputType.emailAddress),
                                                      _editField('Notas', _clientNotasController),
                                                    ],
                                                  )
                                                : Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _infoField(label: 'Nombre', value: client?['nombre'] ?? ''),
                                                      const SizedBox(height: 8),
                                                      _infoField(label: 'Teléfono', value: client?['telefono'] ?? ''),
                                                      const SizedBox(height: 8),
                                                      _infoField(label: 'Email', value: client?['email'] ?? ''),
                                                      const SizedBox(height: 8),
                                                      _infoField(label: 'Notas', value: client?['notas'] ?? ''),
                                                    ],
                                                  ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        const Spacer(),
                                        if (_editing)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: _saving ? null : _saveProjectEdits,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: _saving
                                                      ? const SizedBox(
                                                          height: 20,
                                                          width: 20,
                                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                        )
                                                      : const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: _saving
                                                      ? null
                                                      : () {
                                                          setState(() {
                                                            _editing = false;
                                                            _restoreControllers();
                                                          });
                                                        },
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    side: const BorderSide(color: Colors.grey),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: const Text('Cancelar', style: TextStyle(color: Colors.black, fontSize: 16)),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _editing = true;
                                                    });
                                                  },
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
                                        const SizedBox(height: 40),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}