import 'package:flutter/material.dart';

import '../models/payroll_model.dart';
import '../utils/date_time_helper.dart';

class PayrollTable extends StatelessWidget {
  const PayrollTable({
    required this.payrolls,
    required this.onPreview,
    super.key,
  });

  final List<PayrollModel> payrolls;
  final ValueChanged<PayrollModel> onPreview;

  @override
  Widget build(BuildContext context) {
    if (payrolls.isEmpty) {
      return const Center(child: Text('No payroll records saved yet.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        ),
        columns: const [
          DataColumn(label: Text('Employee')),
          DataColumn(label: Text('Period')),
          DataColumn(label: Text('Hours')),
          DataColumn(label: Text('Gross Pay')),
          DataColumn(label: Text('Deductions')),
          DataColumn(label: Text('Final Payable')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('')),
        ],
        rows: payrolls.map((payroll) {
          final period =
              '${DateTimeHelper.formatDate(payroll.payPeriodStart)} - '
              '${DateTimeHelper.formatDate(payroll.payPeriodEnd)}';

          return DataRow(
            cells: [
              DataCell(Text(payroll.employeeName)),
              DataCell(Text(period)),
              DataCell(Text(payroll.hours.toStringAsFixed(2))),
              DataCell(Text(DateTimeHelper.currency(payroll.grossPay))),
              DataCell(Text(DateTimeHelper.currency(payroll.totalDeductions))),
              DataCell(
                Text(DateTimeHelper.currency(payroll.finalPayableAmount)),
              ),
              DataCell(Text(payroll.slipStatus)),
              DataCell(
                IconButton(
                  tooltip: 'Preview pay slip',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => onPreview(payroll),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
