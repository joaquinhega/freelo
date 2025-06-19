import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para autenticación de usuario
import 'package:cloud_firestore/cloud_firestore.dart'; // Para interactuar con Firestore
import 'package:intl/intl.dart'; // Para formatear fechas
import '../services/pdf_generator_service.dart'; // Servicio para generar PDF
import 'package:open_filex/open_filex.dart'; // Para abrir archivos en el dispositivo
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si se ejecuta en web

// Pantalla para la creación y gestión de facturas.
class FacturacionScreen extends StatefulWidget {
  const FacturacionScreen({super.key});

  @override
  State<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<FacturacionScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario de validación
  // Controladores para los campos de texto del formulario.
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

  final PdfGeneratorService _pdfGeneratorService = PdfGeneratorService(); // Instancia del servicio PDF

  // Definición de colores personalizados para la UI.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFD32F2F);

  // Detalles del freelancer (usuario actual)
  Map<String, String> _freelancerDetails = {
    'name': '',
    'address': '',
    'email': '',
    'phone': '',
  };

  bool _initialized = false; // Flag para inicialización
  String? _projectId; // ID del proyecto, si se pasó como argumento

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se ejecuta una sola vez al cargar las dependencias del widget.
    if (!_initialized) {
      // Obtiene argumentos de la ruta, si los hay (ej. projectId).
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _projectId = args?['projectId'] as String?;
      final String? projectName = args?['projectName'];

      // Inicializa los controladores de fecha con fechas actuales/futuras.
      _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _fechaVencimientoController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));

      _loadFreelancerDetails(); // Carga detalles del freelancer
      if (_projectId != null) {
        _loadProjectAndClientData(_projectId!); // Carga datos de proyecto/cliente si hay projectId
      } else {
        // Establece una descripción predeterminada si hay nombre de proyecto.
        _descripcionController.text = projectName != null
            ? 'Servicio de desarrollo para proyecto "$projectName"'
            : '';
      }
      _initialized = true; // Marca como inicializado
    }
  }

  // Carga datos de un proyecto y cliente desde Firestore.
  Future<void> _loadProjectAndClientData(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Consulta el documento del proyecto.
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      _descripcionController.text = ''; // Resetea descripción
      _fechaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now()); // Fecha actual

      final client = data['client'] ?? {}; // Datos del cliente
      _clienteController.text = client['nombre'] ?? ''; // Nombre del cliente
      _empresaController.text = data['title'] ?? ''; // Título del proyecto como empresa
      _emailController.text = client['email'] ?? ''; // Email del cliente
      _telefonoClienteController.text = client['telefono'] ?? ''; // Teléfono del cliente
      _notasCondicionesController.text = ''; // Limpia notas
      setState(() {}); // Actualiza la UI
    }
  }

  // Carga los detalles del perfil del freelancer desde Firestore.
  void _loadFreelancerDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Consulta el documento de detalles del freelancer.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('freelancerDetails')
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          // Actualiza los detalles del freelancer.
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
    // Libera los controladores de texto para evitar fugas de memoria.
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

  // Lógica principal para generar y guardar la factura.
  void _generarFactura() async {
    if (_formKey.currentState!.validate()) { // Valida todos los campos del formulario
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Usuario no autenticado', isError: true);
        return;
      }

      // Parsea y valida la fecha de facturación.
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

      // Parsea y valida la fecha de vencimiento.
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

      // Parsea y valida el precio.
      double? precioParsed = double.tryParse(_precioController.text.trim());
      if (precioParsed == null) {
        _showSnackBar('Precio inválido', isError: true);
        return;
      }

      try {
        // Guarda los datos de la factura en Firestore.
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
              'projectId': _projectId,
              'projectName': _empresaController.text.trim(), // <- projectName es igual a clienteEmpresa
            });

        _showSnackBar('Factura guardada en la nube con éxito', isError: false);

        // Genera el PDF de la factura usando PdfGeneratorService.
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

        // Define el nombre del archivo PDF.
        final filename = 'Factura_${_numeroFacturaController.text.trim().replaceAll('/', '-')}_${_clienteController.text.trim()}.pdf';
        // Guarda el PDF en el dispositivo.
        final savedFile = await _pdfGeneratorService.savePdfToDevice(pdfBytes, filename);

        // Muestra un SnackBar según la plataforma (web o móvil).
        if (kIsWeb) {
          _showSnackBar('PDF generado y descargado en tu navegador', isError: false, isInfo: true);
        } else if (savedFile != null) {
          // Muestra opción para abrir el PDF en móvil.
          _showSnackBar('PDF de factura guardado en ${savedFile.path}', isError: false, isInfo: true, actionLabel: 'Abrir', onActionPressed: () { OpenFilex.open(savedFile.path); });
        } else {
          _showSnackBar('Error al guardar el PDF de la factura', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error al generar o guardar el PDF: $e', isError: true);
      }

      // Cierra la pantalla después de un retraso.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  // Muestra un SnackBar con mensajes de éxito, error o información.
  void _showSnackBar(String message, {bool isError = false, bool isInfo = false, String? actionLabel, VoidCallback? onActionPressed}) {
    Color backgroundColor = isError ? errorRed : (isInfo ? accentBlue : primaryGreen);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: whiteColor, fontFamily: 'Roboto')),
        backgroundColor: backgroundColor,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(label: actionLabel, onPressed: onActionPressed, textColor: whiteColor)
            : null,
        behavior: SnackBarBehavior.floating, // Comportamiento flotante del SnackBar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Borde redondeado
        margin: const EdgeInsets.all(10), // Margen
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