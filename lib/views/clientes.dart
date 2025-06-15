import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'widgets/Footer.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream clientsStream;

  @override
  void initState() {
    super.initState();
    clientsStream = _firestoreService.getClientsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        automaticallyImplyLeading: false, 
      ),
      bottomNavigationBar: const Footer(currentIndex: 2),
      body: StreamBuilder(
        stream: clientsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar clientes: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay clientes aún.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs.map<Widget>((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['nombre'] ?? ''),
                subtitle: Text(data['email'] ?? ''),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}