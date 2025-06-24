import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa el paquete de Firestore
import '../services/firestore_service.dart'; // Importa el servicio Firestore, la diferencia entre el paquete y el servicio es que el paquete es de Firebase y el servicio es tu implementación personalizada
import 'package:intl/intl.dart'; // Permite formatear fechas

class FacturasScreen extends StatefulWidget {
  const FacturasScreen({super.key});

  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color whiteColor = Colors.white;
  static const Color offWhite = Color(0xFFF0F2F5);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color errorRed = Color(0xFFD32F2F);

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }
    if (timestamp is DateTime) {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        leading: BackButton(color: darkGrey),
        title: const Text(
          'Facturas',
          style: TextStyle(
            color: darkGrey,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            fontFamily: 'Montserrat',
          ),
        ),
        backgroundColor: whiteColor,
        elevation: 4,
        centerTitle: false,
        toolbarHeight: 90,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getInvoicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: errorRed, fontSize: 16, fontFamily: 'Roboto')));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No tienes facturas aún.',
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic, fontFamily: 'Roboto'),
              ),
            );
          }

          // Filtra y agrupa las facturas por projectId y projectName válidos
          Map<String, List<DocumentSnapshot>> invoicesByProject = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final projectId = data['projectId'] as String?;
            final projectName = data['projectName'] as String?;
            if (projectId != null && projectId.isNotEmpty && projectName != null && projectName.isNotEmpty) {
              if (!invoicesByProject.containsKey(projectId)) {
                invoicesByProject[projectId] = [];
              }
              invoicesByProject[projectId]!.add(doc);
            }
          }

          if (invoicesByProject.isEmpty) {
            return Center(
              child: Text(
                'No hay facturas asociadas a proyectos válidos.',
                style: TextStyle(color: mediumGrey, fontSize: 18, fontStyle: FontStyle.italic, fontFamily: 'Roboto'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoicesByProject.keys.length,
            itemBuilder: (context, projectIndex) {
              final projectId = invoicesByProject.keys.elementAt(projectIndex);
              final projectInvoices = invoicesByProject[projectId]!;
              final projectName = projectInvoices.first['projectName'] ?? 'Proyecto Desconocido';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 4.0),
                    child: Text(
                      projectName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkGrey,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: projectInvoices.length,
                    itemBuilder: (context, invoiceIndex) {
                      final invoice = projectInvoices[invoiceIndex];
                      final invoiceData = invoice.data() as Map<String, dynamic>;

                      final precio = invoiceData['precio'];
                      final fechaFacturacion = invoiceData['fechaFacturacion'] ?? invoiceData['emissionDate'];
                      final fechaVencimiento = invoiceData['fechaVencimiento'] ?? invoiceData['dueDate'];

                      // Validación extra para evitar errores de null
                      final fechaFacturacionStr = _formatDate(fechaFacturacion);
                      final fechaVencimientoStr = _formatDate(fechaVencimiento);

                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        color: whiteColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monto: \$${precio != null ? precio.toString() : '0.00'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: primaryGreen,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fecha de Emisión: $fechaFacturacionStr',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: mediumGrey,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fecha de Vencimiento: $fechaVencimientoStr',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: mediumGrey,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }
}