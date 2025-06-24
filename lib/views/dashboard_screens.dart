import 'package:cloud_firestore/cloud_firestore.dart'; //Importa Firestore para manejar la base de datos
import 'dart:async'; //Maneja operaciones asíncronas a través de Future y Stream
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; //Importa gestos para manejar eventos de desplazamiento
import 'widgets/Footer.dart';
import 'widgets/new_tarea.dart';
import 'widgets/details_task.dart';
import '../services/firestore_service.dart'; //Importa el servicio Firestore para interactuar con la base de datos

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFDCE7D6);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF8F8F8);
  static const Color darkGrey = Color(0xFF333333);
  static const Color mediumGrey = Color(0xFF757575);
  static const Color softGreenGradientStart = Color(0xFF4CAF50);

  final FirestoreService _firestoreService = FirestoreService();

  Future<String> _getUserName() async => await _firestoreService.getUserName();
  Future<double> _getIngresosMes() async => await _firestoreService.getIngresoMensualActual();
  Future<int> _getCantidadProyectosActivos() async => await _firestoreService.getCantidadProyectosActivos();
  Future<int> _getCantidadTareasPendientes() async => await _firestoreService.getCantidadTareasPendientes();

  /// Crea una tarjeta de resumen miniatura con un icono, título, valor y color.
  Widget _miniResumenCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.13),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGrey, fontFamily: 'Montserrat')),
            ],
          ),
        ],
      ),
    );
  }

  /// Crea una tarjeta de sección con un widget hijo, color y gradiente opcionales.
  Widget _sectionCard({required Widget child, Color? color, Gradient? gradient}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Crea una tarjeta de acción con un icono, etiqueta, color, color de borde y gradiente opcionales.
  Widget _actionCard({
    required IconData icon,
    required String label,
    Color? color,
    Color? borderColor,
    Color? textColor,
    Gradient? gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        border: borderColor != null ? Border.all(color: borderColor) : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor ?? whiteColor, size: 24),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: textColor ?? whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      bottomNavigationBar: const Footer(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: _getUserName(),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'Usuario';
                  return Text(
                    'Hola, $name 👋',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: darkGrey,
                      fontFamily: 'Montserrat',
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              _sectionCard(
                gradient: const LinearGradient(
                  colors: [whiteColor, lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tareas activas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkGrey,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getUserTasksStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(color: primaryGreen));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            'No tienes tareas aún.',
                            style: TextStyle(color: mediumGrey, fontStyle: FontStyle.italic),
                          );
                        }
                        final allTasks = snapshot.data!.docs;
                        final tasks = allTasks
                            .where((task) =>
                                task['isCompleted'] == null ||
                                task['isCompleted'] == false)
                            .toList();

                        if (tasks.isEmpty) {
                          return Text(
                            'No tienes tareas pendientes.',
                            style: TextStyle(color: mediumGrey, fontStyle: FontStyle.italic),
                          );
                        }

                        return Column(
                          children: [
                            for (var task in tasks)
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 10),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => DetailsTaskScreen(
                                        taskData: task.data()
                                            as Map<String, dynamic>,
                                        taskId: task.id,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (task.data()
                                                        as Map<String, dynamic>)['title'] ??
                                                    '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: darkGrey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (task.data()
                                                        as Map<String, dynamic>)['project'] ??
                                                    '',
                                                style: TextStyle(color: mediumGrey, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 18,
                                            color: mediumGrey),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(24),
                              child: const NewTaskScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 22),
                        label: const Text('Nueva tarea'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: whiteColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Montserrat'),
                          elevation: 8,
                          shadowColor: primaryGreen.withOpacity(0.4),
                        ).copyWith(
                          overlayColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return whiteColor.withOpacity(0.2);
                              }
                              return primaryGreen;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Carrusel resumen con scroll infinito y mouse scroll
              SizedBox(
                height: 120,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final PageController _carouselController = PageController(viewportFraction: 0.85);
                    int _carouselPage = 0;

                    return FutureBuilder<List<double>>(
                      future: Future.wait([
                        _getIngresosMes(),
                        _getCantidadProyectosActivos().then((v) => v.toDouble()),
                        _getCantidadTareasPendientes().then((v) => v.toDouble()),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final ingresos = snapshot.data![0];
                        final proyectos = snapshot.data![1].toInt();
                        final tareas = snapshot.data![2].toInt();

                        final List<Widget> infiniteCards = [
                          _miniResumenCard(
                            icon: Icons.attach_money,
                            title: 'Ingresos este mes',
                            value: '\$${ingresos.toStringAsFixed(2)}',
                            color: primaryGreen,
                          ),
                          _miniResumenCard(
                            icon: Icons.folder_open,
                            title: 'Proyectos activos',
                            value: proyectos.toString(),
                            color: primaryGreen,
                          ),
                          _miniResumenCard(
                            icon: Icons.task_alt,
                            title: 'Tareas pendientes',
                            value: tareas.toString(),
                            color: primaryGreen,
                          ),
                        ];

                        return Listener(
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent) {
                              if (pointerSignal.scrollDelta.dy > 0 || pointerSignal.scrollDelta.dx > 0) {
                                _carouselController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                              } else if (pointerSignal.scrollDelta.dy < 0 || pointerSignal.scrollDelta.dx < 0) {
                                _carouselController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                              }
                            }
                          },
                          child: PageView.builder(
                            controller: _carouselController,
                            onPageChanged: (page) {
                              setState(() {
                                _carouselPage = page;
                              });
                            },
                            itemBuilder: (context, index) {
                              final realIndex = index % infiniteCards.length;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: infiniteCards[realIndex],
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/facturacion');
                      },
                      child: _actionCard(
                        icon: Icons.receipt_long,
                        label: 'Ir a facturación',
                        gradient: const LinearGradient(
                          colors: [primaryGreen, softGreenGradientStart],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        textColor: whiteColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}