import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final titleController = TextEditingController();
  final clientController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    clientController.dispose();
    descriptionController.dispose();
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
              'Nueva tarea',
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
            _inputField(controller: clientController, hint: 'Cliente A'),

            const SizedBox(height: 16),

            // Descripción
            const Text('Descripción'),
            const SizedBox(height: 6),
            _inputField(
              controller: descriptionController,
              hint: 'Detalles de la tarea',
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || clientController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completa todos los campos')),
                    );
                    return;
                  }
                  await FirebaseFirestore.instance.collection('tareas').add({
                    'titulo': titleController.text,
                    'cliente': clientController.text,
                    'descripcion': descriptionController.text,
                    'fecha': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                },
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