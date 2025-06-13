import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ¡Importante: Necesitas esta importación!

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

  // Función para guardar la tarea
  Future<void> _saveTask() async {
    // 1. Obtener el usuario autenticado
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Si no hay usuario autenticado, muestra un mensaje de error y no procede
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Debes iniciar sesión para crear una tarea.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // Sale de la función
    }

    // 2. Validar campos
    if (titleController.text.trim().isEmpty || clientController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, completa el Título y el Cliente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return; // Sale de la función
    }

    // 3. Guardar en Firestore bajo la UID del usuario
    try {
      await FirebaseFirestore.instance
          .collection('tasks') // Nombre de la colección principal (coincide con reglas)
          .doc(user.uid)       // Documento con la UID del usuario
          .collection('userTasks') // Subcolección para las tareas del usuario (coincide con reglas)
          .add({
        'title': titleController.text.trim(),
        'client': clientController.text.trim(),
        'description': descriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(), // Para registrar la fecha de creación
        'isCompleted': false, // Puedes añadir un estado inicial para la tarea
      });

      // 4. Limpiar los campos después de guardar
      titleController.clear();
      clientController.clear();
      descriptionController.clear();

      // 5. Mostrar el mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ¡Tarea creada con éxito!'),
            duration: Duration(seconds: 2), // Duración del mensaje
            backgroundColor: Colors.green, // Color verde para éxito
          ),
        );
      }

      // 6. Esperar un momento y volver a la pantalla anterior (opcional)
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context); // Vuelve a la pantalla anterior
      }
    } catch (e) {
      // 7. Manejo de errores
      print('Error al crear la tarea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la tarea: ${e.toString()}'),
            backgroundColor: Colors.red, // Color rojo para error
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Crear Tarea'), // Título en la AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nueva tarea',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              const Text('Título'),
              const SizedBox(height: 6),
              // Aquí se intenta evitar el aviso de guardar contraseña
              _inputField(
                controller: titleController,
                hint: 'Animación 3D',
                autofillHints: const [AutofillHints.newUsername], // Sugiere al navegador que es un "nuevo nombre de usuario"
              ),

              const SizedBox(height: 16),

              const Text('Cliente'),
              const SizedBox(height: 6),
              // Aquí se intenta evitar el aviso de guardar contraseña
              _inputField(
                controller: clientController,
                hint: 'Cliente A',
                autofillHints: const [AutofillHints.newPassword], // Sugiere al navegador que es una "nueva contraseña" (truco)
              ),

              const SizedBox(height: 16),

              const Text('Descripción'),
              const SizedBox(height: 6),
              _inputField(
                controller: descriptionController,
                hint: 'Detalles de la tarea',
                maxLines: 3,
                autofillHints: [], // Indica que no es aplicable para auto-relleno de credenciales
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTask, // Llama a la nueva función _saveTask
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Bordes más redondeados
                    ),
                    backgroundColor: Theme.of(context).primaryColor, // Usa el color primario del tema
                    foregroundColor: Colors.white, // Color del texto del botón
                  ),
                  child: const Text(
                    'Crear tarea',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Texto en negrita
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    List<String>? autofillHints, // Agregado para los hints de auto-relleno
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      autofillHints: autofillHints, // Pasa los hints al TextFormField
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder( // Borde cuando el campo está habilitado
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder( // Borde cuando el campo está enfocado
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2), // Ejemplo de foco
        ),
      ),
    );
  }
}