import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/Footer.dart';

class TareasScreen extends StatelessWidget {
  const TareasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tareas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay tareas'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _taskTile(
                data['titulo'] ?? '',
                data['cliente'] ?? '',
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const Footer(
        currentIndex: 1,
      ),
    );
  }

  Widget _taskTile(String title, String client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(title),
        subtitle: Text(client),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
