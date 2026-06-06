import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/remittance_model.dart';
import '../providers/payroll_provider.dart';
import '../services/pdf_service.dart';
import '../utils/date_time_helper.dart';

class RemittancePreviewScreen extends StatelessWidget {
  const RemittancePreviewScreen({required this.remittanceId, super.key});

  final String remittanceId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayrollProvider>();
    final remittance = _findRemittance(provider);

    if (remittance == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Remittance Preview')),
        body: const Center(child: Text('Remittance record not found.')),
      );
    }

    final pdfService = const PdfService();

    return Scaffold(
      appBar: AppBar(title: Text('Remittance: ${remittance.employeeName}')),
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Remittance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: remittance.status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<PayrollProvider>().updateRemittanceStatus(
                      remittanceId: remittance.id,
                      status: value,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _InfoRow(label: 'Employee ID', value: remittance.employeeId),
                _InfoRow(label: 'Email', value: remittance.email),
                _InfoRow(
                  label: 'Pay Period',
                  value:
                      '${DateTimeHelper.formatDate(remittance.payPeriodStart)} - '
                      '${DateTimeHelper.formatDate(remittance.payPeriodEnd)}',
                ),
                _InfoRow(
                  label: 'Total Remittance',
                  value: DateTimeHelper.currency(remittance.totalRemittance),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: PdfPreview(
              build: (_) => pdfService.buildRemittanceSlip(remittance),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowSharing: false,
              pdfFileName: 'remittance-${remittance.employeeId}.pdf',
            ),
          ),
        ],
      ),
    );
  }

  RemittanceModel? _findRemittance(PayrollProvider provider) {
    for (final remittance in provider.remittances) {
      if (remittance.id == remittanceId) return remittance;
    }
    return null;
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
