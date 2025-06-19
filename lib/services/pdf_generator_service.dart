import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class PdfGeneratorService {
  Future<Uint8List> generateInvoicePdf({
    required String invoiceNumber,
    required String clientName,
    required String clientCompany,
    required String clientEmail,
    required String clientPhone,
    required String description,
    required double price,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required String notes,
    required Map<String, String> freelancerDetails,

  }) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final boldFontData = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(freelancerDetails['name'] ?? 'Nombre del Freelancer', style: pw.TextStyle(font: boldTtf, fontSize: 20)),
                      pw.Text(freelancerDetails['address'] ?? 'Dirección del Freelancer', style: pw.TextStyle(font: ttf, fontSize: 10)),
                      pw.Text(freelancerDetails['email'] ?? 'freelancer@example.com', style: pw.TextStyle(font: ttf, fontSize: 10)),
                      pw.Text(freelancerDetails['phone'] ?? '+1234567890', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('FACTURA', style: pw.TextStyle(font: boldTtf, fontSize: 30, color: PdfColors.blue)),
              pw.SizedBox(height: 10),
              pw.Text('Número de Factura: $invoiceNumber', style: pw.TextStyle(font: ttf, fontSize: 14)),
              pw.Text('Fecha de Emisión: ${invoiceDate.toLocal().toString().split(' ')[0]}', style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.Text('Fecha de Vencimiento: ${dueDate.toLocal().toString().split(' ')[0]}', style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.SizedBox(height: 30),
              pw.Text('FACTURADO A:', style: pw.TextStyle(font: boldTtf, fontSize: 16)),
              pw.SizedBox(height: 5),
              pw.Text('Nombre Completo: $clientName', style: pw.TextStyle(font: ttf, fontSize: 14)),
              pw.Text(
                'Empresa: ${clientCompany.isNotEmpty ? clientCompany : 'N/A'}',
                style: pw.TextStyle(font: ttf, fontSize: 12),
              ),              
              pw.Text('Email: $clientEmail', style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.Text(
                'Teléfono: ${clientPhone.isNotEmpty ? clientPhone : 'N/A'}',
                style: pw.TextStyle(font: ttf, fontSize: 12),
              ),              
              pw.SizedBox(height: 30),
              pw.Table.fromTextArray(
                headers: ['Desgit add .cripción', 'Precio Unitario', 'Total'],
                data: [
                  [description, '\$${price.toStringAsFixed(2)}', '\$${price.toStringAsFixed(2)}'],
                ],
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(font: boldTtf, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TOTAL: \$${price.toStringAsFixed(2)}', style: pw.TextStyle(font: boldTtf, fontSize: 16, color: PdfColors.blue)),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              if (notes.isNotEmpty) ...[
                pw.Text('Notas / Condiciones:', style: pw.TextStyle(font: boldTtf, fontSize: 14)),
                pw.SizedBox(height: 5),
                pw.Text(notes, style: pw.TextStyle(font: ttf, fontSize: 12)),
              ],
              pw.Spacer(),
              pw.Center(
                child: pw.Text('¡Gracias por elegirnos!', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<dynamic> savePdfToDevice(Uint8List pdfBytes, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return null;
    } else {
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      return file;
    }
  }
}