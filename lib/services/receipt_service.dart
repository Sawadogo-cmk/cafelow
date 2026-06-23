import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ReceiptService {
  static const String cafeName = 'CaféFlow';
  static const String defaultCafePhone = '+225 01 23 45 67 89';

  // Récupère le numéro de téléphone de la boutique depuis la base de données
  static Future<String> _getCafePhoneFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/shop'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['phone'] ?? defaultCafePhone;
        }
      }
      return defaultCafePhone;
    } catch (e) {
      return defaultCafePhone;
    }
  }

  static Future<void> generateAndDownloadReceipt({
    required int orderId,
    required List<Map<String, dynamic>> items,
    required int total,
    required String customerName,
    required String phone,
    required DateTime date,
  }) async {
    // Récupère le numéro de la boutique dynamiquement
    final cafePhone = await _getCafePhoneFromApi();

    final pdf = pw.Document();

    // Logo
    pw.Widget? logoWidget;
    try {
      final logoImage = await rootBundle.load('assets/logo.png');
      logoWidget = pw.Image(
        pw.MemoryImage(logoImage.buffer.asUint8List()),
        width: 80,
        height: 80,
      );
    } catch (e) {
      logoWidget = pw.Text('☕', style: pw.TextStyle(fontSize: 40));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              logoWidget!,
              pw.SizedBox(height: 5),
              pw.Text(
                cafeName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown,
                ),
              ),
              pw.SizedBox(height: 10),

              // ---- INFOS CLIENT ----
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Client : $customerName',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text('Tél : $phone', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 5),

              // ---- DATE ----
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date : ${_formatDate(date)}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Heure : ${_formatTime(date)}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // ---- TABLEAU DES ARTICLES ----
              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: pw.BorderSide(color: PdfColors.grey200),
                ),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.brown100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Article',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Qté',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Prix',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...items.map((item) {
                    final name = item['name'] ?? 'Sans nom';
                    final quantity = item['quantity'] ?? 1;
                    final price = item['price'] ?? 0;
                    final itemTotal = price * quantity;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('$quantity'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${_formatPrice(price)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${_formatPrice(itemTotal)}'),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),

              // ---- TOTAL ----
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL : ',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_formatPrice(total)}',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ---- COORDONNÉES DE LA CAFÉTÉRIA (numéro dynamique) ----
              pw.Text(
                'Merci de votre visite !',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
              ),
              pw.Text(
                'A bientôt chez $cafeName',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey400),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '📞 $cafePhone',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.blue600),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '----------------------------------------',
                style: pw.TextStyle(color: PdfColors.grey400),
              ),
              pw.Text(
                'Généré le ${_formatDate(date)} à ${_formatTime(date)}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'recu_commande_$orderId.pdf',
    );
  }

  static String _formatPrice(int price) => '$price FCFA';
  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
