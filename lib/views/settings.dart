import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Authentication para gestionar usuarios
import '../services/auth_service.dart'; // Servicio personalizado para lógica de autenticación
import 'widgets/Footer.dart'; // Widget de pie de página (barra de navegación inferior)
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Cloud Firestore para la base de datos

// Pantalla de configuración del usuario.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _currentUser; // Almacena la información del usuario actualmente autenticado
  Map<String, dynamic>? _freelancerDetails; // Almacena los detalles del perfil del freelancer

  final bool _notificaciones = false; // Estado para la configuración de notificaciones (actualmente fijo en false)
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
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('freelancerDetails')
        .get(); // Intenta obtener el documento 'freelancerDetails'

    if (doc.exists && doc.data() != null) {
      // Si el documento existe, carga los datos en los controladores de texto.
      setState(() {
        _freelancerDetails = doc.data();
        _firstNameController.text = _freelancerDetails?['firstName'] ?? '';
        _lastNameController.text = _freelancerDetails?['lastName'] ?? '';
        _emailController.text = _freelancerDetails?['email'] ?? '';
        _phoneController.text = _freelancerDetails?['phone'] ?? '';
        _addressController.text = _freelancerDetails?['address'] ?? '';
      });
    } else if (_isGoogleLoggedIn) {
      // Si no existe el documento y el usuario es de Google, precarga con datos de Google.
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
    setState(() => _saving = true); // Activa el estado de guardado

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Validaciones de campos obligatorios según el proveedor de inicio de sesión.
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
      // Guarda los detalles del freelancer en la subcolección 'profile'.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('profile')
          .doc('freelancerDetails')
          .set({
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'phone': phone,
            'address': address,
          }, SetOptions(merge: true)); // Usa merge para no sobrescribir todo el documento

      // Actualiza el nombre del usuario directamente en el documento del usuario principal.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
            'nombre': '$firstName $lastName',
          }, SetOptions(merge: true));

      setState(() {
        _editing = false; // Sale del modo edición
      });
      _loadFreelancerDetails(_currentUser!.uid); // Recarga los detalles para reflejar los cambios
      _showSnackBar("Datos guardados correctamente.", isError: false); // Muestra mensaje de éxito
    } catch (e) {
      _showSnackBar("Error al guardar: $e", isError: true); // Muestra mensaje de error
    }
    setState(() => _saving = false); // Desactiva el estado de guardado
  }

  // Muestra un SnackBar (mensaje temporal en la parte inferior de la pantalla).
  void _showSnackBar(String message, {bool isError = false, String? actionLabel, VoidCallback? onActionPressed}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: whiteColor, fontFamily: 'Roboto')),
        backgroundColor: isError ? errorRed : primaryGreen, // Color según sea error o éxito
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(label: actionLabel, onPressed: onActionPressed, textColor: whiteColor)
            : null,
        behavior: SnackBarBehavior.floating, // Comportamiento flotante
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Bordes redondeados
        margin: const EdgeInsets.all(10), // Margen alrededor del SnackBar
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
          if (icon != null) ...[ // Muestra el icono si se proporciona
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
        enabled: enabled, // Habilita o deshabilita el campo
        style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'),
        decoration: InputDecoration(
          labelText: label, // Etiqueta del campo
          labelStyle: const TextStyle(color: mediumGrey),
          prefixIcon: icon != null ? Icon(icon, color: primaryGreen, size: 24) : null, // Icono opcional
          border: OutlineInputBorder( // Estilo del borde por defecto
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mediumGrey.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder( // Estilo del borde cuando enfocado
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: whiteColor, // Color de fondo del campo
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // Widget para elementos de la sección "Acerca de".
  Widget _aboutItem({
    required String title,
    required VoidCallback? onTap, // Callback al tocar el elemento
    IconData? icon,
    String? subtitle,
  }) {
    return Card(
      elevation: 3, // Sombra de la tarjeta
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Bordes redondeados
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: whiteColor,
      child: InkWell(
        onTap: onTap, // Acción al tocar
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          child: Row(
            children: [
              if (icon != null) ...[ // Muestra el icono si se proporciona
                Icon(icon, color: primaryGreen, size: 26),
                const SizedBox(width: 18),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: onTap == null ? mediumGrey : darkGrey, // Color según si es interactivo
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    if (subtitle != null) ...[ // Muestra subtítulo si se proporciona
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: onTap == null ? mediumGrey : mediumGrey,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) // Muestra flecha si el elemento es interactivo
                Icon(Icons.arrow_forward_ios, size: 20, color: mediumGrey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final freelancer = _freelancerDetails ?? {}; // Asegura que freelancer no sea nulo

    return Scaffold(
      backgroundColor: offWhite, // Color de fondo de la pantalla
      appBar: AppBar(
        title: const Text(
          'Configuración', // Título de la AppBar
          style: TextStyle(
              color: darkGrey,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              fontFamily: 'Montserrat'),
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: false, // No muestra el botón de retroceso automático
        backgroundColor: whiteColor,
        elevation: 4, // Sombra
        centerTitle: false,
        toolbarHeight: 90, // Altura de la barra de herramientas
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Bordes inferiores redondeados
          ),
        ),
        actions: [
          if (!_editing) // Muestra el botón de editar solo si no está en modo edición
            IconButton(
              icon: const Icon(Icons.edit, size: 28, color: primaryGreen),
              tooltip: 'Editar perfil',
              onPressed: () {
                setState(() {
                  _editing = true; // Cambia a modo edición
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: const Footer(currentIndex: 4), // Barra de navegación inferior
      body: ListView( // Permite el desplazamiento de la pantalla
        padding: const EdgeInsets.all(20),
        children: [
          Text('Datos del Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          const SizedBox(height: 20),
          if (_editing) ...[ // Muestra campos editables si está en modo edición
            _editTile('Nombre', _firstNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn), // Nombre (deshabilitado si es Google)
            _editTile('Apellido', _lastNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn), // Apellido (deshabilitado si es Google)
            _editTile('Correo electrónico', _emailController, icon: Icons.mail_outline, enabled: !_isGoogleLoggedIn), // Email (deshabilitado si es Google)
            _editTile('Teléfono *', _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone, enabled: true), // Teléfono (siempre editable)
            _editTile('Dirección', _addressController, icon: Icons.location_on_outlined, enabled: true), // Dirección (siempre editable)
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveFreelancerDetails, // Botón Guardar (deshabilitado si está guardando)
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: whiteColor), // Indicador de carga
                          )
                        : const Text('Guardar', style: TextStyle(color: whiteColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving // Botón Cancelar (deshabilitado si está guardando)
                        ? null
                        : () {
                            setState(() {
                              _editing = false; // Sale del modo edición
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
          ] else ...[ // Muestra información estática si no está en modo edición
            _infoTile('Nombre', freelancer['firstName'] ?? '', icon: Icons.person_outline),
            _infoTile('Apellido', freelancer['lastName'] ?? '', icon: Icons.person_outline),
            _infoTile('Correo electrónico', freelancer['email'] ?? '', icon: Icons.mail_outline),
            _infoTile('Teléfono', freelancer['phone'] ?? '', icon: Icons.phone_outlined),
            _infoTile('Dirección', freelancer['address'] ?? '', icon: Icons.location_on_outlined),
          ],
          const SizedBox(height: 30),
          Text('Preferencias', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.zero,
            color: whiteColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SwitchListTile( // Widget para la opción de notificaciones
                value: _notificaciones,
                onChanged: null, // Deshabilitado, no permite cambiarlo
                title: const Text('Notificaciones', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
                activeColor: primaryGreen,
                inactiveThumbColor: mediumGrey,
                inactiveTrackColor: mediumGrey.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text('Acerca de', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          const SizedBox(height: 16),
          _aboutItem(
            title: 'Versión de la App',
            subtitle: '1.0.0 Beta',
            onTap: null, // No interactivo
            icon: Icons.info_outline,
          ),
          _aboutItem(
            title: 'Términos y Condiciones',
            onTap: null, // No interactivo
            icon: Icons.description_outlined,
          ),
          _aboutItem(
            title: 'Políticas de privacidad',
            onTap: null, // No interactivo
            icon: Icons.policy_outlined,
          ),
          _aboutItem(
            title: 'Contacto de soporte',
            onTap: null, // No interactivo
            icon: Icons.help_outline,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Muestra un diálogo de confirmación antes de cerrar sesión.
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
                        onPressed: () => Navigator.of(context).pop(false), // Botón Cancelar
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
                        onPressed: () => Navigator.of(context).pop(true), // Botón Cerrar Sesión
                        child: const Text('Cerrar Sesión', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    elevation: 10,
                  ),
                );
                if (confirm == true) {
                  await AuthService().logout(); // Llama al servicio de autenticación para cerrar sesión
                  if (context.mounted) { // Asegura que el widget esté montado antes de navegar
                    Navigator.pushReplacementNamed(context, '/bienvenida'); // Redirige a la pantalla de bienvenida
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed, // Color de fondo del botón de cerrar sesión
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
              icon: const Icon(Icons.logout, color: whiteColor, size: 28), // Icono de cerrar sesión
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