import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewClientScreen extends StatefulWidget {
  const NewClientScreen({super.key});

  @override
  State<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends State<NewClientScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Nuevo cliente',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text('Nombre'),
            const SizedBox(height: 6),
            _inputField(controller: nameController, hint: 'Nombre completo'),

            const SizedBox(height: 16),

            const Text('Email'),
            const SizedBox(height: 6),
            _inputField(controller: emailController, hint: 'correo@ejemplo.com'),

            const SizedBox(height: 16),

            const Text('Teléfono'),
            const SizedBox(height: 6),
            _inputField(controller: phoneController, hint: '123456789'),

            const SizedBox(height: 16),

            const Text('Notas'),
            const SizedBox(height: 6),
            _inputField(
              controller: notesController,
              hint: 'Notas adicionales',
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completa nombre y email')),
                    );
                    return;
                  }
                  await FirebaseFirestore.instance.collection('clientes').add({
                    'nombre': nameController.text,
                    'email': emailController.text,
                    'telefono': phoneController.text,
                    'notas': notesController.text,
                    'fecha': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                },
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