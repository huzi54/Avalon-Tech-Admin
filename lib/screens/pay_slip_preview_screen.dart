import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/payroll_model.dart';
import '../providers/payroll_provider.dart';
import '../services/pdf_service.dart';
import '../utils/date_time_helper.dart';

class PaySlipPreviewScreen extends StatelessWidget {
  const PaySlipPreviewScreen({required this.payrollId, super.key});

  final String payrollId;

  static const List<String> statusOptions = ['Unpaid', 'Paid'];
  static const List<String> paidViaOptions = [
    'Cash',
    'Check',
    'Direct Deposit',
    'E-Transfer',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayrollProvider>();
    final payroll = _findPayroll(provider);

    if (payroll == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Slip Preview')),
        body: const Center(child: Text('Payroll record not found.')),
      );
    }

    final pdfService = const PdfService();
    final isPaid = payroll.slipStatus.toLowerCase() == 'paid';

    return Scaffold(
      appBar: AppBar(title: Text('Pay Slip: ${payroll.employeeName}')),
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Payment', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: payroll.slipStatus,
                  decoration: const InputDecoration(labelText: 'Slip Status'),
                  items: [
                    for (final status in statusOptions)
                      DropdownMenuItem(value: status, child: Text(status)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<PayrollProvider>().updateSlipPayment(
                      payrollId: payroll.id,
                      slipStatus: value,
                      paidVia: value == 'Paid'
                          ? payroll.paidVia ?? paidViaOptions.first
                          : null,
                    );
                  },
                ),
                if (isPaid) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: payroll.paidVia ?? paidViaOptions.first,
                    decoration: const InputDecoration(labelText: 'Paid Via'),
                    items: [
                      for (final option in paidViaOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<PayrollProvider>().updateSlipPayment(
                        payrollId: payroll.id,
                        slipStatus: 'Paid',
                        paidVia: value,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                _InfoRow(label: 'Employee ID', value: payroll.employeeId),
                _InfoRow(
                  label: 'Final Payable',
                  value: DateTimeHelper.currency(payroll.finalPayableAmount),
                ),
                _InfoRow(
                  label: 'Pay Period',
                  value:
                      '${DateTimeHelper.formatDate(payroll.payPeriodStart)} - '
                      '${DateTimeHelper.formatDate(payroll.payPeriodEnd)}',
                ),
                if (payroll.payDate != null)
                  _InfoRow(
                    label: 'Pay Date',
                    value: DateTimeHelper.formatDate(payroll.payDate!),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: PdfPreview(
              build: (_) => pdfService.buildPaySlip(payroll),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowSharing: false,
              pdfFileName: 'payslip-${payroll.employeeId}.pdf',
            ),
          ),
        ],
      ),
    );
  }

  PayrollModel? _findPayroll(PayrollProvider provider) {
    for (final payroll in provider.payrolls) {
      if (payroll.id == payrollId) return payroll;
    }
    return provider.currentPreview?.id == payrollId
        ? provider.currentPreview
        : null;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
