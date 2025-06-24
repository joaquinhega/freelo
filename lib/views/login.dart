import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/firestore_service.dart';
import '../routes/routes.dart';
import '../services/auth_service.dart';

// Pantalla de login con email/contraseña y Google Sign-In
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método para login con email y contraseña
  void _login() async {
    setState(() => _loading = true);
    var user = await AuthService().login(_emailController.text, _passwordController.text);
    setState(() => _loading = false);
    if (user != null) {
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al iniciar sesión")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: green),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 28, right: 28, bottom: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la app
            Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                'assets/LogoCompleto.png',
                width: 220,
                height: 220,
              ),
            ),
            // Texto de bienvenida
            Text(
              'Ingresá tus datos para continuar',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 32),
            // Campo de email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.montserrat(),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: GoogleFonts.montserrat(color: green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.email, color: green),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            // Campo de contraseña
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: GoogleFonts.montserrat(),
              decoration: InputDecoration(
                labelText: "Contraseña",
                labelStyle: GoogleFonts.montserrat(color: green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.lock, color: green),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Botón de login
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text("Iniciar sesión"),
              ),
            ),
            const SizedBox(height: 24),
            // Divider con texto "o"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "o",
                    style: GoogleFonts.montserrat(color: Colors.grey[600]),
                  ),
                ),
                const Expanded(child: Divider(thickness: 1)),
              ],
            ),
            const SizedBox(height: 18),
            // Botón de login con Google
            SizedBox(
              width: 320,
              height: 60,
              child: ElevatedButton.icon(
                icon: Image.asset(
                  'assets/google.png',
                  width: 24,
                  height: 24,
                ),
                label: Text(
                  "Continuar con Google",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.grey.shade400, width: 0.8),
                  ),
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                onPressed: () async {
                  try {
                    final user = await AuthService().signInWithGoogle();
                    if (user != null) {
                      // Verifica si ya existe freelancerDetails usando FirestoreService
                      final exists = await FirestoreService().freelancerDetailsExists(user.uid);
                      if (!exists) {
                        // Si no existe, lo crea con los datos de Google y deja teléfono/dirección vacíos
                        await FirestoreService().createFreelancerDetails(
                          user.uid,
                          firstName: user.displayName?.split(' ').first ?? '',
                          lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
                          email: user.email ?? '',
                          phone: '',
                          address: '',
                        );
                      }
                      Navigator.pushReplacementNamed(context, Routes.dashboard);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No se pudo completar el inicio con Google.")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error con Google Sign-In: $e")),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 28),
            // Link para ir a registro
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, Routes.register);
              },
              child: Text(
                "¿No tenés cuenta? Registrate",
                style: GoogleFonts.montserrat(
                  color: green,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
