import 'package:flutter/material.dart'; // Importa la librería fundamental de Flutter.

// Widget de tipo StatefulWidget para la edición de un proyecto.
class EditProjectWidget extends StatefulWidget {
  final Map<String, dynamic> initialData; // Datos iniciales del proyecto a editar.

  const EditProjectWidget({super.key, required this.initialData});

  @override
  State<EditProjectWidget> createState() => _EditProjectWidgetState(); // Crea el estado del widget.
}

class _EditProjectWidgetState extends State<EditProjectWidget> {
  // Controladores de texto para los campos del formulario.
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final TextEditingController _projectDateController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientNotasController = TextEditingController();

  bool _hasClient = false; // Bandera para indicar si el proyecto tiene un cliente asociado.

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    // Inicializa los controladores con los datos iniciales del proyecto.
    _projectNameController.text = data['title'] ?? '';
    _projectDescriptionController.text = data['description'] ?? '';
    _projectDateController.text = data['date'] ?? '';
    final client = data['client'] ?? {}; // Obtiene los datos del cliente, si existen.
    _clientNameController.text = client['nombre'] ?? '';
    _clientPhoneController.text = client['telefono'] ?? '';
    _clientEmailController.text = client['email'] ?? '';
    _clientNotasController.text = client['notas'] ?? '';
    _hasClient = data['hasClient'] ?? false; // Establece la bandera de cliente.
  }

  @override
  void dispose() {
    // Libera los recursos de los controladores al destruir el widget para evitar fugas de memoria.
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    _projectDateController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientNotasController.dispose();
    super.dispose();
  }

  // Widget auxiliar para crear campos de texto con estilo consistente.
  Widget _editField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType, // Tipo de teclado para el campo.
    bool isDate = false, // Indica si el campo es para una fecha.
    bool enabled = true, // Controla si el campo está habilitado para edición.
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        readOnly: isDate, // Si es una fecha, se hace de solo lectura para abrir el selector.
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF2F2F7), // Color de fondo según si está habilitado.
        ),
        onTap: isDate && enabled // Si es campo de fecha y habilitado, abre el selector de fecha.
            ? () async {
                FocusScope.of(context).requestFocus(FocusNode()); // Quita el foco del campo.
                final picked = await showDatePicker( // Muestra el selector de fecha.
                  context: context,
                  initialDate: controller.text.isNotEmpty
                      ? DateTime.tryParse(controller.text.split('/').reversed.join('-')) ?? DateTime.now()
                      : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  // Formatea la fecha seleccionada y la asigna al controlador.
                  controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                }
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Proyecto'), // Título de la barra de aplicación.
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(null), // Botón para cerrar y descartar cambios.
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView( // Permite desplazamiento si el contenido excede el espacio.
          children: [
            // Campos de edición para los datos del proyecto.
            _editField('Nombre del Proyecto', _projectNameController),
            _editField('Descripción', _projectDescriptionController),
            _editField('Fecha de Entrega (opcional)', _projectDateController, isDate: true, enabled: true),
            Row(
              children: [
                Checkbox(
                  value: _hasClient, // Estado del checkbox para "Tiene Cliente".
                  onChanged: (bool? value) {
                    setState(() {
                      _hasClient = value ?? false;
                      if (!_hasClient) {
                        // Limpia los campos del cliente si el checkbox se desmarca.
                        _clientNameController.clear();
                        _clientPhoneController.clear();
                        _clientEmailController.clear();
                        _clientNotasController.clear();
                      }
                    });
                  },
                ),
                const Text('Cliente'),
              ],
            ),
            // Muestra los campos del cliente solo si `_hasClient` es verdadero.
            if (_hasClient) ...[
              _editField('Nombre', _clientNameController),
              _editField('Teléfono', _clientPhoneController, keyboardType: TextInputType.phone),
              _editField('Email', _clientEmailController, keyboardType: TextInputType.emailAddress),
              _editField('Notas', _clientNotasController),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Recopila los datos de los controladores.
                      final result = {
                        'title': _projectNameController.text.trim(),
                        'description': _projectDescriptionController.text.trim(),
                        'date': _projectDateController.text.trim(),
                        'hasClient': _hasClient,
                        'client': _hasClient
                            ? { // Si tiene cliente, incluye sus datos.
                                'nombre': _clientNameController.text.trim(),
                                'telefono': _clientPhoneController.text.trim(),
                                'email': _clientEmailController.text.trim(),
                                'notas': _clientNotasController.text.trim(),
                              }
                            : null, // Si no tiene cliente, el campo es nulo.
                      };
                      Navigator.of(context).pop(result); // Devuelve los datos actualizados.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Estilo del botón "Guardar".
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null), // Botón para cancelar sin guardar.
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}