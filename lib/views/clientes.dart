import 'package:flutter/material.dart';
import 'widgets/Footer.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _clientTile('Cliente A', 'Editar video'),
          _clientTile('Cliente B', 'Traducción de documento'),
          _clientTile('Cliente C', 'Rediseño de sitio web'),
          _clientTile('Cliente D', 'Escribir artículo'),
        ],
      ),
      bottomNavigationBar: const Footer(
        currentIndex: 2,
      ),
    );
  }

  Widget _clientTile(String name, String task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(name),
        subtitle: Text(task),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}