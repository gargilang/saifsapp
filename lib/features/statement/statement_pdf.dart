import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/brand.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import 'statement_data.dart';

const _charcoal = PdfColor.fromInt(0xFF111318);
const _gold = PdfColor.fromInt(0xFFD89B2B);

Future<Uint8List> buildStatementPdf(StatementData data, {required Uint8List logoPng}) async {
  final logo = pw.MemoryImage(logoPng);
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('$kBrandName - $kBrandTagline',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Row(children: [
          pw.Image(logo, width: 44, height: 44),
          pw.SizedBox(width: 12),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(kBrandName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Kartu Piutang Customer',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
          pw.Spacer(),
          pw.Text(tampilTanggal(data.generatedAt),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ]),
        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(data.nama, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (data.noHp != null) pw.Text(data.noHp!, style: const pw.TextStyle(fontSize: 10)),
            if (data.alamat != null) pw.Text(data.alamat!, style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
        pw.SizedBox(height: 12),
        pw.Row(children: [
          _summaryBox('Total Belanja', formatRupiah(data.totalBelanja)),
          _summaryBox('Total Bayar', formatRupiah(data.totalBayar)),
          _summaryBox('Sisa Hutang', formatRupiah(data.sisaHutang), highlight: true),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('DAFTAR BARANG',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Barang', 'Tanggal', 'Harga', 'Status', 'Sisa'],
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _charcoal),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {2: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
          data: [
            for (final i in data.items)
              [
                i.namaBarang,
                tampilTanggal(i.tanggal),
                formatRupiah(i.harga),
                i.statusLabel,
                i.sisa > 0 ? formatRupiah(i.sisa) : '-',
              ],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('RIWAYAT PEMBAYARAN',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Tanggal', 'Jumlah', 'Metode'],
          headerStyle:
              pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _charcoal),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {1: pw.Alignment.centerRight},
          data: [
            for (final p in data.payments)
              [tampilTanggal(p.tanggal), formatRupiah(p.jumlah), p.metode],
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _summaryBox(String label, String value, {bool highlight = false}) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 3),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: highlight ? const PdfColor.fromInt(0xFFFFF3D6) : PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label.toUpperCase(),
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    );
