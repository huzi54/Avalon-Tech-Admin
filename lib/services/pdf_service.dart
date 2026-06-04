import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../app_config.dart';
import '../models/payroll_model.dart';
import '../utils/date_time_helper.dart';

class PdfService {
  const PdfService();

  Future<Uint8List> buildPaySlip(PayrollModel payroll) async {
    final pdf = pw.Document();
    final navy = PdfColor.fromHex('#071846');
    final border = PdfColor.fromHex('#B9C3D0');
    final lightHeader = PdfColor.fromHex('#F4F7FB');
    final green = PdfColor.fromHex('#18A957');

    pw.TextStyle base({bool bold = false, double size = 8.6}) {
      return pw.TextStyle(
        fontSize: size,
        color: PdfColors.black,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget amountRow(
      String label,
      num value, {
      bool bold = false,
      double vertical = 2.2,
    }) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: vertical),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(label, style: base(bold: bold)),
            ),
            pw.Text(DateTimeHelper.currency(value), style: base(bold: bold)),
          ],
        ),
      );
    }

    pw.Widget divider({double thickness = 0.6}) {
      return pw.Container(height: thickness, color: border);
    }

    pw.Widget section({
      required String title,
      required List<pw.Widget> children,
    }) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border, width: 0.8),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                color: lightHeader,
                border: pw.Border(bottom: pw.BorderSide(color: border)),
              ),
              child: pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  color: navy,
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(7),
              child: pw.Column(children: children),
            ),
          ],
        ),
      );
    }

    pw.Widget infoRow(String label, String value, {bool badge = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(width: 82, child: pw.Text(label, style: base())),
            if (badge)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: pw.BoxDecoration(
                  color: value.toLowerCase() == 'paid'
                      ? green
                      : PdfColors.amber,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              )
            else
              pw.Expanded(child: pw.Text(value, style: base(bold: true))),
          ],
        ),
      );
    }

    final payDateText = payroll.payDate == null
        ? '-'
        : DateTimeHelper.formatDate(payroll.payDate!);
    final paidViaText = payroll.slipStatus.toLowerCase() == 'paid'
        ? payroll.paidVia ?? '-'
        : '-';
    final noteText = payroll.nonTaxableDeductionNote?.trim().isNotEmpty == true
        ? payroll.nonTaxableDeductionNote!.trim()
        : '-';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(8),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 7),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#8EA0B8')),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    AppConfig.companyName,
                    style: pw.TextStyle(
                      color: navy,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    AppConfig.companyAddress,
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#343A46'),
                      fontSize: 10.5,
                    ),
                  ),
                ),
                pw.SizedBox(height: 7),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 128,
                      height: 0.8,
                      color: PdfColors.black,
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                      width: 5,
                      height: 5,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.black,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Text(
                      'Pay Slip',
                      style: pw.TextStyle(
                        color: navy,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                      width: 5,
                      height: 5,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.black,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Container(
                      width: 128,
                      height: 0.8,
                      color: PdfColors.black,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(9),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: border, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            infoRow('Employee:', payroll.employeeName),
                            infoRow('Employee ID:', payroll.employeeId),
                            infoRow(
                              'Slip Status:',
                              payroll.slipStatus,
                              badge: true,
                            ),
                            infoRow('Paid Via:', paidViaText),
                            infoRow('Pay Frequency:', payroll.payFrequency),
                          ],
                        ),
                      ),
                      pw.Container(width: 0.8, height: 70, color: border),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            infoRow(
                              'Pay Period:',
                              '${DateTimeHelper.formatDate(payroll.payPeriodStart)} - '
                                  '${DateTimeHelper.formatDate(payroll.payPeriodEnd)}',
                            ),
                            infoRow('Pay Date:', payDateText),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: section(
                        title: 'Earnings Summary',
                        children: [
                          amountRow('Hours', payroll.hours),
                          amountRow('Hourly Rate', payroll.rate),
                          divider(),
                          amountRow('Regular Income', payroll.regularIncome),
                          amountRow(
                            'Other Taxable Income',
                            payroll.otherTaxableIncome,
                          ),
                          divider(),
                          amountRow('Gross Pay', payroll.grossPay, bold: true),
                          amountRow('Annual Income', payroll.annualIncome),
                          amountRow(
                            'Federal TD1 Amount',
                            payroll.federalTd1Amount,
                          ),
                          amountRow(
                            'Provincial TD1 Amount',
                            payroll.provincialTd1Amount,
                          ),
                          amountRow(
                            'Canada Employment Amount',
                            payroll.canadaEmploymentAmount,
                          ),
                          amountRow(
                            'CPP Basic Exemption Per Period',
                            payroll.cppBasicExemptionPerPeriod,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: section(
                        title: 'Deductions Summary',
                        children: [
                          amountRow('Federal Tax', payroll.federalTax),
                          amountRow('Provincial Tax', payroll.provincialTax),
                          divider(),
                          amountRow('Total Tax', payroll.totalTax, bold: true),
                          divider(),
                          amountRow('EI Deduction', payroll.ei),
                          amountRow(
                            payroll.nonTaxableDeductionReason ??
                                'Other Non-Taxable Deduction / Reason',
                            payroll.otherNonTaxableDeduction,
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(
                              top: 4,
                              bottom: 7,
                              left: 8,
                            ),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Deduction Note',
                                  style: pw.TextStyle(
                                    fontSize: 7.8,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                                pw.Text(
                                  noteText,
                                  style: pw.TextStyle(
                                    fontSize: 7.8,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          divider(),
                          amountRow(
                            'Total Deductions',
                            payroll.totalDeductions,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                section(
                  title: 'Net Pay Summary',
                  children: [
                    amountRow(
                      'Net Pay Before Other Deductions',
                      payroll.netPay,
                    ),
                    divider(thickness: 1.0),
                    amountRow(
                      'Final Payable Amount',
                      payroll.finalPayableAmount,
                      bold: true,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                section(
                  title: 'Employer Remittance',
                  children: [
                    amountRow(
                      'Employee Income Tax (Federal + Provincial)',
                      payroll.employeeIncomeTax,
                    ),
                    amountRow('Employee CPP', payroll.cpp),
                    amountRow('Employee EI Deduction', payroll.ei),
                    divider(),
                    amountRow('Employer CPP', payroll.employerCpp),
                    amountRow('Employer EI', payroll.employerEi),
                    divider(thickness: 1.0),
                    amountRow(
                      'Total Remittance',
                      payroll.totalRemittance,
                      bold: true,
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      text: 'Printed Date: ',
                      style: base(size: 9),
                      children: [
                        pw.TextSpan(
                          text: DateTimeHelper.formatDate(DateTime.now()),
                          style: base(size: 9, bold: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> printPaySlip(PayrollModel payroll) async {
    await Printing.layoutPdf(onLayout: (_) => buildPaySlip(payroll));
  }
}
