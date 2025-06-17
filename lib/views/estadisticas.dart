import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/Footer.dart';

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  Future<List<double>> _getIngresosPorMes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return List.filled(12, 0.0);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('facturas')
        .get();

    List<double> ingresosPorMes = List.filled(12, 0.0);

    for (var doc in snapshot.docs) {
      final precio = doc['precio'];
      final fecha = (doc['fecha'] as Timestamp?)?.toDate();
      if (fecha == null) continue;
      final mes = fecha.month - 1;
      double monto = 0.0;
      if (precio is int) monto = precio.toDouble();
      else if (precio is double) monto = precio;
      else if (precio is String) monto = double.tryParse(precio) ?? 0.0;
      ingresosPorMes[mes] += monto;
    }
    return ingresosPorMes;
  }

  Future<int> _getHorasTrabajadas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .get();

    int totalMinutos = 0;
    for (var doc in snapshot.docs) {
      final duracion = doc['duracion'];
      if (duracion is int) {
        totalMinutos += duracion;
      } else if (duracion is String) {
        final match = RegExp(r'\d+').firstMatch(duracion);
        if (match != null) {
          totalMinutos += int.tryParse(match.group(0)!) ?? 0;
        }
      }
    }
    return (totalMinutos / 60).round();
  }

  Future<double> _getIngresosTotales() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('facturas')
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

  Future<List<String>> _getClientesPrincipales() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('facturas')
        .get();

    Map<String, double> clientes = {};
    for (var doc in snapshot.docs) {
      final cliente = doc['cliente'] ?? 'Sin cliente';
      final precio = doc['precio'];
      double monto = 0.0;
      if (precio is int) monto = precio.toDouble();
      else if (precio is double) monto = precio;
      else if (precio is String) monto = double.tryParse(precio) ?? 0.0;
      clientes[cliente] = (clientes[cliente] ?? 0) + monto;
    }
    final sorted = clientes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const Footer(currentIndex: 3),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ingresos mensuales', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: FutureBuilder<List<double>>(
                  future: _getIngresosPorMes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final ingresosPorMes = snapshot.data!;
                    return LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const meses = [
                                  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                                  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
                                ];
                                int idx = value.toInt();
                                if (idx >= 0 && idx < meses.length) {
                                  return Text(meses[idx], style: const TextStyle(fontSize: 10));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < ingresosPorMes.length; i++)
                                FlSpot(i.toDouble(), ingresosPorMes[i])
                            ],
                            isCurved: true,
                            color: Colors.green[700],
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<int>(
                future: _getHorasTrabajadas(),
                builder: (context, snapshot) {
                  final horas = snapshot.data ?? 0;
                  return Text('Tiempo trabajado: $horas h');
                },
              ),
              FutureBuilder<double>(
                future: _getIngresosTotales(),
                builder: (context, snapshot) {
                  final ingresos = snapshot.data ?? 0.0;
                  return Text('Ingresos: \$${ingresos.toStringAsFixed(2)}');
                },
              ),
              const SizedBox(height: 16),
              const Text('Clientes principales:'),
              FutureBuilder<List<String>>(
                future: _getClientesPrincipales(),
                builder: (context, snapshot) {
                  final clientes = snapshot.data ?? [];
                  if (clientes.isEmpty) {
                    return const Text('Sin clientes');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: clientes.map((c) => Text(c)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}