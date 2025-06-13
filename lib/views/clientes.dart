import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ¡Necesario para obtener el UID del usuario!

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  Stream<QuerySnapshot>? _clientsStream;

  @override
  void initState() {
    super.initState();
    _initializeClientsStream();
  }

  void _initializeClientsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Modifica la consulta para apuntar a la colección de clientes del usuario autenticado
      // Asegúrate de que 'users' o 'clients_data' sea el nombre de la colección principal
      // donde guardas los documentos de usuario, y 'clients' la subcolección.
      _clientsStream = FirebaseFirestore.instance
          .collection('users') // O 'clients_data' si es lo que usas
          .doc(user.uid)
          .collection('clients')
          .orderBy('nombre', descending: false) // Opcional: ordenar por nombre
          .snapshots();
    } else {
      // Si no hay usuario autenticado, devuelve un stream vacío para evitar errores
      // y puedes mostrar un mensaje al usuario.
      print('DEBUG: No hay usuario autenticado. No se pueden cargar los clientes.');
      _clientsStream = Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: _clientsStream == null
          ? const Center(child: CircularProgressIndicator()) // Muestra un cargando mientras se inicializa el stream
          : StreamBuilder<QuerySnapshot>(
              stream: _clientsStream, // Usa el stream inicializado
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Aquí verás el error de permisos si persiste, con más detalle
                  return Center(child: Text('Error al cargar clientes: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay clientes aún.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(16), // Agregado padding
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['nombre'] ?? ''), // Asegúrate que el campo sea 'nombre'
                      subtitle: Text(data['email'] ?? ''), // Asegúrate que el campo sea 'email'
                      // Puedes añadir un trailing u otras acciones si lo deseas
                    );
                  }).toList(),
                );
              },
            ),
    
    );
  }
}