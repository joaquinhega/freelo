import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/views/detailsProject.dart';
import 'package:myapp/views/new_client.dart';
import '../services/firestore_service.dart';
import 'widgets/Footer.dart';
import '../routes/routes.dart'; 

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<QuerySnapshot> projectsStream;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9); 
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F); 

  @override
  void initState() {
    super.initState();
    projectsStream = _firestoreService.getProjectsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        title: const Text(
          'Proyectos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            fontFamily: 'Montserrat', 
          ),
        ),
        automaticallyImplyLeading: false,
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
          IconButton(
            icon: const Icon(Icons.receipt_long, color: primaryGreen), // Icono de factura
            onPressed: () {
              Navigator.pushNamed(context, Routes.invoices);
            },
          ),
        ],
      ),
      bottomNavigationBar: const Footer(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const NewClientScreen()));
        },
        backgroundColor: primaryGreen, 
        foregroundColor: whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 8, 
        highlightElevation: 12, 
        splashColor: lightGreen,
        tooltip: 'Agregar Proyecto',
        child: const Icon(Icons.add, size: 30), 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: projectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar proyectos: ${snapshot.error}',
                    style: TextStyle(color: errorRed, fontSize: 18, fontFamily: 'Roboto'))); 
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('No hay proyectos aún.',
                    style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic))); 
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), 
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot document = snapshot.data!.docs[index];
              final data = document.data() as Map<String, dynamic>;

              return Card(
                elevation: 6, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), 
                ),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                color: whiteColor,
                child: InkWell( 
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
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(18), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Sin título',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkGrey, // Text color
                              fontFamily: 'Montserrat'), 
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['description'] ?? 'Sin descripción',
                          style: TextStyle(
                              fontSize: 15, 
                              color: mediumGrey,
                              fontFamily: 'Roboto'), 
                        ),
                        const SizedBox(height: 8),
                        if (data['date'] != null && data['date'].isNotEmpty)
                          Text(
                            'Fecha de Entrega: ${data['date']}',
                            style:
                                const TextStyle(fontSize: 14, color: mediumGrey, fontFamily: 'Roboto'), 
                          ),
                        if (data['hasPhases'] == true &&
                            (data['phases'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fases:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGrey,
                                        fontFamily: 'Montserrat')), 
                                ...(data['phases'] as List).map((phase) {
                                  return Text('  • ${phase['title']}',
                                      style: TextStyle(
                                          color: mediumGrey, fontFamily: 'Roboto')); 
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
    );
  }
}