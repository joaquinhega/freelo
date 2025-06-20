import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/Footer.dart';
import 'widgets/new_tarea.dart';
import 'widgets/details_task.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Definición de colores constantes para la UI.
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFDCE7D6);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF8F8F8);
  static const Color darkGrey = Color(0xFF333333);
  static const Color mediumGrey = Color(0xFF757575);
  static const Color softGreenGradientStart = Color(0xFF4CAF50);

  // Función principal: Obtiene el nombre del usuario desde Firestore (perfil o documento) o Firebase Auth.
  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Usuario';

    try {
      // Intenta obtener el nombre de 'freelancerDetails' primero.
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('freelancerDetails')
          .get();

      if (profileDoc.exists && profileDoc.data() != null) {
        final firstName = profileDoc.data()!['firstName'] ?? '';
        if (firstName.isNotEmpty) {
          return firstName;
        }
      }

      // Si no encuentra en 'freelancerDetails', intenta obtener de la colección principal 'users'.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        if (doc.data()!.containsKey('nombre') &&
            doc['nombre'] != null &&
            doc['nombre'].toString().isNotEmpty) {
          return doc['nombre'].toString();
        }
      }
    } catch (e) {
      print("Error obteniendo nombre de Firestore: $e");
    }

    // Como último recurso, usa displayName de Firebase Auth o la parte del email antes del '@'.
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null) {
      return user.email!.split('@')[0];
    }
    return 'Usuario';
  }

  // Función principal: Calcula la suma de 'precio' de las 'facturas' del mes actual del usuario.
  Future<double> _getIngresosMes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final finMes = DateTime(now.year, now.month + 1, 1);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('facturas')
        .where('fechaFacturacion', isGreaterThanOrEqualTo: inicioMes)
        .where('fechaFacturacion', isLessThan: finMes)
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final precio = doc['precio'];
      if (precio is int) {
        total += precio.toDouble();
      } else if (precio is double) {
        total += precio;
      } else if (precio is String) {
        total += double.tryParse(precio) ?? 0.0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Estructura visual: Define el diseño general de la pantalla (fondo, barra inferior, contenido).
    return Scaffold(
      backgroundColor: offWhite,
      bottomNavigationBar: const Footer(currentIndex: 0), // Barra de navegación inferior.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Muestra el saludo "Hola, [nombre] 👋" obteniendo el nombre asíncronamente.
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
              const SizedBox(height: 12),
              const WorkTimer(), // Widget: Muestra el tiempo de trabajo actual.
              const SizedBox(height: 30),
              // Tarjeta de sección: Contiene la lista de tareas activas y el botón "Nueva tarea".
              _sectionCard(
                gradient: const LinearGradient( // Estilo de gradiente para la tarjeta.
                  colors: [whiteColor, lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tareas activas', // Título de la sección de tareas.
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkGrey,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Muestra las tareas activas del usuario en tiempo real desde Firestore.
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('userTasks')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(color: primaryGreen));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            'No tienes tareas aún.', // Mensaje si no hay tareas.
                            style: TextStyle(color: mediumGrey, fontStyle: FontStyle.italic),
                          );
                        }
                        final allTasks = snapshot.data!.docs;
                        // Filtra las tareas para mostrar solo las que no están completadas.
                        final tasks = allTasks
                            .where((task) =>
                                task['isCompleted'] == null ||
                                task['isCompleted'] == false)
                            .toList();

                        if (tasks.isEmpty) {
                          return Text(
                            'No tienes tareas pendientes.', // Mensaje si no hay tareas pendientes.
                            style: TextStyle(color: mediumGrey, fontStyle: FontStyle.italic),
                          );
                        }

                        // Construye la lista de tarjetas para cada tarea activa.
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
                                    // Abre un diálogo con los detalles de la tarea al tocar la tarjeta.
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
                                              // Título de la tarea.
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
                                              // Proyecto al que pertenece la tarea.
                                              Text(
                                                (task.data()
                                                        as Map<String, dynamic>)['project'] ??
                                                    '',
                                                style: TextStyle(color: mediumGrey, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon( // Ícono de flecha para indicar que es clickeable.
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
                      // Botón para agregar una nueva tarea (abre un diálogo).
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(24),
                              child: const NewTaskScreen(), // Pantalla para crear nueva tarea.
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
              // Tarjeta de sección: Muestra los ingresos del mes y un mensaje de facturas.
              _sectionCard(
                color: whiteColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Muestra los ingresos del mes, obtenidos asíncronamente.
                    FutureBuilder<double>(
                      future: _getIngresosMes(),
                      builder: (context, snapshot) {
                        final ingresos = snapshot.data ?? 0.0;
                        return Text(
                          'Ingresos este mes: \$${ingresos.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkGrey,
                            fontFamily: 'Montserrat',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: warningOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              size: 24,
                              color:
                                  warningOrange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '2 facturas vencen esta semana',
                              style: TextStyle(fontSize: 15, color: darkGrey, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    // Tarjeta de acción: Navega a la pantalla de facturación.
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/facturacion');
                      },
                      child: _actionCard(
                        icon: Icons.receipt_long,
                        label: 'Ir a facturación',
                        gradient: const LinearGradient( // Estilo de gradiente para la tarjeta.
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

  // Widget auxiliar: Crea un contenedor para secciones con padding, bordes redondeados y sombra.
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

  // Widget auxiliar: Crea una tarjeta interactiva con ícono, etiqueta y estilos personalizables.
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
}

// Widget: Un simple temporizador que muestra el tiempo transcurrido desde que se inicializó la sesión.
class WorkTimer extends StatefulWidget {
  const WorkTimer({super.key});

  @override
  State<WorkTimer> createState() => _WorkTimerState();
}

class _WorkTimerState extends State<WorkTimer> {
  DateTime? _inicioSesion;
  Timer? _timer;
  Duration _duracion = Duration.zero;

  @override
  void initState() {
    super.initState();
    _inicioSesion = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duracion = DateTime.now().difference(_inicioSesion!);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela el temporizador cuando el widget se destruye.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horas = _duracion.inHours;
    final minutos = _duracion.inMinutes % 60;
    final segundos = _duracion.inSeconds % 60;
    return Text(
      // Muestra el tiempo trabajado en formato HH h MM m SS s.
      'Hoy trabajaste: ${horas > 0 ? '$horas h ' : ''}${minutos.toString().padLeft(2, '0')} m ${segundos.toString().padLeft(2, '0')} s',
      style: TextStyle(color: _DashboardScreenState.mediumGrey, fontSize: 16, fontFamily: 'Roboto'),
    );
  }
}