import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/Footer.dart'; // Importa el widget de pie de página personalizado

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  // Obtiene los ingresos por mes del usuario actual desde Firestore.
  Future<List<double>> _getIngresosPorMes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return List.filled(12, 0.0); // Retorna ceros si no hay usuario

    // Consulta las facturas del usuario en Firestore.
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('facturas')
        .get();

    List<double> ingresosPorMes = List.filled(12, 0.0); // Inicializa lista para 12 meses

    for (var doc in snapshot.docs) {
      final precio = doc['precio'];
      final fecha = (doc['fechaFacturacion'] as Timestamp?)?.toDate();
      if (fecha == null) continue;
      final mes = fecha.month - 1;
      double monto = 0.0;
      // Convierte el precio a double, manejando diferentes tipos de datos.
      if (precio is int) monto = precio.toDouble();
      else if (precio is double) monto = precio;
      else if (precio is String) monto = double.tryParse(precio) ?? 0.0;
      ingresosPorMes[mes] += monto; // Acumula el monto por mes
    }
    return ingresosPorMes;
  }

  // Obtiene la cantidad total de tareas del usuario actual.
  Future<int> _getCantidadTareas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0; // Retorna 0 si no hay usuario

    // Consulta las tareas del usuario en Firestore.
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .doc(user.uid)
        .collection('userTasks')
        .get();

    return snapshot.docs.length; // Retorna el número de documentos (tareas)
  }

  // Obtiene el total de ingresos del usuario actual.
  Future<double> _getIngresosTotales() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0; // Retorna 0.0 si no hay usuario

    // Consulta las facturas del usuario.
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('facturas')
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final precio = doc['precio'];
      // Suma el precio total, manejando diferentes tipos de datos.
      if (precio is int) {
        total += precio.toDouble();
      } else if (precio is double) {
        total += precio;
      } else if (precio is String) {
        total += double.tryParse(precio) ?? 0.0;
      }
    }
    return total; // Retorna el total de ingresos
  }

  // Obtiene los nombres de los 3 clientes principales por ingresos.
  Future<List<String>> _getClientesPrincipales() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return []; // Retorna lista vacía si no hay usuario

    // Consulta las facturas del usuario.
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('facturas')
        .get();

    Map<String, double> clientes = {}; // Mapa para acumular ingresos por cliente
    for (var doc in snapshot.docs) {
      // Obtiene el nombre del cliente o "Sin cliente" si no está presente.
      final cliente = doc.data().containsKey('cliente') ? doc['cliente'] : 'Sin cliente';
      final precio = doc['precio'];
      double monto = 0.0;
      // Convierte el precio a double.
      if (precio is int) monto = precio.toDouble();
      else if (precio is double) monto = precio;
      else if (precio is String) monto = double.tryParse(precio) ?? 0.0;
      clientes[cliente] = (clientes[cliente] ?? 0) + monto; // Suma el monto al cliente
    }
    // Ordena los clientes por monto de mayor a menor y toma los primeros 3.
    final sorted = clientes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'), // Título de la AppBar
        automaticallyImplyLeading: false, // Oculta el botón de retroceso automático
      ),
      bottomNavigationBar: const Footer(currentIndex: 3), // Pie de página de navegación
      body: Padding(
        padding: const EdgeInsets.all(16), // Padding global para el cuerpo
        child: SingleChildScrollView( // Permite el scroll si el contenido es grande
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alinea los widgets al inicio
            children: [
              const Text('Ingresos mensuales', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180, // Altura fija para el gráfico
                child: FutureBuilder<List<double>>(
                  future: _getIngresosPorMes(), // Llama a la función para obtener datos
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator()); // Muestra carga
                    }
                    final ingresosPorMes = snapshot.data!;
                    return LineChart( // Gráfico de líneas de fl_chart
                      LineChartData(
                        gridData: FlGridData(show: false), // Oculta la cuadrícula
                        borderData: FlBorderData(show: false), // Oculta el borde
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false), // Oculta títulos izquierdos
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false), // Oculta títulos derechos
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false), // Oculta títulos superiores
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                // Muestra las abreviaturas de los meses en el eje X
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
                              // Puntos de datos para el gráfico
                              for (int i = 0; i < ingresosPorMes.length; i++)
                                FlSpot(i.toDouble(), ingresosPorMes[i])
                            ],
                            isCurved: true, // Línea curva
                            color: Colors.green[700], // Color de la línea
                            barWidth: 3,
                            dotData: FlDotData(show: false), // Oculta los puntos en la línea
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.2), // Área bajo la línea
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.white,
                            tooltipRoundedRadius: 8,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  '\$${spot.y.toStringAsFixed(2)}',
                                  const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Muestra la cantidad de tareas creadas
              FutureBuilder<int>(
                future: _getCantidadTareas(),
                builder: (context, snapshot) {
                  final cantidad = snapshot.data ?? 0;
                  return Text('Tareas creadas: $cantidad');
                },
              ),
              // Muestra los ingresos totales
              FutureBuilder<double>(
                future: _getIngresosTotales(),
                builder: (context, snapshot) {
                  final ingresos = snapshot.data ?? 0.0;
                  return Text('Ingresos Totales: \$${ingresos.toStringAsFixed(2)}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}