import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// PDF Rapor oluşturma ve paylaşma yardımcı sınıfı
class PdfReportService {
  static Future<void> generateAndShare({
    required BuildContext context,
    required List<Map<String, dynamic>> docs,
    required double totalIncome,
    required double totalExpense,
    required int month,
    required int year,
  }) async {
    final pdf = pw.Document();

    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final monthName = months[month];

    // Kategori toplamları
    Map<String, double> catTotals = {};
    for (var doc in docs) {
      final tipi = (doc['belge_tipi'] as String? ?? 'gider').toLowerCase();
      if (tipi == 'gelir') continue;
      final cat = doc['category'] as String? ?? 'Diğer';
      catTotals[cat] = (catTotals[cat] ?? 0) + (doc['amount'] as num? ?? 0).toDouble();
    }
    final sortedCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0052FF'),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BillMind', style: pw.TextStyle(color: PdfColors.white, fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Aylık Finansal Rapor — $monthName $year',
                    style: pw.TextStyle(color: PdfColor.fromInt(0xB3FFFFFF), fontSize: 14)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Özet
          pw.Row(
            children: [
              _pdfStatBox('Toplam Gelir', '₺${_fmt(totalIncome)}', PdfColors.green),
              pw.SizedBox(width: 16),
              _pdfStatBox('Toplam Gider', '₺${_fmt(totalExpense)}', PdfColors.red),
              pw.SizedBox(width: 16),
              _pdfStatBox('Net Durum', '₺${_fmt(totalIncome - totalExpense)}',
                  totalIncome >= totalExpense ? PdfColors.green : PdfColors.red),
            ],
          ),
          pw.SizedBox(height: 24),

          // Kategori Dağılımı
          pw.Text('Kategori Dağılımı', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          ...sortedCats.map((entry) {
            final pct = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 11))),
                  pw.Expanded(flex: 5, child: pw.Stack(
                    alignment: pw.Alignment.centerLeft,
                    children: [
                      pw.Container(
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: (pct * 100).toInt().clamp(1, 100),
                            child: pw.Container(
                              height: 8,
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#0052FF'),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: (100 - (pct * 100).toInt()).clamp(0, 100),
                            child: pw.SizedBox(),
                          ),
                        ],
                      ),
                    ],
                  )),
                  pw.SizedBox(width: 8),
                  pw.Text('${(pct * 100).toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(flex: 2, child: pw.Text('₺${_fmt(entry.value)}',
                      style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.right)),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 24),

          // Belge Listesi
          pw.Text('Belge Listesi', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: ['FİRMA', 'KATEGORİ', 'TUTAR', 'TİP'].map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                )).toList(),
              ),
              ...docs.take(30).map((doc) => pw.TableRow(
                children: [
                  _pdfCell(doc['name']?.toString() ?? '-'),
                  _pdfCell(doc['category']?.toString() ?? '-'),
                  _pdfCell('₺${_fmt((doc['amount'] as num?)?.toDouble() ?? 0)}'),
                  _pdfCell((doc['belge_tipi']?.toString() ?? 'gider').toUpperCase()),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 24),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Bu rapor BillMind tarafından otomatik oluşturulmuştur. ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    // Kaydet ve paylaş
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/BillMind_Rapor_${monthName}_$year.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(path)], text: 'BillMind Aylık Raporu — $monthName $year');
  }

  static pw.Widget _pdfStatBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey200),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}
