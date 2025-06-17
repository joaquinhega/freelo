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
  DocumentSnapshot? _userProfileData;

  bool _notifTareas = true;
  bool _notifPlazos = true;
  bool _notifPagos = true;

  bool _isGoogleLoggedIn = false;

  final FirestoreService _firestoreService = FirestoreService();

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
            _loadUserProfile(_currentUser!.uid);
          } else {
            _userProfileData = null;
          }
        });
      }
    });

    if (_currentUser != null) {
      _loadUserProfile(_currentUser!.uid);
    }
    print('photoURL: ${_currentUser?.photoURL}');
  }

  void _checkLoginProvider() {
    _isGoogleLoggedIn = _currentUser?.providerData
            .any((info) => info.providerId == 'google.com') ??
        false;
  }

  // Cambiado: ahora usa FirestoreService para obtener el perfil
  void _loadUserProfile(String uid) {
    _firestoreService.getUserProfileStream(uid).listen((snapshot) {
      if (mounted) {
        setState(() {
          _userProfileData = snapshot;
        });
      }
    });
  }

  Widget _editableInfoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEditPressed,
    bool showEditIcon = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (onEditPressed != null && showEditIcon)
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
              onPressed: onEditPressed,
            ),
        ],
      ),
    );
  }

  Widget _aboutItem({
    required String title,
    required VoidCallback onTap,
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

@override
Widget build(BuildContext context) {
  print('Usuario actual: ${_currentUser?.email}');
  print('photoURL: ${_currentUser?.photoURL}');
  print('providerData: ${_currentUser?.providerData}');
    final String userEmail = _currentUser?.email ?? 'No disponible';
    String userDisplayName = _currentUser?.displayName ?? 'Nombre Completo';
    String userPhoneNumber = _currentUser?.phoneNumber ?? 'No disponible';

    if (_userProfileData != null && _userProfileData!.exists) {
      final data = _userProfileData!.data() as Map<String, dynamic>;
      userDisplayName = data['nombreCompleto'] ?? userDisplayName;
      userPhoneNumber = data['numeroTelefono'] ?? userPhoneNumber;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      bottomNavigationBar: const Footer(currentIndex: 4),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: (_currentUser?.photoURL == null || _currentUser!.photoURL!.isEmpty)
                      ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                      : null,
                ),
                if (!_isGoogleLoggedIn)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cambiar foto de perfil')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, size: 20, color: Colors.grey[700]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _editableInfoTile(
            icon: Icons.person_outline,
            label: 'Nombre completo',
            value: userDisplayName,
            onEditPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar nombre')),
              );
            },
            showEditIcon: !_isGoogleLoggedIn,
          ),
          _editableInfoTile(
            icon: Icons.mail_outline,
            label: 'Correo electrónico',
            value: userEmail,
            onEditPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar correo electrónico')),
              );
            },
            showEditIcon: !_isGoogleLoggedIn,
          ),
          _editableInfoTile(
            icon: Icons.phone_outlined,
            label: 'Número de teléfono',
            value: userPhoneNumber,
            onEditPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar número de teléfono')),
              );
            },
            showEditIcon: true,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _isGoogleLoggedIn ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cambiar contraseña')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGoogleLoggedIn ? Colors.grey[200] : const Color(0xFFF2F2F7),
                foregroundColor: _isGoogleLoggedIn ? Colors.grey : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cambiar contraseña'),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Preferencias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _notifTareas,
            onChanged: (bool v) {
              setState(() {
                _notifTareas = v;
              });
              // TODO: Guardar preferencia en FirestoreService si lo deseas
            },
            title: const Text('Notificaciones de Tareas'),
            activeColor: Colors.green,
          ),
          SwitchListTile(
            value: _notifPlazos,
            onChanged: (bool v) {
              setState(() {
                _notifPlazos = v;
              });
              // TODO: Guardar preferencia en FirestoreService si lo deseas
            },
            title: const Text('Notificaciones de Plazos'),
            activeColor: Colors.green,
          ),
          SwitchListTile(
            value: _notifPagos,
            onChanged: (bool v) {
              setState(() {
                _notifPagos = v;
              });
              // TODO: Guardar preferencia en FirestoreService si lo deseas
            },
            title: const Text('Notificaciones de Pagos'),
            activeColor: Colors.green,
          ),
          const SizedBox(height: 24),
          _aboutItem(
            title: 'Gestionar categorías de ingresos',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gestionar categorías de ingresos')),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Acerca de', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _aboutItem(
            title: 'Versión de la App',
            subtitle: '1.0.0 Beta',
            onTap: () {},
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 8),
          _aboutItem(
            title: 'Términos y Condiciones',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver Términos y Condiciones')),
              );
            },
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 8),
          _aboutItem(
            title: 'Políticas de privacidad',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver Políticas de privacidad')),
              );
            },
            icon: Icons.policy_outlined,
          ),
          const SizedBox(height: 8),
          _aboutItem(
            title: 'Contacto de soporte',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contactar soporte')),
              );
            },
            icon: Icons.help_outline,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/bienvenida');
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