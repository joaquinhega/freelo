import 'package:flutter/material.dart';

class EditProjectWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProjectWidget({super.key, required this.initialData});

  @override
  State<EditProjectWidget> createState() => _EditProjectWidgetState();
}

class _EditProjectWidgetState extends State<EditProjectWidget> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final TextEditingController _projectDateController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientNotasController = TextEditingController();

  bool _hasClient = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _projectNameController.text = data['title'] ?? '';
    _projectDescriptionController.text = data['description'] ?? '';
    _projectDateController.text = data['date'] ?? '';
    final client = data['client'] ?? {};
    _clientNameController.text = client['nombre'] ?? '';
    _clientPhoneController.text = client['telefono'] ?? '';
    _clientEmailController.text = client['email'] ?? '';
    _clientNotasController.text = client['notas'] ?? '';
    _hasClient = data['hasClient'] ?? false;
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    _projectDateController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientNotasController.dispose();
    super.dispose();
  }

  Widget _editField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool isDate = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        readOnly: isDate,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF2F2F7),
        ),
        onTap: isDate && enabled
            ? () async {
                FocusScope.of(context).requestFocus(FocusNode());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.text.isNotEmpty
                      ? DateTime.tryParse(controller.text.split('/').reversed.join('-')) ?? DateTime.now()
                      : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
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
        title: const Text('Editar Proyecto'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _editField('Nombre del Proyecto', _projectNameController),
            _editField('Descripción', _projectDescriptionController),
            _editField('Fecha de Entrega (opcional)', _projectDateController, isDate: true, enabled: true),
            Row(
              children: [
                Checkbox(
                  value: _hasClient,
                  onChanged: (bool? value) {
                    setState(() {
                      _hasClient = value ?? false;
                      if (!_hasClient) {
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
                      final result = {
                        'title': _projectNameController.text.trim(),
                        'description': _projectDescriptionController.text.trim(),
                        'date': _projectDateController.text.trim(),
                        'hasClient': _hasClient,
                        'client': _hasClient
                            ? {
                                'nombre': _clientNameController.text.trim(),
                                'telefono': _clientPhoneController.text.trim(),
                                'email': _clientEmailController.text.trim(),
                                'notas': _clientNotasController.text.trim(),
                              }
                            : null,
                      };
                      Navigator.of(context).pop(result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                    onPressed: () => Navigator.of(context).pop(null),
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