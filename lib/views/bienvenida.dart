import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _overlayOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    // Overlay más oscuro (0.75)
    _overlayOpacity = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF2E7D32);

    return Scaffold(
      body: Stack(
        children: [
          // --- MODIFICA EL FONDO DESDE AQUÍ ---
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/homeOffice.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Blur sobre la imagen
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // <--- Cambia el blur aquí
              child: Container(color: Colors.transparent),
            ),
          ),
          // Overlay animado para oscurecer el fondo
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _overlayOpacity,
              builder: (context, child) => Container(
                color: Colors.black.withOpacity(_overlayOpacity.value), // <--- Cambia la opacidad aquí
              ),
            ),
          ),
          // --- HASTA AQUÍ MODIFICAS EL FONDO ---
          // Contenido principal con fade-in
          FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo animado
                            AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 800),
                              child: Image.asset(
                                'assets/fLogo.png',
                                width: 120,
                                height: 120,
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Título principal
                            Text(
                              '¡Impulsa tu trabajo freelance!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Microcopy persuasivo
                            Text(
                              'Gestioná clientes, tareas y cobros en un solo lugar.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Botón fijo abajo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, Routes.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('¡Comenzar ahora!'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}