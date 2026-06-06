import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../providers/employee_provider.dart';
import '../providers/payroll_provider.dart';
import '../services/pdf_service.dart';
import '../utils/app_input_formatters.dart';
import '../utils/date_time_helper.dart';
import 'salary_calculator_screen.dart';

class PaySlipPreviewScreen extends StatefulWidget {
  const PaySlipPreviewScreen({required this.payrollId, super.key});

  final String payrollId;

  @override
  State<PaySlipPreviewScreen> createState() => _PaySlipPreviewScreenState();
}

class _PaySlipPreviewScreenState extends State<PaySlipPreviewScreen> {
  final _checkNumberController = TextEditingController();

  static const _statusOptions = ['Unpaid', 'Paid'];
  static const _paidViaOptions = ['EMT', 'Cheque', 'Cash'];

  @override
  void dispose() {
    _checkNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payrollProvider = context.watch<PayrollProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final payroll = _findPayroll(payrollProvider);

    if (payroll == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Slip Preview')),
        body: const Center(child: Text('Payroll record not found.')),
      );
    }

    final employee = employeeProvider.findById(payroll.employeeId);
    final taxableLabel = payrollProvider.otherTaxableLabel(payroll.id);
    final checkNumber = payrollProvider.checkNumber(payroll.id);
    if (_checkNumberController.text.isEmpty && checkNumber != null) {
      _checkNumberController.text = checkNumber;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pay Slip: ${payroll.employeeName}'),
          actions: [
            TextButton.icon(
              onPressed: () => _openEdit(payroll),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Payroll'),
            ),
            const SizedBox(width: 12),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Owner Preview'),
              Tab(text: 'Employee Slip'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OwnerPreview(payroll: payroll),
            _EmployeeSlipPreview(
              payroll: payroll,
              employee: employee,
              taxableLabel: taxableLabel,
              checkNumberController: _checkNumberController,
              paidViaOptions: _paidViaOptions,
              statusOptions: _statusOptions,
            ),
          ],
        ),
      ),
    );
  }

  void _openEdit(PayrollModel payroll) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalaryCalculatorScreen(
          initialArgs: SalaryCalculatorArgs(
            employeeId: payroll.employeeId,
            payrollId: payroll.id,
          ),
        ),
      ),
    );
  }

  PayrollModel? _findPayroll(PayrollProvider provider) {
    for (final payroll in provider.payrolls) {
      if (payroll.id == widget.payrollId) return payroll;
    }
    return provider.currentPreview?.id == widget.payrollId
        ? provider.currentPreview
        : null;
  }
}

class _OwnerPreview extends StatelessWidget {
  const _OwnerPreview({required this.payroll});

  final PayrollModel payroll;

  @override
  Widget build(BuildContext context) {
    final pdfService = const PdfService();

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Owner Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
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
              _InfoRow(
                label: 'Total Remittance',
                value: DateTimeHelper.currency(payroll.totalRemittance),
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
            pdfFileName: 'owner-payslip-${payroll.employeeId}.pdf',
          ),
        ),
      ],
    );
  }
}

class _EmployeeSlipPreview extends StatelessWidget {
  const _EmployeeSlipPreview({
    required this.payroll,
    required this.employee,
    required this.taxableLabel,
    required this.checkNumberController,
    required this.paidViaOptions,
    required this.statusOptions,
  });

  final PayrollModel payroll;
  final EmployeeModel? employee;
  final String taxableLabel;
  final TextEditingController checkNumberController;
  final List<String> paidViaOptions;
  final List<String> statusOptions;

  @override
  Widget build(BuildContext context) {
    final pdfService = const PdfService();
    final paidVia = paidViaOptions.contains(payroll.paidVia)
        ? payroll.paidVia
        : paidViaOptions.first;
    final showCheque = payroll.slipStatus == 'Paid' && paidVia == 'Cheque';

    return Row(
      children: [
        SizedBox(
          width: 340,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Employee Slip',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: payroll.slipStatus,
                decoration: const InputDecoration(labelText: 'Payment Status'),
                items: [
                  for (final status in statusOptions)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  context.read<PayrollProvider>().updateSlipPayment(
                    payrollId: payroll.id,
                    slipStatus: value,
                    paidVia: value == 'Paid' ? paidVia : null,
                    checkNumber: checkNumberController.text,
                  );
                },
              ),
              if (payroll.slipStatus == 'Paid') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paidVia,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                  ),
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
                      checkNumber: checkNumberController.text,
                    );
                  },
                ),
              ],
              if (showCheque) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: checkNumberController,
                  inputFormatters: [AppInputFormatters.digitsOnly],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cheque Number'),
                  onChanged: (value) {
                    context.read<PayrollProvider>().updateSlipPayment(
                      payrollId: payroll.id,
                      slipStatus: 'Paid',
                      paidVia: 'Cheque',
                      checkNumber: value,
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              _InfoRow(label: 'Name', value: payroll.employeeName),
              _InfoRow(label: 'Employee ID', value: payroll.employeeId),
              _InfoRow(
                label: 'Designation',
                value: employee?.role ?? 'Employee',
              ),
              _InfoRow(label: 'Pay Frequency', value: payroll.payFrequency),
              _InfoRow(
                label: 'Final Payable',
                value: DateTimeHelper.currency(payroll.finalPayableAmount),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: PdfPreview(
            build: (_) => pdfService.buildEmployeePaySlip(
              payroll,
              designation: employee?.role ?? 'Employee',
              otherTaxableLabel: taxableLabel,
              checkNumber: checkNumberController.text,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowSharing: false,
            pdfFileName: 'employee-payslip-${payroll.employeeId}.pdf',
          ),
        ),
      ],
    );
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
