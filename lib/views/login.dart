import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/routes.dart';
import '../services/auth_service.dart';

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
        title: Text(
          "Iniciar sesión",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: green,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: green),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/fLogo.png',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 32),
              Text(
                'Ingresá tus datos para continuar',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),
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
              // Botón de iniciar sesión más angosto
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
              // Divider con texto
              Row(
                children: [
                  const Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "o continuar con",
                      style: GoogleFonts.montserrat(color: Colors.grey[600]),
                    ),
                  ),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 18),
              // Botones sociales
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    asset: 'assets/google.png',
                    onTap: () {}, // Implementa tu lógica
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    asset: 'assets/linkedin.png',
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    asset: 'assets/github.png',
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    asset: 'assets/apple.png',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),
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
      ),
    );
  }
}

// Botón social reutilizable
class _SocialButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  const _SocialButton({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(asset, width: 26, height: 26),
        ),
      ),
    );
  }
}