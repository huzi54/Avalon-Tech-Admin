import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../app_config.dart';
import '../models/payroll_model.dart';
import '../models/remittance_model.dart';
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
                            'Total Deductions (Total Statutory Deductions)',
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

  Future<Uint8List> buildEmployeePaySlip(
    PayrollModel payroll, {
    required String designation,
    required String otherTaxableLabel,
    String? checkNumber,
    bool includeOwnerAnnualDetails = false,
  }) async {
    final pdf = pw.Document();
    final navy = PdfColor.fromHex('#071846');
    final text = PdfColor.fromHex('#0F1B3D');
    final border = PdfColor.fromHex('#C5CEDA');
    final green = PdfColor.fromHex('#08733C');
    final greenBg = PdfColor.fromHex('#F0FAF5');
    final red = PdfColor.fromHex('#D20B0B');
    final redBg = PdfColor.fromHex('#FFF3F3');
    final blue = PdfColor.fromHex('#0D47A1');
    final blueBg = PdfColor.fromHex('#F2F7FF');
    final purple = PdfColor.fromHex('#5B35B1');
    final orange = PdfColor.fromHex('#E84A18');
    final note = PdfColor.fromHex('#FFF9EC');
    final noteBorder = PdfColor.fromHex('#E2B65B');

    pw.TextStyle base({bool bold = false, double size = 7.4, PdfColor? color}) {
      return pw.TextStyle(
        fontSize: size,
        color: color ?? text,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget kv(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.2),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 88, child: pw.Text(label, style: base())),
            pw.SizedBox(width: 9, child: pw.Text(':', style: base())),
            pw.Expanded(
              child: pw.Text(value, style: base(bold: bold)),
            ),
          ],
        ),
      );
    }

    pw.Widget line(
      String label,
      String value, {
      bool bold = false,
      PdfColor? color,
      PdfColor? background,
    }) {
      return pw.Container(
        color: background,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3.4),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: base(bold: bold, color: color),
              ),
            ),
            pw.Text(
              value,
              style: base(bold: bold, color: color),
            ),
          ],
        ),
      );
    }

    pw.Widget amountLine(
      String label,
      num value, {
      bool bold = false,
      PdfColor? color,
      PdfColor? background,
      bool negative = false,
    }) {
      final amount = DateTimeHelper.currency(value);
      return line(
        label,
        negative ? '-$amount' : amount,
        bold: bold,
        color: color,
        background: background,
      );
    }

    pw.Widget tableSection({
      required String title,
      required PdfColor color,
      required PdfColor background,
      required List<pw.Widget> rows,
    }) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.55),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: pw.BoxDecoration(
                color: background,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(5),
                  topRight: pw.Radius.circular(5),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 17,
                    height: 17,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: color, width: 1.4),
                    ),
                    child: pw.Text(
                      title.startsWith('EARNING')
                          ? r'$'
                          : title.startsWith('DEDUCTION')
                          ? '-'
                          : title.startsWith('NET')
                          ? '='
                          : 'i',
                      style: base(bold: true, size: 9, color: color),
                    ),
                  ),
                  pw.SizedBox(width: 7),
                  pw.Text(
                    title,
                    style: base(bold: true, size: 8.7, color: color),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: border)),
              ),
              child: pw.Column(
                children: [
                  line(
                    'DESCRIPTION',
                    'AMOUNT',
                    bold: true,
                    background: PdfColor.fromHex('#FBFCFE'),
                  ),
                  pw.Container(height: 0.55, color: border),
                  ...rows,
                ],
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget infoCard({
      required String title,
      required PdfColor color,
      required List<pw.Widget> rows,
    }) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border, width: 0.65),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: border)),
              ),
              child: pw.Text(
                title,
                style: base(bold: true, size: 8.2, color: color),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(children: rows),
            ),
          ],
        ),
      );
    }

    final paymentMethod = payroll.slipStatus.toLowerCase() == 'paid'
        ? payroll.paidVia ?? '-'
        : '-';
    final checkText =
        payroll.paidVia == 'Check' && checkNumber?.trim().isNotEmpty == true
        ? checkNumber!.trim()
        : '-';
    final deductionReason =
        payroll.nonTaxableDeductionReason?.trim().isNotEmpty == true
        ? payroll.nonTaxableDeductionReason!.trim()
        : 'Other';
    final deductionNote =
        payroll.nonTaxableDeductionNote?.trim().isNotEmpty == true
        ? payroll.nonTaxableDeductionNote!.trim()
        : null;
    final payPeriod =
        '${DateTimeHelper.formatDate(payroll.payPeriodStart)} - ${DateTimeHelper.formatDate(payroll.payPeriodEnd)}';
    final payDate = payroll.payDate == null
        ? '-'
        : DateTimeHelper.formatDate(payroll.payDate!);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(7),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 7),
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
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    AppConfig.companyAddress,
                    style: base(size: 8.5),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(width: 52, height: 0.7, color: navy),
                      pw.SizedBox(width: 9),
                      pw.Text(
                        'PAY SLIP',
                        style: pw.TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 9),
                      pw.Container(width: 52, height: 0.7, color: navy),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: border),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 48,
                        height: 48,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#EEF2FA'),
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Text(
                          payroll.employeeName.trim().isEmpty
                              ? '?'
                              : payroll.employeeName.trim()[0].toUpperCase(),
                          style: pw.TextStyle(
                            color: navy,
                            fontSize: 21,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 18),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            kv(
                              'Employee Name',
                              payroll.employeeName,
                              bold: true,
                            ),
                            kv('Employee ID', payroll.employeeId, bold: true),
                            kv('Designation', designation),
                          ],
                        ),
                      ),
                      pw.Container(width: 0.7, height: 58, color: border),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            kv('Pay Frequency', payroll.payFrequency),
                            kv(
                              'Total Working Hours',
                              payroll.hours.toStringAsFixed(2),
                            ),
                            kv(
                              'Hourly Rate',
                              DateTimeHelper.currency(payroll.rate),
                            ),
                            kv(
                              'Regular Income',
                              DateTimeHelper.currency(payroll.regularIncome),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                tableSection(
                  title: 'EARNING DETAILS',
                  color: green,
                  background: greenBg,
                  rows: [
                    amountLine('Gross Pay', payroll.regularIncome),
                    pw.Container(height: 0.45, color: border),
                    amountLine(
                      'Other Taxable Income ($otherTaxableLabel)',
                      payroll.otherTaxableIncome,
                    ),
                    pw.Container(height: 0.45, color: border),
                    amountLine(
                      'TOTAL EARNINGS (GROSS PAY)',
                      payroll.grossPay,
                      bold: true,
                      color: green,
                      background: greenBg,
                    ),
                  ],
                ),
                tableSection(
                  title: 'DEDUCTION DETAILS',
                  color: red,
                  background: redBg,
                  rows: [
                    amountLine('CPP Deduction', payroll.cpp),
                    pw.Container(height: 0.45, color: border),
                    amountLine('EI Deduction', payroll.ei),
                    pw.Container(height: 0.45, color: border),
                    amountLine('Federal Tax', payroll.federalTax),
                    pw.Container(height: 0.45, color: border),
                    amountLine('Provincial Tax', payroll.provincialTax),
                    pw.Container(height: 0.45, color: border),
                    amountLine(
                      'TOTAL DEDUCTIONS (TOTAL STATUTORY DEDUCTIONS)',
                      payroll.totalDeductions,
                      bold: true,
                      color: red,
                      background: redBg,
                    ),
                  ],
                ),
                tableSection(
                  title: 'NET PAY CALCULATION',
                  color: blue,
                  background: blueBg,
                  rows: [
                    amountLine('Gross Pay (Total Earnings)', payroll.grossPay),
                    pw.Container(height: 0.45, color: border),
                    amountLine(
                      'Total Deductions (Total Statutory Deductions)',
                      payroll.totalDeductions,
                      color: red,
                      negative: true,
                    ),
                    pw.Container(height: 0.45, color: border),
                    amountLine(
                      'Net Pay Before Other Deductions',
                      payroll.netPay,
                      bold: true,
                      color: blue,
                      background: blueBg,
                    ),
                    pw.Container(height: 0.45, color: border),
                    amountLine(
                      'Other Non-Taxable Deduction ($deductionReason)',
                      payroll.otherNonTaxableDeduction,
                      color: red,
                      negative: payroll.otherNonTaxableDeduction > 0,
                    ),
                    if (deductionNote != null) ...[
                      pw.Container(height: 0.45, color: border),
                      line(
                        'Deduction Note',
                        deductionNote,
                        color: PdfColor.fromHex('#475569'),
                      ),
                    ],
                    pw.Container(height: 0.45, color: border),
                    amountLine(
                      'FINAL PAYABLE AMOUNT',
                      payroll.finalPayableAmount,
                      bold: true,
                      color: blue,
                      background: blueBg,
                    ),
                  ],
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: infoCard(
                        title: 'PAYMENT INFORMATION',
                        color: purple,
                        rows: [
                          kv('Payment Method', paymentMethod, bold: true),
                          kv('Payment Status', payroll.slipStatus, bold: true),
                          kv('Check Number', checkText),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: infoCard(
                        title: 'PAY PERIOD INFORMATION',
                        color: orange,
                        rows: [
                          kv('Pay Period', payPeriod),
                          kv('Pay Date', payDate),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Row(
                              children: [
                                pw.SizedBox(
                                  width: 88,
                                  child: pw.Text('Slip Status', style: base()),
                                ),
                                pw.SizedBox(
                                  width: 9,
                                  child: pw.Text(':', style: base()),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: payroll.slipStatus == 'Paid'
                                        ? PdfColor.fromHex('#DFF4E8')
                                        : PdfColor.fromHex('#FFE4E6'),
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    payroll.slipStatus,
                                    style: base(
                                      bold: true,
                                      size: 8,
                                      color: payroll.slipStatus == 'Paid'
                                          ? green
                                          : red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(7),
                  decoration: pw.BoxDecoration(
                    color: note,
                    border: pw.Border.all(color: noteBorder),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NOTE',
                        style: base(bold: true, color: noteBorder),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          'Payment date or method may vary due to holidays, banking delays, or system issues. Includes a 30-minute unpaid lunch break as per Canadian labour rules. Salary reflects approved payroll adjustments and authorized deductions.',
                          style: base(size: 7),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your hard work!',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#333333'),
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (includeOwnerAnnualDetails) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(18),
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
                        fontSize: 25,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Center(
                    child: pw.Text(
                      AppConfig.companyAddress,
                      style: base(size: 10),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'OWNER PAYROLL DETAILS',
                      style: base(bold: true, size: 18, color: navy),
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  infoCard(
                    title: 'EMPLOYEE & PAY PERIOD',
                    color: navy,
                    rows: [
                      kv('Employee Name', payroll.employeeName, bold: true),
                      kv('Employee ID', payroll.employeeId),
                      kv('Designation', designation),
                      kv('Pay Frequency', payroll.payFrequency),
                      kv('Number of Periods', '${payroll.numberOfPayPeriods}'),
                      kv('Pay Period', payPeriod),
                      kv('Pay Date', payDate),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                  tableSection(
                    title: 'ANNUAL & TAX DETAILS',
                    color: purple,
                    background: PdfColor.fromHex('#F7F2FF'),
                    rows: [
                      amountLine('Annual Income', payroll.annualIncome),
                      pw.Container(height: 0.45, color: border),
                      amountLine(
                        'Federal TD1 Amount',
                        payroll.federalTd1Amount,
                      ),
                      pw.Container(height: 0.45, color: border),
                      amountLine(
                        'Provincial TD1 Amount',
                        payroll.provincialTd1Amount,
                      ),
                      pw.Container(height: 0.45, color: border),
                      amountLine(
                        'Canada Employment Amount',
                        payroll.canadaEmploymentAmount,
                      ),
                      pw.Container(height: 0.45, color: border),
                      amountLine(
                        'CPP Basic Exemption Per Period',
                        payroll.cppBasicExemptionPerPeriod,
                      ),
                    ],
                  ),
                  tableSection(
                    title: 'EMPLOYER REMITTANCE',
                    color: blue,
                    background: blueBg,
                    rows: [
                      amountLine(
                        'Employee Income Tax (Federal + Provincial)',
                        payroll.employeeIncomeTax,
                      ),
                      pw.Container(height: 0.45, color: border),
                      amountLine('Employee CPP', payroll.cpp),
                      pw.Container(height: 0.45, color: border),
                      amountLine('Employee EI', payroll.ei),
                      pw.Container(height: 0.45, color: border),
                      amountLine('Employer CPP', payroll.employerCpp),
                      pw.Container(height: 0.45, color: border),
                      amountLine('Employer EI', payroll.employerEi),
                      pw.Container(height: 0.45, color: border),
                      amountLine(
                        'TOTAL REMITTANCE',
                        payroll.totalRemittance,
                        bold: true,
                        color: blue,
                        background: blueBg,
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Center(
                    child: pw.Text(
                      'Printed Date: ${DateTimeHelper.formatDate(DateTime.now())}',
                      style: base(size: 8),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  Future<Uint8List> buildRemittanceSlip(RemittanceModel remittance) async {
    final pdf = pw.Document();
    final navy = PdfColor.fromHex('#071846');
    final border = PdfColor.fromHex('#C5CEDA');
    final light = PdfColor.fromHex('#F7FAFE');
    final blue = PdfColor.fromHex('#003586');

    pw.TextStyle base({bool bold = false, double size = 10, PdfColor? color}) {
      return pw.TextStyle(
        fontSize: size,
        color: color ?? navy,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget kv(String icon, String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 28,
              child: pw.Text(icon, style: base(size: 13, bold: true)),
            ),
            pw.SizedBox(width: 116, child: pw.Text(label, style: base())),
            pw.SizedBox(width: 14, child: pw.Text(':', style: base())),
            pw.Expanded(child: pw.Text(value, style: base(bold: true))),
          ],
        ),
      );
    }

    pw.Widget cell(
      String value, {
      bool bold = false,
      PdfColor? color,
      pw.Alignment align = pw.Alignment.centerLeft,
    }) {
      return pw.Container(
        height: 42,
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(color: border, width: 0.5),
            bottom: pw.BorderSide(color: border, width: 0.5),
          ),
        ),
        child: pw.Text(
          value,
          style: base(bold: bold, color: color),
        ),
      );
    }

    pw.TableRow row(
      String description,
      String employeeShare,
      String employerShare, {
      bool total = false,
    }) {
      return pw.TableRow(
        decoration: total ? pw.BoxDecoration(color: light) : null,
        children: [
          cell(description, bold: total, color: total ? blue : null),
          cell(
            employeeShare,
            bold: total,
            color: total ? blue : null,
            align: pw.Alignment.center,
          ),
          cell(
            employerShare,
            bold: total,
            color: total ? blue : null,
            align: pw.Alignment.center,
          ),
        ],
      );
    }

    final employeeGovernment =
        remittance.employeeIncomeTax +
        remittance.employeeCpp +
        remittance.employeeEi;
    final employerGovernment = remittance.employerCpp + remittance.employerEi;
    final period =
        '${DateTimeHelper.formatDate(remittance.payPeriodStart)} - ${DateTimeHelper.formatDate(remittance.payPeriodEnd)}';
    final created = DateTimeHelper.formatDate(remittance.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    AppConfig.companyAddress,
                    style: base(size: 12),
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Container(width: 70, height: 0.8, color: navy),
                    pw.SizedBox(width: 18),
                    pw.Text(
                      'REMITTANCE SLIP',
                      style: pw.TextStyle(
                        color: navy,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 18),
                    pw.Container(width: 70, height: 0.8, color: navy),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: border),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            kv('#', 'Employee ID', remittance.employeeId),
                            kv('P', 'Employee Name', remittance.employeeName),
                            kv('@', 'Email', remittance.email),
                            kv('[]', 'Pay Frequency', remittance.payFrequency),
                          ],
                        ),
                      ),
                      pw.Container(width: 0.7, height: 106, color: border),
                      pw.SizedBox(width: 24),
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            kv('[]', 'Pay Period', period),
                            kv(
                              '>',
                              'Start',
                              DateTimeHelper.formatDate(
                                remittance.payPeriodStart,
                              ),
                            ),
                            kv(
                              '<',
                              'End',
                              DateTimeHelper.formatDate(
                                remittance.payPeriodEnd,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: border),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: blue,
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(5),
                            topRight: pw.Radius.circular(5),
                          ),
                        ),
                        child: pw.Text(
                          'REMITTANCE SUMMARY',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Table(
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1.55),
                          1: pw.FlexColumnWidth(1.05),
                          2: pw.FlexColumnWidth(1.05),
                        },
                        children: [
                          pw.TableRow(
                            decoration: pw.BoxDecoration(color: light),
                            children: [
                              cell('DESCRIPTION', bold: true),
                              cell(
                                'EMPLOYEE SHARE',
                                bold: true,
                                align: pw.Alignment.center,
                              ),
                              cell(
                                'EMPLOYER SHARE',
                                bold: true,
                                align: pw.Alignment.center,
                              ),
                            ],
                          ),
                          row(
                            'Gross Pay',
                            DateTimeHelper.currency(remittance.grossPay),
                            '-',
                          ),
                          row(
                            'Employee Income Tax (Federal + Provincial)',
                            DateTimeHelper.currency(
                              remittance.employeeIncomeTax,
                            ),
                            '-',
                          ),
                          row(
                            'CPP Deduction (Employee)',
                            DateTimeHelper.currency(remittance.employeeCpp),
                            '-',
                          ),
                          row(
                            'CPP (Employer)',
                            '-',
                            DateTimeHelper.currency(remittance.employerCpp),
                          ),
                          row(
                            'EI Deduction (Employee)',
                            DateTimeHelper.currency(remittance.employeeEi),
                            '-',
                          ),
                          row(
                            'EI (Employer)',
                            '-',
                            DateTimeHelper.currency(remittance.employerEi),
                          ),
                          row(
                            'NET PAY (TO EMPLOYEE)',
                            DateTimeHelper.currency(remittance.netPay),
                            '-',
                            total: true,
                          ),
                          row(
                            'TOTAL REMITTANCE (TO GOVERNMENT)',
                            DateTimeHelper.currency(employeeGovernment),
                            DateTimeHelper.currency(employerGovernment),
                            total: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: border),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(child: kv('[]', 'Created At', created)),
                      pw.Container(width: 0.7, height: 42, color: border),
                      pw.SizedBox(width: 28),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            kv('S', 'Status', remittance.status),
                            kv('>', 'Paid Via', remittance.paidVia ?? '-'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (remittance.notes?.trim().isNotEmpty == true) ...[
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: light,
                      border: pw.Border.all(color: border),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Notes: ', style: base(bold: true)),
                        pw.Expanded(
                          child: pw.Text(
                            remittance.notes!.trim(),
                            style: base(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                pw.Spacer(),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: blue,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Text(
                        'i',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Text(
                        'Remittances must be submitted to CRA on or before the due date to avoid interest and penalties.',
                        style: base(size: 9),
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Column(
                      children: [
                        pw.Container(width: 130, height: 0.8, color: navy),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Authorized Signature',
                          style: base(size: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 30),
                    pw.Column(
                      children: [
                        pw.Text(
                          DateTimeHelper.formatDate(DateTime.now()),
                          style: base(size: 9),
                        ),
                        pw.Container(width: 120, height: 0.8, color: navy),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Printed Date',
                          style: base(size: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> buildRemittanceList(
    List<RemittanceModel> remittances,
  ) async {
    final pdf = pw.Document();
    final navy = PdfColor.fromHex('#071846');
    final header = PdfColor.fromHex('#EFF6FF');
    final border = PdfColor.fromHex('#CBD5E1');
    final total = remittances.fold<double>(
      0,
      (sum, record) => sum + record.totalRemittance,
    );

    pw.TextStyle style({bool bold = false, double size = 7.4}) {
      return pw.TextStyle(
        color: navy,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget cell(String value, {bool bold = false, PdfColor? color}) {
      return pw.Container(
        color: color,
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(value, style: style(bold: bold), maxLines: 3),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              AppConfig.companyName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              AppConfig.companyAddress,
              textAlign: pw.TextAlign.center,
              style: style(size: 8.5),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Text(
                  'Remittance Records',
                  style: style(size: 14, bold: true),
                ),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: pw.BoxDecoration(
                    color: header,
                    border: pw.Border.all(color: border),
                  ),
                  child: pw.Text(
                    'TOTAL: ${DateTimeHelper.currency(total)}',
                    style: style(size: 11, bold: true),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (_) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Printed: ${DateTimeHelper.formatDate(DateTime.now())}',
            style: style(size: 7),
          ),
        ),
        build: (_) => [
          pw.Table(
            border: pw.TableBorder.all(color: border, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.35),
              1: pw.FlexColumnWidth(0.75),
              2: pw.FlexColumnWidth(1.25),
              3: pw.FlexColumnWidth(0.75),
              4: pw.FlexColumnWidth(0.75),
              5: pw.FlexColumnWidth(0.75),
              6: pw.FlexColumnWidth(0.75),
              7: pw.FlexColumnWidth(0.75),
              8: pw.FlexColumnWidth(0.8),
              9: pw.FlexColumnWidth(0.95),
              10: pw.FlexColumnWidth(0.75),
              11: pw.FlexColumnWidth(0.9),
              12: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                children: [
                  cell('Employee', bold: true, color: header),
                  cell('Frequency', bold: true, color: header),
                  cell('Period', bold: true, color: header),
                  cell('Gross', bold: true, color: header),
                  cell('Tax', bold: true, color: header),
                  cell('Emp CPP', bold: true, color: header),
                  cell('Er CPP', bold: true, color: header),
                  cell('Emp EI', bold: true, color: header),
                  cell('Er EI', bold: true, color: header),
                  cell('Remittance', bold: true, color: header),
                  cell('Status', bold: true, color: header),
                  cell('Paid Via', bold: true, color: header),
                  cell('Notes', bold: true, color: header),
                ],
              ),
              for (final record in remittances)
                pw.TableRow(
                  children: [
                    cell('${record.employeeName}\n${record.employeeId}'),
                    cell(record.payFrequency),
                    cell(
                      '${DateTimeHelper.formatDate(record.payPeriodStart)} - '
                      '${DateTimeHelper.formatDate(record.payPeriodEnd)}',
                    ),
                    cell(DateTimeHelper.currency(record.grossPay)),
                    cell(DateTimeHelper.currency(record.employeeIncomeTax)),
                    cell(DateTimeHelper.currency(record.employeeCpp)),
                    cell(DateTimeHelper.currency(record.employerCpp)),
                    cell(DateTimeHelper.currency(record.employeeEi)),
                    cell(DateTimeHelper.currency(record.employerEi)),
                    cell(DateTimeHelper.currency(record.totalRemittance)),
                    cell(record.status),
                    cell(record.paidVia ?? '-'),
                    cell(
                      record.notes?.trim().isNotEmpty == true
                          ? record.notes!.trim()
                          : '-',
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<void> printRemittanceList(List<RemittanceModel> remittances) {
    return Printing.layoutPdf(
      onLayout: (_) => buildRemittanceList(remittances),
    );
  }
}
