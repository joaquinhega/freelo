import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/auth_service.dart';
import '../routes/routes.dart';

// Pantalla de registro de usuario con email/contraseña y Google Sign-In
class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Método para registrar usuario con email y contraseña
  void _register() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    final user = await AuthService().register(email, password);
    if (user != null) {
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar usuario")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de la app
              Image.asset(
                'assets/LogoCompleto.png',
                width: 220,
                height: 220,
              ),
              const SizedBox(height: 24),
              // Texto de bienvenida
              Text(
                'Crea tu cuenta para comenzar',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
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
              const SizedBox(height: 18),
              // Campo para confirmar contraseña
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: GoogleFonts.montserrat(),
                decoration: InputDecoration(
                  labelText: "Confirmar Contraseña",
                  labelStyle: GoogleFonts.montserrat(color: green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.lock_outline, color: green),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              // Botón para registrar usuario
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _register,
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
                  child: const Text("Registrar"),
                ),
              ),
              const SizedBox(height: 24),
              // Divider con texto "o"
              Row(
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
              // Botón de registro con Google
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
                      color: Colors.black87,
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
                  ),
                  onPressed: () async {
                    try {
                      final user = await AuthService().signInWithGoogle();
                      if (user != null) {
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
              // Link para ir a login si ya tienes cuenta
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                child: Text(
                  "¿Ya tenés cuenta? Iniciá sesión",
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
      ),
    );
  }
}