import 'package:flutter/material.dart';

class TareasScreen extends StatelessWidget {
  const TareasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _taskTile('Editar video', 'Cliente A'),
          _taskTile('Traducción de documento', 'Cliente B'),
          _taskTile('Escribir artículo', 'Cliente D'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
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
