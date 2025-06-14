import 'package:flutter/material.dart';
import 'widgets/Footer.dart';

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const Footer(currentIndex: 3), 
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresos mensuales', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 150, child: Placeholder()), 
            const SizedBox(height: 16),
            const Text('Tiempo trabajado: 94 h'),
            const Text('Ingresos: \$21.200'),
            const SizedBox(height: 16),
            const Text('Clientes principales:'),
            const Text('Cliente A'),
            const Text('Cliente B'),
            const Text('Cliente C'),
          ],
        ),
      ),
    );
  }
}