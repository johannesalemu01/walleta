import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/transaction.dart';
import '../providers/app_provider.dart';

class PdfExportService {
  static Future<void> exportTransactions(AppProvider appProvider) async {
    final pdf = pw.Document();

    final transactions = appProvider.transactions;
    final totalBalance = appProvider.totalBalance;
    final income = appProvider.monthlyStats['income'] ?? 0;
    final expense = appProvider.monthlyStats['expense'] ?? 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Birr Track - Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox('Total Balance', '${totalBalance.toStringAsFixed(2)} ETB'),
                _buildSummaryBox('Monthly Income', '${income.toStringAsFixed(2)} ETB', color: PdfColors.green700),
                _buildSummaryBox('Monthly Expense', '${expense.toStringAsFixed(2)} ETB', color: PdfColors.red700),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text('Recent Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Date', 'Type', 'Category', 'Description', 'Amount'],
              data: transactions.map((t) => [
                t.date.split('T')[0],
                t.type == TransactionType.income ? 'Income' : 'Expense',
                t.categoryId,
                t.description,
                '${t.amount.toStringAsFixed(2)} ETB'
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'birr_track_report.pdf');
  }

  static pw.Widget _buildSummaryBox(String title, String value, {PdfColor color = PdfColors.black}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
