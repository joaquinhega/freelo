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

  // Define a consistent color palette based on green and white
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep Green (from logo)
  static const Color lightGreen = Color(0xFFE8F5E9); // Very light green for subtle backgrounds/accents
  static const Color whiteColor = Colors.white; // Pure white
  static const Color offWhite = Color(0xFFF0F2F5); // Slightly off-white for background
  static const Color darkGrey = Color(0xFF212121); // Dark grey for primary text
  static const Color mediumGrey = Color(0xFF616161); // Medium grey for secondary text
  static const Color accentBlue = Color(0xFF2196F3); // A touch of blue for emphasis (e.g., info icons)
  static const Color warningOrange = Color(0xFFFF9800); // Orange for warnings
  static const Color errorRed = Color(0xFFD32F2F); // Red for errors
  static const Color softGreenGradientStart = Color(0xFF4CAF50); // Lighter green for gradients
  static const Color softGreenGradientEnd = Color(0xFF8BC34A); // Even lighter green for gradients


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
            color: darkGrey, // AppBar title color
            fontWeight: FontWeight.bold,
            fontSize: 28, // Larger app bar title for more impact
            fontFamily: 'Montserrat', // Modern font for titles
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: whiteColor, // White app bar background
        elevation: 4, // More pronounced shadow for app bar
        centerTitle: false, // Align title to start
        toolbarHeight: 90, // Increase app bar height for better spacing
        surfaceTintColor: Colors.transparent, // Remove default surface tint
        shape: const RoundedRectangleBorder( // Rounded bottom corners for app bar
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      bottomNavigationBar: const Footer(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const NewClientScreen()));
        },
        backgroundColor: primaryGreen, // FAB color
        foregroundColor: whiteColor, // FAB icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Slightly rounded FAB
        ),
        elevation: 8, // Added shadow to FAB
        highlightElevation: 12, // More elevation on press
        splashColor: lightGreen, // Splash color on press
        tooltip: 'Agregar Proyecto',
        child: const Icon(Icons.add, size: 30), // Larger icon
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
                    style: TextStyle(color: errorRed, fontSize: 18, fontFamily: 'Roboto'))); // Using errorRed, larger font
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('No hay proyectos aún.',
                    style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic))); // Larger and italic
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), // Increased padding for the list
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot document = snapshot.data!.docs[index];
              final data = document.data() as Map<String, dynamic>;

              return Card( // Changed GestureDetector to Card with InkWell inside
                elevation: 6, // More pronounced shadow for cards
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // More rounded corners
                ),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10), // Adjusted margin
                color: whiteColor, // Card background color
                child: InkWell( // Added InkWell for ripple effect on tap
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
                    padding: const EdgeInsets.all(18), // Consistent padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Sin título',
                          style: const TextStyle(
                              fontSize: 20, // Larger title
                              fontWeight: FontWeight.bold,
                              color: darkGrey, // Text color
                              fontFamily: 'Montserrat'), // Modern font
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['description'] ?? 'Sin descripción',
                          style: TextStyle(
                              fontSize: 15, // Consistent font size
                              color: mediumGrey, // Text color
                              fontFamily: 'Roboto'), // Consistent font
                        ),
                        const SizedBox(height: 8),
                        if (data['date'] != null && data['date'].isNotEmpty)
                          Text(
                            'Fecha de Entrega: ${data['date']}',
                            style:
                                const TextStyle(fontSize: 14, color: mediumGrey, fontFamily: 'Roboto'), // Text color
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
                                        fontFamily: 'Montserrat')), // Text color
                                ...(data['phases'] as List).map((phase) {
                                  return Text('  • ${phase['title']}',
                                      style: TextStyle(
                                          color: mediumGrey, fontFamily: 'Roboto')); // Text color
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