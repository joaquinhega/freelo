import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'widgets/Footer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _currentUser;
  Map<String, dynamic>? _freelancerDetails;

  final bool _notificaciones = false;
  bool _isGoogleLoggedIn = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _editing = false;
  bool _saving = false;

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
    _currentUser = FirebaseAuth.instance.currentUser;
    _checkLoginProvider();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _checkLoginProvider();
          if (_currentUser != null) {
            _loadFreelancerDetails(_currentUser!.uid);
          } else {
            _freelancerDetails = null;
          }
        });
      }
    });

    if (_currentUser != null) {
      _loadFreelancerDetails(_currentUser!.uid);
    }
  }

  void _checkLoginProvider() {
    _isGoogleLoggedIn = _currentUser?.providerData
            .any((info) => info.providerId == 'google.com') ??
        false;
  }

  void _loadFreelancerDetails(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('freelancerDetails')
        .get();
    if (doc.exists && doc.data() != null) {
      setState(() {
        _freelancerDetails = doc.data();
        _firstNameController.text = _freelancerDetails?['firstName'] ?? '';
        _lastNameController.text = _freelancerDetails?['lastName'] ?? '';
        _emailController.text = _freelancerDetails?['email'] ?? '';
        _phoneController.text = _freelancerDetails?['phone'] ?? '';
        _addressController.text = _freelancerDetails?['address'] ?? '';
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
          }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
            'nombre': '$firstName $lastName',
          }, SetOptions(merge: true));

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

  Widget _aboutItem({
    required String title,
    required VoidCallback? onTap,
    IconData? icon,
    String? subtitle,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: whiteColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          child: Row(
            children: [
              if (icon != null) ...[
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
                        color: onTap == null ? mediumGrey : darkGrey,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    if (subtitle != null) ...[
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
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 20, color: mediumGrey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final freelancer = _freelancerDetails ?? {};

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
          if (!_editing)
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
          if (_editing) ...[
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
              child: SwitchListTile(
                value: _notificaciones,
                onChanged: null,
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
            onTap: null,
            icon: Icons.info_outline,
          ),
          _aboutItem(
            title: 'Términos y Condiciones',
            onTap: null,
            icon: Icons.description_outlined,
          ),
          _aboutItem(
            title: 'Políticas de privacidad',
            onTap: null,
            icon: Icons.policy_outlined,
          ),
          _aboutItem(
            title: 'Contacto de soporte',
            onTap: null,
            icon: Icons.help_outline,
          ),
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