import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/pdf_generator_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  final TextEditingController _numeroFacturaController = TextEditingController();
  final TextEditingController _fechaVencimientoController = TextEditingController();
  final TextEditingController _notasCondicionesController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoClienteController = TextEditingController();

  final PdfGeneratorService _pdfGeneratorService = PdfGeneratorService();

  Map<String, String> _freelancerDetails = {
    'name': '',
    'address': '',
    'email': '',
    'phone': '',
  };

  bool _initialized = false;
  String? _projectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      print('[facturacion] Arguments recibidos: $args');

      _projectId = args?['projectId'] as String?;
      final String? projectName = args?['projectName'];
      print('[facturacion] projectId=$_projectId, projectName=$projectName');

      _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _fechaVencimientoController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));

      _loadFreelancerDetails();
      if (_projectId != null) {
        _loadProjectAndClientData(_projectId!);
      } else {
        _descripcionController.text = projectName != null
            ? 'Servicio de desarrollo para proyecto "$projectName"'
            : '';
      }
      _initialized = true;
    }
  }

Future<void> _loadProjectAndClientData(String projectId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  print('[facturacion] Consultando Firestore para projectId=$projectId');

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('projects')
      .doc(projectId)
      .get();
  print('[facturacion] Firestore doc.exists=${doc.exists}, data=${doc.data()}');


    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      _descripcionController.text = '';
      _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

      final client = data['client'] ?? {};
      print('[facturacion] Datos de cliente obtenidos: $client');
      _clienteController.text = client['nombre'] ?? '';
      _empresaController.text = data['title'] ?? '';
      _emailController.text = client['email'] ?? '';
      _telefonoClienteController.text = client['telefono'] ?? '';
      _notasCondicionesController.text = '';
      setState(() {});
    }
  }

  void _loadFreelancerDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('freelancerDetails')
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _freelancerDetails = {
            'name': '${doc.data()!['firstName'] ?? ''} ${doc.data()!['lastName'] ?? ''}'.trim(),
            'address': doc.data()!['address'] ?? '',
            'email': doc.data()!['email'] ?? '',
            'phone': doc.data()!['phone'] ?? '',
          };
        });
      }
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _fechaController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _numeroFacturaController.dispose();
    _fechaVencimientoController.dispose();
    _notasCondicionesController.dispose();
    _empresaController.dispose();
    _emailController.dispose();
    _telefonoClienteController.dispose();
    super.dispose();
  }

  void _generarFactura() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado'), backgroundColor: Colors.red),
        );
        return;
      }

      DateTime? fechaFactura;
      try {
        final partes = _fechaController.text.split('/');
        fechaFactura = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha de Facturación inválida (DD/MM/YYYY)'), backgroundColor: Colors.red),
        );
        return;
      }

      DateTime? fechaVencimiento;
      try {
        final partes = _fechaVencimientoController.text.split('/');
        fechaVencimiento = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha de Vencimiento inválida (DD/MM/YYYY)'), backgroundColor: Colors.red),
        );
        return;
      }

      double? precioParsed = double.tryParse(_precioController.text.trim());
      if (precioParsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precio inválido'), backgroundColor: Colors.red),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('facturas')
          .add({
            'numeroFactura': _numeroFacturaController.text.trim(),
            'clienteNombre': _clienteController.text.trim(),
            'clienteEmpresa': _empresaController.text.trim(),
            'clienteEmail': _emailController.text.trim(),
            'clienteTelefono': _telefonoClienteController.text.trim(),
            'fechaFacturacion': fechaFactura,
            'fechaVencimiento': fechaVencimiento,
            'descripcionServicio': _descripcionController.text.trim(),
            'precio': precioParsed,
            'notasCondiciones': _notasCondicionesController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
            'proyectoId': _projectId,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura guardada en la nube con éxito'), backgroundColor: Colors.green),
      );

      try {
        final pdfBytes = await _pdfGeneratorService.generateInvoicePdf(
          invoiceNumber: _numeroFacturaController.text.trim(),
          clientName: _clienteController.text.trim(),
          clientCompany: _empresaController.text.trim(),
          clientEmail: _emailController.text.trim(),
          clientPhone: _telefonoClienteController.text.trim(),
          description: _descripcionController.text.trim(),
          price: precioParsed,
          invoiceDate: fechaFactura,
          dueDate: fechaVencimiento,
          notes: _notasCondicionesController.text.trim(),
          freelancerDetails: _freelancerDetails,
        );

        final filename = 'Factura_${_numeroFacturaController.text.trim().replaceAll('/', '-')}_${_clienteController.text.trim()}.pdf';
        final savedFile = await _pdfGeneratorService.savePdfToDevice(pdfBytes, filename);

        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF generado y descargado en tu navegador'),
              backgroundColor: Colors.blue,
            ),
          );
        } else if (savedFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF de factura guardado en ${savedFile.path}'),
              backgroundColor: Colors.blue,
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () {
                  OpenFilex.open(savedFile.path);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar el PDF de la factura'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar o guardar el PDF: $e'), backgroundColor: Colors.red),
        );
      }

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
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
          child: ListView(
            children: [
              const Text('Número de Factura', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _numeroFacturaController,
                decoration: const InputDecoration(hintText: 'Ej: 001/2024'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el número de factura' : null,
              ),
              const SizedBox(height: 20),

              const Text('Datos del Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(hintText: 'Nombre y Apellido del Cliente'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el nombre del cliente' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _empresaController,
                decoration: const InputDecoration(hintText: 'Empresa del Cliente (Opcional)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email del Cliente'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el email del cliente' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _telefonoClienteController,
                decoration: const InputDecoration(hintText: 'Teléfono del Cliente (Opcional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              const Text('Fecha de Facturación', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(hintText: 'DD/MM/YYYY'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese la fecha de facturación' : null,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
                  }
                },
              ),
              const SizedBox(height: 10),

              const Text('Fecha de Vencimiento', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _fechaVencimientoController,
                decoration: const InputDecoration(hintText: 'DD/MM/YYYY'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese la fecha de vencimiento' : null,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _fechaVencimientoController.text = DateFormat('dd/MM/yyyy').format(picked);
                  }
                },
              ),
              const SizedBox(height: 20),

              const Text('Descripción del Servicio/Producto', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Descripción detallada de la factura'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese la descripción' : null,
              ),
              const SizedBox(height: 10),

              const Text('Precio', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ej: 250.00'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Notas / Condiciones Adicionales (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _notasCondicionesController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Ej: Condiciones de pago, detalles bancarios, etc.'),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generarFactura,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Generar y Guardar Factura',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}