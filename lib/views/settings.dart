// pantalla de configuración del usuario

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Authentication para gestionar usuarios
import '../services/auth_service.dart'; // Servicio personalizado para lógica de autenticación
import 'widgets/Footer.dart'; // Widget de pie de página (barra de navegación inferior)
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Cloud Firestore para la base de datos
import '../services/firestore_service.dart'; // Servicio personalizado para interactuar con Firestore

// Pantalla de configuración del usuario.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _currentUser; // Almacena la información del usuario actualmente autenticado
  Map<String, dynamic>? _freelancerDetails; // Almacena los detalles del perfil del freelancer
  bool _isGoogleLoggedIn = false; // Indica si el usuario inició sesión con Google

  // Controladores para los campos de texto del formulario de perfil.
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _editing = false; // Controla si los campos de perfil están en modo edición
  bool _saving = false; // Indica si se está guardando el perfil

  // Definición de una paleta de colores para la UI.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Obtiene el usuario actual al iniciar el estado
    _checkLoginProvider(); // Verifica el proveedor de inicio de sesión

    // Escucha cambios en el estado de autenticación de Firebase.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) { // Asegura que el widget esté montado antes de actualizar el estado
        setState(() {
          _currentUser = user; // Actualiza el usuario actual
          _checkLoginProvider(); // Vuelve a verificar el proveedor
          if (_currentUser != null) {
            _loadFreelancerDetails(_currentUser!.uid); // Carga los detalles del freelancer si hay un usuario
          } else {
            _freelancerDetails = null; // Limpia los detalles si no hay usuario
          }
        });
      }
    });

    // Carga los detalles iniciales del freelancer si ya hay un usuario.
    if (_currentUser != null) {
      _loadFreelancerDetails(_currentUser!.uid);
    }
  }

  // Verifica si el usuario inició sesión a través de Google.
  void _checkLoginProvider() {
    _isGoogleLoggedIn = _currentUser?.providerData
            .any((info) => info.providerId == 'google.com') ??
        false;
  }

  // Carga los detalles del perfil del freelancer desde Firestore.
  void _loadFreelancerDetails(String uid) async {
    final details = await FirestoreService().getFreelancerDetails();
    if (details != null) {
      setState(() {
        _freelancerDetails = details;
        _firstNameController.text = details['firstName'] ?? '';
        _lastNameController.text = details['lastName'] ?? '';
        _emailController.text = details['email'] ?? '';
        _phoneController.text = details['phone'] ?? '';
        _addressController.text = details['address'] ?? '';
      });
    } else if (_isGoogleLoggedIn) {
      setState(() {
        _freelancerDetails = {
          'firstName': _currentUser!.displayName?.split(' ').first ?? '',
          'lastName': _currentUser!.displayName?.split(' ').skip(1).join(' ') ?? '',
          'email': _currentUser!.email ?? '',
          'phone': _currentUser!.phoneNumber ?? '',
          'address': '',
        };
        _firstNameController.text = _freelancerDetails?['firstName'] ?? '';
        _lastNameController.text = _freelancerDetails?['lastName'] ?? '';
        _emailController.text = _freelancerDetails?['email'] ?? '';
        _phoneController.text = _freelancerDetails?['phone'] ?? '';
        _addressController.text = _freelancerDetails?['address'] ?? '';
      });
    }
  }

  // Guarda los detalles del freelancer en Firestore.
Future<void> _saveFreelancerDetails() async {
  setState(() => _saving = true);

  final firstName = _firstNameController.text.trim();
  final lastName = _lastNameController.text.trim();
  final email = _emailController.text.trim();
  final phone = _phoneController.text.trim();
  final address = _addressController.text.trim();

  if (_isGoogleLoggedIn) {
    if (phone.isEmpty) {
      _showSnackBar("El teléfono es obligatorio.", isError: true);
      setState(() => _saving = false);
      return;
    }
  } else {
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty) {
      _showSnackBar("Completa todos los campos obligatorios.", isError: true);
      setState(() => _saving = false);
      return;
    }
  }

  try {
    await FirestoreService().createFreelancerDetails(
      _currentUser!.uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
    );
    // Actualiza el nombre en el documento principal del usuario
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .set({'nombre': '$firstName $lastName'}, SetOptions(merge: true));

    setState(() {
      _editing = false;
    });
    _loadFreelancerDetails(_currentUser!.uid);
    _showSnackBar("Datos guardados correctamente.", isError: false);
  } catch (e) {
    _showSnackBar("Error al guardar: $e", isError: true);
  }
  setState(() => _saving = false);
}

  // Muestra un SnackBar (mensaje temporal en la parte inferior de la pantalla).
  void _showSnackBar(String message, {bool isError = false, String? actionLabel, VoidCallback? onActionPressed}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: whiteColor, fontFamily: 'Roboto')),
        backgroundColor: isError ? errorRed : primaryGreen,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(label: actionLabel, onPressed: onActionPressed, textColor: whiteColor)
            : null,
        behavior: SnackBarBehavior.floating, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
        margin: const EdgeInsets.all(10), 
      ),
    );
  }

  // Widget para mostrar información del perfil en modo no edición.
  Widget _infoTile(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[ 
            Icon(icon, color: primaryGreen, size: 24),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: mediumGrey, fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: darkGrey, fontFamily: 'Roboto')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para campos de texto editables en modo edición.
  Widget _editTile(String label, TextEditingController controller, {IconData? icon, TextInputType? keyboardType, bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled, 
        style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'),
        decoration: InputDecoration(
          labelText: label, 
          labelStyle: const TextStyle(color: mediumGrey),
          prefixIcon: icon != null ? Icon(icon, color: primaryGreen, size: 24) : null, 
          border: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mediumGrey.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: whiteColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final freelancer = _freelancerDetails ?? {}; // Asegura que freelancer no sea nulo

    return Scaffold(
      backgroundColor: offWhite, 
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
              color: darkGrey,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              fontFamily: 'Montserrat'),
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: false, 
        backgroundColor: whiteColor,
        elevation: 4,
        centerTitle: false,
        toolbarHeight: 90, 
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), 
          ),
        ),
        actions: [
          if (!_editing) // Muestra el botón de editar solo si no está en modo edición
            IconButton(
              icon: const Icon(Icons.edit, size: 28, color: primaryGreen),
              tooltip: 'Editar perfil',
              onPressed: () {
                setState(() {
                  _editing = true; 
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: const Footer(currentIndex: 4), 
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Datos del Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          const SizedBox(height: 20),
          if (_editing) ...[ // Muestra campos editables si está en modo edición
            _editTile('Nombre', _firstNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn), 
            _editTile('Apellido', _lastNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn), 
            _editTile('Correo electrónico', _emailController, icon: Icons.mail_outline, enabled: !_isGoogleLoggedIn),
            _editTile('Teléfono *', _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone, enabled: true), 
            _editTile('Dirección', _addressController, icon: Icons.location_on_outlined, enabled: true),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveFreelancerDetails, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: primaryGreen.withOpacity(0.4),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return whiteColor.withOpacity(0.3);
                          }
                          return primaryGreen;
                        },
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: whiteColor), 
                          )
                        : const Text('Guardar', style: TextStyle(color: whiteColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving 
                        ? null
                        : () {
                            setState(() {
                              _editing = false; 
                              // Restaura los valores originales de los controladores
                              _firstNameController.text = freelancer['firstName'] ?? '';
                              _lastNameController.text = freelancer['lastName'] ?? '';
                              _emailController.text = freelancer['email'] ?? '';
                              _phoneController.text = freelancer['phone'] ?? '';
                              _addressController.text = freelancer['address'] ?? '';
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: mediumGrey.withOpacity(0.6), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: mediumGrey.withOpacity(0.2),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: darkGrey, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                  ),
                ),
              ],
            ),
          ] else ...[ 
            _infoTile('Nombre', freelancer['firstName'] ?? '', icon: Icons.person_outline),
            _infoTile('Apellido', freelancer['lastName'] ?? '', icon: Icons.person_outline),
            _infoTile('Correo electrónico', freelancer['email'] ?? '', icon: Icons.mail_outline),
            _infoTile('Teléfono', freelancer['phone'] ?? '', icon: Icons.phone_outlined),
            _infoTile('Dirección', freelancer['address'] ?? '', icon: Icons.location_on_outlined),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('¿Cerrar sesión?', style: TextStyle(fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
                    content: const Text('¿Estás seguro que deseas cerrar sesión?', style: TextStyle(color: mediumGrey, fontFamily: 'Roboto')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancelar', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: errorRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () => Navigator.of(context).pop(true), 
                        child: const Text('Cerrar Sesión', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    elevation: 10,
                  ),
                );
                if (confirm == true) {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/bienvenida');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, 
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 10,
                shadowColor: errorRed.withOpacity(0.5),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return whiteColor.withOpacity(0.3);
                    }
                    return errorRed;
                  },
                ),
              ),
              icon: const Icon(Icons.logout, color: whiteColor, size: 28), 
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 19, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}