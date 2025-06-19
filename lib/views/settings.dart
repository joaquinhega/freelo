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

  final bool _notificaciones = false; // Notification switch state, currently static
  bool _isGoogleLoggedIn = false;

  final FirestoreService _firestoreService = FirestoreService();

  // Controllers for editing user details
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _editing = false; // State for enabling/disabling edit mode
  bool _saving = false; // State for showing loading indicator during save

  // Define a consistent color palette based on green and white
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep Green (from logo)
  static const Color lightGreen = Color(0xFFE8F5E9); // Very light green for subtle backgrounds/accents
  static const Color whiteColor = Colors.white; // Pure white
  static const Color offWhite = Color(0xFFF0F2F5); // Slightly off-white for background
  static const Color darkGrey = Color(0xFF212121); // Dark grey for primary text
  static const Color mediumGrey = Color(0xFF616161); // Medium grey for secondary text
  static const Color accentBlue = Color(0xFF2196F3); // A touch of blue for emphasis (e.g., info icons)
  static const Color warningOrange = Color(0xFFFF9800); // Orange for warnings
  static const Color errorRed = Color(0xFFD32F2F); // Red for errors/deletions
  static const Color softGrey = Color(0xFFE0E0E0); // Lighter grey for subtle backgrounds

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _checkLoginProvider();

    // Listen for authentication state changes to update UI
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _checkLoginProvider();
          if (_currentUser != null) {
            _loadFreelancerDetails(_currentUser!.uid);
          } else {
            _freelancerDetails = null; // Clear details if user logs out
          }
        });
      }
    });

    // Load details initially if a user is already logged in
    if (_currentUser != null) {
      _loadFreelancerDetails(_currentUser!.uid);
    }
  }

  // Determine if the user logged in via Google
  void _checkLoginProvider() {
    _isGoogleLoggedIn = _currentUser?.providerData
            .any((info) => info.providerId == 'google.com') ??
        false;
  }

  // Load freelancer details from Firestore
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
      // Populate fields with Google details if no Firestore profile exists
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

  // Save freelancer details to Firestore
  Future<void> _saveFreelancerDetails() async {
    setState(() => _saving = true);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Basic validation based on login provider
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
      // Save details to the 'freelancerDetails' document
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

      // Synchronize the full name to the main user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
            'nombre': '$firstName $lastName',
          }, SetOptions(merge: true));

      setState(() {
        _editing = false; // Exit edit mode after saving
      });
      _loadFreelancerDetails(_currentUser!.uid); // Reload details to update UI
      _showSnackBar("Datos guardados correctamente.", isError: false);
    } catch (e) {
      _showSnackBar("Error al guardar: $e", isError: true);
    }
    setState(() => _saving = false);
  }

  // Helper to show custom SnackBar messages
  void _showSnackBar(String message, {bool isError = false, String? actionLabel, VoidCallback? onActionPressed}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: whiteColor, fontFamily: 'Roboto')),
        backgroundColor: isError ? errorRed : primaryGreen,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(label: actionLabel, onPressed: onActionPressed, textColor: whiteColor)
            : null,
        behavior: SnackBarBehavior.floating, // Make it floating
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
        margin: const EdgeInsets.all(10), // Margin from edges
      ),
    );
  }

  // Widget for displaying user information in read-only mode
  Widget _infoTile(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Increased margin
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Increased padding
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.4), // Soft green background
        borderRadius: BorderRadius.circular(15), // More rounded corners
        border: Border.all(color: primaryGreen.withOpacity(0.3)), // Subtle green border
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: primaryGreen, size: 24), // Green icons, larger
            const SizedBox(width: 16), // Increased spacing
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: mediumGrey, fontFamily: 'Montserrat', fontWeight: FontWeight.bold)), // Smaller, bold label
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: darkGrey, fontFamily: 'Roboto')), // Larger, medium-bold value
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for displaying user information in edit mode (TextFormField)
  Widget _editTile(String label, TextEditingController controller, {IconData? icon, TextInputType? keyboardType, bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Increased margin
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(color: darkGrey, fontFamily: 'Roboto'), // Consistent text style
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: mediumGrey), // Label color
          prefixIcon: icon != null ? Icon(icon, color: primaryGreen, size: 24) : null, // Green prefix icon, larger
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // More rounded borders
            borderSide: BorderSide(color: mediumGrey.withOpacity(0.6)), // Softer border
          ),
          focusedBorder: OutlineInputBorder( // Focused border style
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2), // Green border when focused
          ),
          filled: true,
          fillColor: whiteColor, // White background for text fields
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Adjusted padding
        ),
      ),
    );
  }

  // Widget for "About" section items
  Widget _aboutItem({
    required String title,
    required VoidCallback? onTap,
    IconData? icon,
    String? subtitle,
  }) {
    return Card( // Changed to Card for elevation and rounded corners
      elevation: 3, // Subtle shadow for about items
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      margin: const EdgeInsets.symmetric(vertical: 8), // Margin for cards
      color: whiteColor, // White background
      child: InkWell( // Added InkWell for ripple effect
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18), // Increased padding
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: primaryGreen, size: 26), // Larger, green icon
                const SizedBox(width: 18), // Increased spacing
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // Bolder title
                        fontSize: 17, // Larger font size
                        color: onTap == null ? mediumGrey : darkGrey, // Dynamic color
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: onTap == null ? mediumGrey : mediumGrey, // Consistent subtitle color
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 20, color: mediumGrey), // Larger, grey arrow
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
      backgroundColor: offWhite, // Off-white background for the scaffold
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
              color: darkGrey, // Dark grey title
              fontWeight: FontWeight.bold,
              fontSize: 28, // Larger title
              fontFamily: 'Montserrat'), // Modern font
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: false, // Hide default back button if not needed
        backgroundColor: whiteColor, // White app bar background
        elevation: 4, // More pronounced shadow
        centerTitle: false,
        toolbarHeight: 90, // Increased height
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder( // Rounded bottom corners
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit, size: 28, color: primaryGreen), // Larger, green icon
              tooltip: 'Editar perfil',
              onPressed: () {
                setState(() {
                  _editing = true;
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: const Footer(currentIndex: 4), // Assuming Footer exists
      body: ListView(
        padding: const EdgeInsets.all(20), // Increased padding
        children: [
          // Sección de Datos del Usuario
          Text('Datos del Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          const SizedBox(height: 20), // Increased spacing
          if (_editing) ...[
            // Edit mode fields
            _editTile('Nombre', _firstNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn),
            _editTile('Apellido', _lastNameController, icon: Icons.person_outline, enabled: !_isGoogleLoggedIn),
            _editTile('Correo electrónico', _emailController, icon: Icons.mail_outline, enabled: !_isGoogleLoggedIn),
            _editTile('Teléfono *', _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone, enabled: true),
            _editTile('Dirección', _addressController, icon: Icons.location_on_outlined, enabled: true),
            const SizedBox(height: 20), // Increased spacing
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveFreelancerDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen, // Green button
                      padding: const EdgeInsets.symmetric(vertical: 18), // Larger padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8, // Added shadow
                      shadowColor: primaryGreen.withOpacity(0.4),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color>( // Ripple effect
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
                const SizedBox(width: 16), // Increased spacing
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            setState(() {
                              _editing = false;
                              // Reset controllers to original values
                              _firstNameController.text = freelancer['firstName'] ?? '';
                              _lastNameController.text = freelancer['lastName'] ?? '';
                              _emailController.text = freelancer['email'] ?? '';
                              _phoneController.text = freelancer['phone'] ?? '';
                              _addressController.text = freelancer['address'] ?? '';
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18), // Larger padding
                      side: BorderSide(color: mediumGrey.withOpacity(0.6), width: 1.5), // Softer border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4, // Added shadow
                      shadowColor: mediumGrey.withOpacity(0.2),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: darkGrey, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Read-only mode info tiles
            _infoTile('Nombre', freelancer['firstName'] ?? '', icon: Icons.person_outline),
            _infoTile('Apellido', freelancer['lastName'] ?? '', icon: Icons.person_outline),
            _infoTile('Correo electrónico', freelancer['email'] ?? '', icon: Icons.mail_outline),
            _infoTile('Teléfono', freelancer['phone'] ?? '', icon: Icons.phone_outlined),
            _infoTile('Dirección', freelancer['address'] ?? '', icon: Icons.location_on_outlined),
          ],
          const SizedBox(height: 30), // Increased spacing

          // Sección de Preferencias
          Text('Preferencias', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          const SizedBox(height: 16),
          Card( // Wrap SwitchListTile in a Card
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.zero, // Controlled by ListView padding
            color: whiteColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Padding inside the card
              child: SwitchListTile(
                value: _notificaciones,
                onChanged: null, // Currently disabled as per original code
                title: const Text('Notificaciones', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
                activeColor: primaryGreen, // Green switch color
                inactiveThumbColor: mediumGrey,
                inactiveTrackColor: mediumGrey.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(height: 30), // Increased spacing

          // Sección Acerca de
          Text('Acerca de', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
          const SizedBox(height: 16),
          _aboutItem(
            title: 'Versión de la App',
            subtitle: '1.0.0 Beta',
            onTap: null, // Disabled tap
            icon: Icons.info_outline,
          ),
          _aboutItem(
            title: 'Términos y Condiciones',
            onTap: null, // Disabled tap
            icon: Icons.description_outlined,
          ),
          _aboutItem(
            title: 'Políticas de privacidad',
            onTap: null, // Disabled tap
            icon: Icons.policy_outlined,
          ),
          _aboutItem(
            title: 'Contacto de soporte',
            onTap: null, // Disabled tap
            icon: Icons.help_outline,
          ),
          const SizedBox(height: 40),

          // Botón de Cerrar Sesión
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
                          elevation: 5, // Added shadow
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Cerrar Sesión', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    elevation: 10, // Added shadow to dialog
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
                backgroundColor: errorRed, // Red button for logout
                padding: const EdgeInsets.symmetric(vertical: 18), // Larger padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // More rounded corners
                ),
                elevation: 10, // More pronounced shadow
                shadowColor: errorRed.withOpacity(0.5), // Red shadow
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color>( // Ripple effect
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return whiteColor.withOpacity(0.3);
                    }
                    return errorRed;
                  },
                ),
              ),
              icon: const Icon(Icons.logout, color: whiteColor, size: 28), // Larger logout icon
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 19, color: whiteColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'), // Larger, bold, Montserrat font
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
