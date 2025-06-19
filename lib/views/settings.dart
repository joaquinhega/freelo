import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
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

  final FirestoreService _firestoreService = FirestoreService();

  // Controladores para edición
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _editing = false;
  bool _saving = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("El teléfono es obligatorio.")),
        );
        setState(() => _saving = false);
        return;
      }
    } else {
      if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Completa todos los campos obligatorios.")),
        );
        setState(() => _saving = false);
        return;
      }
    }

    try {
      // Permitir siempre editar todos los campos
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

      // Sincroniza el nombre en users/{uid}
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datos guardados correctamente.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
    setState(() => _saving = false);
  }

  Widget _infoTile(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editTile(String label, TextEditingController controller, {IconData? icon, TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
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
    return ListTile(
      tileColor: const Color(0xFFF2F2F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: icon != null ? Icon(icon, color: Colors.grey[700]) : null,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: onTap == null ? Colors.grey : Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: onTap == null ? Colors.grey : Colors.black),
            )
          : null,
      trailing: onTap == null
          ? null
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final freelancer = _freelancerDetails ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
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
          const Text('Datos del Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_editing) ...[
            _editTile('Nombre', _firstNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn),
            _editTile('Apellido', _lastNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn),
            _editTile('Correo electrónico', _emailController, icon: Icons.mail_outline, enabled: !_isGoogleLoggedIn),
            _editTile('Teléfono *', _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone, enabled: true),
            _editTile('Dirección', _addressController, icon: Icons.location_on_outlined, enabled: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveFreelancerDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
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
          ] else ...[
            _infoTile('Nombre', freelancer['firstName'] ?? '', icon: Icons.person_outline),
            _infoTile('Apellido', freelancer['lastName'] ?? '', icon: Icons.person_outline),
            _infoTile('Correo electrónico', freelancer['email'] ?? '', icon: Icons.mail_outline),
            _infoTile('Teléfono', freelancer['phone'] ?? '', icon: Icons.phone_outlined),
            _infoTile('Dirección', freelancer['address'] ?? '', icon: Icons.location_on_outlined),
          ],
          const SizedBox(height: 24),
          const Text('Preferencias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _notificaciones,
            onChanged: null, 
            title: const Text('Notificaciones'),
            activeColor: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text('Acerca de', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _aboutItem(
            title: 'Versión de la App',
            subtitle: '1.0.0 Beta',
            onTap: null,
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 8),
          _aboutItem(
            title: 'Términos y Condiciones',
            onTap: null,
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 8),
          _aboutItem(
            title: 'Políticas de privacidad',
            onTap: null,
            icon: Icons.policy_outlined,
          ),
          const SizedBox(height: 8),
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
                    title: const Text('¿Cerrar sesión?', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                      ),
                    ],
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
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}