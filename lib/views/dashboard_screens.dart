import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/Footer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user != null && user.email != null) {
      return user.email!.split('@')[0];
    }
    return 'Usuario';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      bottomNavigationBar: const Footer(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: _getUserName(),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'Usuario';
                  return Text(
                    'Hola, $name 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 4),
              const Text('Hoy trabajaste: 2 h 15 m',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              _sectionCard(
                color: const Color(0xFFDFF5E5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tareas activas',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('userTasks')
                              .where('isCompleted', isEqualTo: false)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('No tienes tareas activas.');
                        }
                        final tareas = snapshot.data!.docs;
                        return Column(
                          children: [
                            for (var doc in tareas)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _taskRow(
                                  Icons.play_circle,
                                  doc.data() is Map && (doc.data() as Map).containsKey('title')
                                      ? doc['title'] ?? 'Sin título'
                                      : 'Sin título',
                                  doc.data() is Map && (doc.data() as Map).containsKey('duracion')
                                      ? doc['duracion']?.toString() ?? ''
                                      : '',
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/nueva-tarea');
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva tarea'),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFCDECD0),
                        foregroundColor: Colors.green[900],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                color: const Color(0xFFE3F0FB),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ingresos este mes: \$78.200',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text('2 facturas vencen esta semana',
                            style: TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/estadisticas');
                      },
                      child: _actionCard(
                        icon: Icons.bar_chart,
                        label: 'Ver estadísticas',
                        color: Colors.green[800]!,
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/facturacion');
                      },
                      child: _actionCard(
                        icon: Icons.receipt_long,
                        label: 'Ir a facturación',
                        color: Colors.white,
                        borderColor: Colors.grey[300],
                        textColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/clientes');
                },
                child: _sectionCard(
                  color: Colors.white,
                  child: Row(
                    children: const [
                      Icon(Icons.people_alt_outlined),
                      SizedBox(width: 10),
                      Text('Ver clientes',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskRow(IconData icon, String task, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(task),
          ],
        ),
        Text(time),
      ],
    );
  }

  Widget _sectionCard({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    Color? borderColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: borderColor != null ? Border.all(color: borderColor) : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor ?? Colors.white),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: textColor ?? Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}