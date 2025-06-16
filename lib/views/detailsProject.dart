import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

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

  final FirestoreService _firestoreService = FirestoreService();

  late Stream<QuerySnapshot> _tasksStream;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksStream = FirebaseFirestore.instance
          .collection('users') // La colección 'users' para los datos de cada usuario
          .doc(user.uid)
          .collection('userTasks') // Subcolección de tareas del usuario
          .where('projectId', isEqualTo: widget.projectId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      // Manejar el caso de usuario no autenticado (por ejemplo, devolver un Stream vacío)
      _tasksStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final projectName = widget.projectData['title'] ?? 'Proyecto Desconocido';
    final hasPhases = widget.projectData['hasPhases'] ?? false;
    final phases = (widget.projectData['phases'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final hasClient = widget.projectData['hasClient'] ?? false;
    final client = widget.projectData['client'] as Map<String, dynamic>?;

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
                                      'Entrega: ${widget.projectData['date'] ?? 'N/A'}',
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
                        const SizedBox(height: 24),
                        Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Generar factura...')),
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
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                            color: const Color(0xFFE6F2EA),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.projectData['description'] ?? 'Sin descripción',
                                            style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _infoField(
                                          label: 'FECHA',
                                          value: widget.projectData['date'] ?? 'N/A',
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
                                        if (hasClient && client != null) ...[
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
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _infoField(label: 'Nombre', value: client['nombre'] ?? ''),
                                                const SizedBox(height: 8),
                                                _infoField(label: 'Teléfono', value: client['telefono'] ?? ''),
                                                const SizedBox(height: 8),
                                                _infoField(label: 'Email', value: client['email'] ?? ''),
                                                const SizedBox(height: 8),
                                                _infoField(label: 'Notas', value: client['notas'] ?? ''),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    _showFullDetails = false;
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Editar proyecto...')),
                                                  );
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
                                                onPressed: () {
                                                  setState(() {
                                                    _showFullDetails = false;
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Eliminar proyecto...')),
                                                  );
                                                },
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