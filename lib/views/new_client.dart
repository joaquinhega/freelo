import 'package:flutter/material.dart';

class NewClientScreen extends StatelessWidget {
  const NewClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

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
              'Nuevo Cliente',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text('Nombre'),
            const SizedBox(height: 6),
            _inputField(controller: nameController, hint: 'Cliente B'),

            const SizedBox(height: 16),
            const Text('Email'),
            const SizedBox(height: 6),
            _inputField(
              controller: emailController,
              hint: 'cliente.b@example.com',
            ),

            const SizedBox(height: 16),
            const Text('Teléfono'),
            const SizedBox(height: 6),
            _inputField(controller: phoneController, hint: '(355) 123-4567'),

            const SizedBox(height: 16),
            const Text('Notas'),
            const SizedBox(height: 6),
            _inputField(
              controller: notesController,
              hint: 'Cliente recurrente',
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // guardar cliente
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Guardar'),
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
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
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
