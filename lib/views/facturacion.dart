import 'package:flutter/material.dart';

class FacturacionScreen extends StatelessWidget {
  const FacturacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facturar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cliente'),
            const TextField(
              decoration: InputDecoration(hintText: '\$250.00 USD'),
            ),
            const SizedBox(height: 10),
            const Text('Fecha'),
            const TextField(
              decoration: InputDecoration(hintText: '6 abr. 2024'),
            ),
            const SizedBox(height: 10),
            const Text('Descripción'),
            const TextField(maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Generar factura'),
            ),
          ],
        ),
      ),
    );
  }
}
