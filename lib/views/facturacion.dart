import 'package:flutter/material.dart';

class FacturacionScreen extends StatefulWidget {
  const FacturacionScreen({super.key});

  @override
  State<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<FacturacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  @override
  void dispose() {
    _clienteController.dispose();
    _fechaController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _generarFactura() {
    if (_formKey.currentState!.validate()) {
      // Aquí puedes guardar la factura en Firestore o mostrar un mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura generada correctamente')),
      );
      // Limpia los campos si lo deseas
      _clienteController.clear();
      _fechaController.clear();
      _descripcionController.clear();
      _precioController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facturar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cliente'),
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(hintText: 'Nombre del cliente'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el cliente' : null,
              ),
              const SizedBox(height: 10),
              const Text('Fecha'),
              TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(hintText: 'Ej: 6 abr. 2024'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese la fecha' : null,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _fechaController.text =
                        "${picked.day}/${picked.month}/${picked.year}";
                  }
                },
              ),
              const SizedBox(height: 10),
              const Text('Descripción'),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Descripción de la factura'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese la descripción' : null,
              ),
              const SizedBox(height: 10),
              const Text('Precio'),
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ej: 250.00'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el precio' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generarFactura,
                  child: const Text('Generar factura'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}