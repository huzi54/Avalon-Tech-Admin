import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/payroll_model.dart';
import '../utils/date_time_helper.dart';

class PrintService {
  const PrintService();

  Future<Uint8List> buildPaySlip(PayrollModel payroll) async {
    final pdf = pw.Document();

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [pw.Text(label), pw.Text(value)],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Pay Slip', style: pw.TextStyle(fontSize: 28)),
            pw.SizedBox(height: 16),
            pw.Text(payroll.employeeName),
            pw.Text(
              '${DateTimeHelper.formatDate(payroll.payPeriodStart)} - '
              '${DateTimeHelper.formatDate(payroll.payPeriodEnd)}',
            ),
            pw.Divider(),
            row('Hours', payroll.hours.toStringAsFixed(2)),
            row('Rate', DateTimeHelper.currency(payroll.rate)),
            row('Gross Pay', DateTimeHelper.currency(payroll.grossPay)),
            row('Federal Tax', DateTimeHelper.currency(payroll.federalTax)),
            row(
              'Provincial Tax',
              DateTimeHelper.currency(payroll.provincialTax),
            ),
            row('CPP', DateTimeHelper.currency(payroll.cpp)),
            row('EI', DateTimeHelper.currency(payroll.ei)),
            pw.Divider(),
            row(
              'Total Deductions',
              DateTimeHelper.currency(payroll.totalDeductions),
            ),
            row('Net Pay', DateTimeHelper.currency(payroll.netPay)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> printPaySlip(PayrollModel payroll) async {
    await Printing.layoutPdf(onLayout: (_) => buildPaySlip(payroll));
  }
}
