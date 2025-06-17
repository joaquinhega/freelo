import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/views/detailsProject.dart';
import 'package:myapp/views/new_client.dart';
import '../services/firestore_service.dart';
import 'widgets/Footer.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<QuerySnapshot> projectsStream;

  @override
  void initState() {
    super.initState();
    projectsStream = _firestoreService.getProjectsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: const Footer(currentIndex: 2),
      body: StreamBuilder<QuerySnapshot>(
        stream: projectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar proyectos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay proyectos aún.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot document = snapshot.data!.docs[index];
              final data = document.data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsProjectScreen(
                        projectData: data,
                        projectId: document.id,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Sin título',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['description'] ?? 'Sin descripción',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        if (data['date'] != null && data['date'].isNotEmpty)
                          Text(
                            'Fecha de Entrega: ${data['date']}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        if (data['hasPhases'] == true && (data['phases'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fases:', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...(data['phases'] as List).map((phase) {
                                  return Text('  • ${phase['title']}');
                                }).toList(),
                              ],
                            ),
                          ),
                        // Cliente y duración eliminados
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NewClientScreen()));
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar Proyecto',
      ),
    );
  }
}