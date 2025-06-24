import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/pdf_generator_service.dart';
import '../services/firestore_service.dart'; // Importa el servicio centralizado
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
  final FirestoreService _firestoreService = FirestoreService(); // Instancia centralizada

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color errorRed = Color(0xFFD32F2F);

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
      _projectId = args?['projectId'] as String?;
      final String? projectName = args?['projectName'];

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

  // --- LIMPIO: Carga datos de un proyecto y cliente usando FirestoreService ---
  Future<void> _loadProjectAndClientData(String projectId) async {
    final data = await _firestoreService.getProjectById(projectId);
    if (data != null) {
      _descripcionController.text = '';
      _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final client = data['client'] ?? {};
      _clienteController.text = client['nombre'] ?? '';
      _empresaController.text = data['title'] ?? '';
      _emailController.text = client['email'] ?? '';
      _telefonoClienteController.text = client['telefono'] ?? '';
      _notasCondicionesController.text = '';
      setState(() {});
    }
  }

  // --- LIMPIO: Carga detalles del freelancer usando FirestoreService ---
  void _loadFreelancerDetails() async {
    final details = await _firestoreService.getFreelancerDetails();
    if (details != null) {
      setState(() {
        _freelancerDetails = details;
      });
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

  // --- LIMPIO: Genera y guarda la factura usando FirestoreService ---
  void _generarFactura() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Usuario no autenticado', isError: true);
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
        _showSnackBar('Fecha de Facturación inválida (DD/MM/YYYY)', isError: true);
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
        _showSnackBar('Fecha de Vencimiento inválida (DD/MM/YYYY)', isError: true);
        return;
      }

      double? precioParsed = double.tryParse(_precioController.text.trim());
      if (precioParsed == null) {
        _showSnackBar('Precio inválido', isError: true);
        return;
      }

      try {
        // Guarda la factura usando FirestoreService
        await _firestoreService.addInvoiceFull(
          numeroFactura: _numeroFacturaController.text.trim(),
          clienteNombre: _clienteController.text.trim(),
          clienteEmpresa: _empresaController.text.trim(),
          clienteEmail: _emailController.text.trim(),
          clienteTelefono: _telefonoClienteController.text.trim(),
          emissionDate: fechaFactura,
          dueDate: fechaVencimiento,
          descripcionServicio: _descripcionController.text.trim(),
          amount: precioParsed,
          notasCondiciones: _notasCondicionesController.text.trim(),
          projectId: _projectId,
          projectName: _empresaController.text.trim(),
        );

        _showSnackBar('Factura guardada en la nube con éxito', isError: false);

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
          _showSnackBar('PDF generado y descargado en tu navegador', isError: false, isInfo: true);
        } else if (savedFile != null) {
          _showSnackBar('PDF de factura guardado en ${savedFile.path}', isError: false, isInfo: true, actionLabel: 'Abrir', onActionPressed: () { OpenFilex.open(savedFile.path); });
        } else {
          _showSnackBar('Error al guardar el PDF de la factura', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error al generar o guardar el PDF: $e', isError: true);
      }

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isInfo = false, String? actionLabel, VoidCallback? onActionPressed}) {
    Color backgroundColor = isError ? errorRed : (isInfo ? accentBlue : primaryGreen);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: whiteColor, fontFamily: 'Roboto')),
        backgroundColor: backgroundColor,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(label: actionLabel, onPressed: onActionPressed, textColor: whiteColor)
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Widget para construir títulos de sección.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkGrey,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  // Widget para construir campos de texto con estilo consistente.
  Widget _buildTextFormField(TextEditingController controller, String hintText, String? Function(String?)? validator, {TextInputType? keyboardType, int maxLines = 1, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'),
        decoration: InputDecoration(
          hintText: hintText, // Texto de sugerencia
          hintStyle: TextStyle(color: mediumGrey.withOpacity(0.7)),
          filled: true,
          fillColor: whiteColor, // Color de fondo del campo
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder( // Estilo del borde por defecto
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mediumGrey.withOpacity(0.4), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder( // Estilo del borde cuando habilitado
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mediumGrey.withOpacity(0.4), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder( // Estilo del borde cuando está enfocado
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2.0),
          ),
          errorBorder: OutlineInputBorder( // Estilo del borde en caso de error
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder( // Estilo del borde en error y enfocado
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed, width: 2.0),
          ),
        ),
        validator: validator, // Función de validación
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite, // Color de fondo de la pantalla
      appBar: AppBar(
        leading: BackButton(color: darkGrey), // Botón de retroceso
        title: const Text(
          'Facturar', // Título de la AppBar
          style: TextStyle(
              color: darkGrey,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              fontFamily: 'Montserrat'),
          overflow: TextOverflow.ellipsis, // Manejo de texto largo
        ),
        backgroundColor: whiteColor, // Color de fondo de la AppBar
        elevation: 4, // Sombra
        centerTitle: false,
        toolbarHeight: 90, // Altura de la barra de herramientas
        surfaceTintColor: Colors.transparent, // Color de la superficie
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Borde inferior redondeado
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20), // Padding para el contenido del cuerpo
        child: Form(
          key: _formKey, // Asigna la clave al formulario
          child: ListView( // Permite el scroll de los campos del formulario
            children: [
              _buildSectionTitle('Número de Factura'),
              _buildTextFormField(
                _numeroFacturaController,
                'Ej: 001/2024',
                (value) => // Validador de campo requerido
                    value == null || value.isEmpty ? 'Ingrese el número de factura' : null,
              ),
              _buildSectionTitle('Datos del Cliente'),
              _buildTextFormField(
                _clienteController,
                'Nombre y Apellido del Cliente',
                (value) => // Validador de campo requerido
                    value == null || value.isEmpty ? 'Ingrese el nombre del cliente' : null,
              ),
              _buildTextFormField(
                _empresaController,
                'Empresa del Cliente (Opcional)',
                null, // Campo opcional, sin validador
              ),
              _buildTextFormField(
                _emailController,
                'Email del Cliente',
                (value) => // Validador de campo requerido
                    value == null || value.isEmpty ? 'Ingrese el email del cliente' : null,
                keyboardType: TextInputType.emailAddress, // Teclado para email
              ),
              _buildTextFormField(
                _telefonoClienteController,
                'Teléfono del Cliente (Opcional)',
                null, // Campo opcional
                keyboardType: TextInputType.phone, // Teclado para teléfono
              ),
              _buildSectionTitle('Fechas de la Factura'),
              _buildTextFormField(
                _fechaController,
                'DD/MM/YYYY',
                (value) => // Validador de campo requerido
                    value == null || value.isEmpty ? 'Ingrese la fecha de facturación' : null,
                readOnly: true, // Solo lectura, para seleccionar con date picker
                onTap: () async { // Abre el selector de fecha al tocar
                  FocusScope.of(context).requestFocus(FocusNode()); // Quita el foco del teclado
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      // Tema personalizado para el date picker
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: primaryGreen, // Color principal
                            onPrimary: whiteColor, // Color del texto sobre el principal
                            onSurface: darkGrey, // Color del texto en la superficie
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: primaryGreen, // Color de texto de los botones
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    _fechaController.text = DateFormat('dd/MM/yyyy').format(picked); // Actualiza campo con fecha seleccionada
                  }
                },
              ),
              _buildTextFormField(
                _fechaVencimientoController,
                'DD/MM/YYYY',
                (value) => // Validador de campo requerido
                    value == null || value.isEmpty ? 'Ingrese la fecha de vencimiento' : null,
                readOnly: true, // Solo lectura
                onTap: () async { // Abre selector de fecha
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)), // Fecha inicial a 30 días
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: primaryGreen,
                            onPrimary: whiteColor,
                            onSurface: darkGrey,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: primaryGreen,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    _fechaVencimientoController.text = DateFormat('dd/MM/yyyy').format(picked); // Actualiza campo
                  }
                },
              ),
              _buildSectionTitle('Descripción del Servicio/Producto'),
              _buildTextFormField(
                _descripcionController,
                'Descripción detallada de la factura',
                (value) => // Validador de campo requerido
                    value == null || value.isEmpty ? 'Ingrese la descripción' : null,
                maxLines: 3, // Permite múltiples líneas
              ),
              _buildSectionTitle('Precio'),
              _buildTextFormField(
                _precioController,
                'Ej: 250.00',
                (value) { // Validador de precio
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
                keyboardType: TextInputType.number, // Teclado numérico
              ),
              _buildSectionTitle('Notas / Condiciones Adicionales (Opcional)'),
              _buildTextFormField(
                _notasCondicionesController,
                'Ej: Condiciones de pago, detalles bancarios, etc.',
                null, // Campo opcional
                maxLines: 3, // Permite múltiples líneas
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, // Ancho completo del botón
                child: ElevatedButton.icon(
                  onPressed: _generarFactura, // Llama a la función para generar factura
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen, // Color de fondo del botón
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Borde redondeado del botón
                    ),
                    elevation: 10, // Sombra del botón
                    shadowColor: primaryGreen.withOpacity(0.5),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return whiteColor.withOpacity(0.3); // Efecto al presionar
                        }
                        return primaryGreen;
                      },
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, color: whiteColor, size: 28), // Icono de PDF
                  label: const Text(
                    'Generar y Guardar Factura', // Texto del botón
                    style: TextStyle(fontSize: 19, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
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