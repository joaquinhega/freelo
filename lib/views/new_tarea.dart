import 'package:flutter/material.dart';

class NewTaskScreen extends StatelessWidget {
  const NewTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final clientController = TextEditingController();
    final descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva Tarea',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Título
            const Text('Título'),
            const SizedBox(height: 6),
            _inputField(controller: titleController, hint: 'Animación 3D'),

            const SizedBox(height: 16),

            // Cliente
            const Text('Cliente'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                // abrir selección de cliente
              },
              child: AbsorbPointer(
                child: _inputField(
                  controller: clientController,
                  hint: 'Empresa A',
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Descripción
            const Text('Descripción'),
            const SizedBox(height: 6),
            _inputField(
              controller: descriptionController,
              hint: 'Crear modelo y animar personaje',
              maxLines: 3,
            ),

            const Spacer(),

            // Botón
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // guardar tarea
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Crear tarea'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
