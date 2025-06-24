import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/Footer.dart';
import '../services/firestore_service.dart';

class EstadisticasScreen extends StatelessWidget {
  EstadisticasScreen({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  // Helper widget para los ítems del Summary Component
  Widget _buildSummaryItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.green[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.green[900]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ],
    );
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
              // Summary Component
              FutureBuilder<List<double>>(
                future: Future.wait([
                  _firestoreService.getIngresoMensualActual(),
                  _firestoreService.getCantidadProyectosActivos().then((v) => v.toDouble()),
                  _firestoreService.getCantidadTareasPendientes().then((v) => v.toDouble()),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final ingresoMensual = snapshot.data![0];
                  final proyectosActivos = snapshot.data![1].toInt();
                  final tareasPendientes = snapshot.data![2].toInt();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          icon: Icons.attach_money,
                          label: 'Ingreso Mensual',
                          value: '\$${ingresoMensual.toStringAsFixed(2)}',
                        ),
                        _buildSummaryItem(
                          icon: Icons.folder_open,
                          label: 'Proyectos Activos',
                          value: proyectosActivos.toString(),
                        ),
                        _buildSummaryItem(
                          icon: Icons.task_alt,
                          label: 'Tareas Pendientes',
                          value: tareasPendientes.toString(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Ingresos mensuales', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: FutureBuilder<List<double>>(
                  future: _firestoreService.getIngresosPorMes(),
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
              const SizedBox(height: 24),
              const Text('Ingresos por proyecto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: FutureBuilder<Map<String, double>>(
                  future: _firestoreService.getIngresosPorProyecto(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final ingresosPorProyecto = snapshot.data!;
                    if (ingresosPorProyecto.isEmpty) {
                      return const Center(child: Text('No hay datos de ingresos por proyecto.'));
                    }

                    final List<Color> pieColors = [
                      Color(0xFF2E7D32),
                      Color(0xFF66BB6A),
                      Color(0xFF388E3C),
                      Color(0xFF81C784),
                      Color(0xFF43A047),
                      Color(0xFFA5D6A7),
                      Color(0xFFB9F6CA),
                      Color(0xFF388E3C),
                    ];
                    int colorIndex = 0;

                    final List<PieChartSectionData> sections = ingresosPorProyecto.entries.map((entry) {
                      final color = pieColors[colorIndex % pieColors.length];
                      colorIndex++;
                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title: '${entry.key}\n\$${entry.value.toStringAsFixed(2)}',
                        radius: 80,
                        titleStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        badgeWidget: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.black, fontSize: 10),
                        ),
                        badgePositionPercentageOffset: 1.4,
                      );
                    }).toList();

                    return PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {},
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Muestra los ingresos totales
              FutureBuilder<double>(
                future: _firestoreService.getIngresosTotales(),
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