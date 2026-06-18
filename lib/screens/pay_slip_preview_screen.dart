import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../providers/employee_provider.dart';
import '../providers/payroll_provider.dart';
import '../services/pdf_service.dart';
import '../services/payroll_service.dart';
import '../utils/app_input_formatters.dart';
import '../utils/date_time_helper.dart';
import 'salary_calculator_screen.dart';

class PaySlipPreviewScreen extends StatefulWidget {
  const PaySlipPreviewScreen({
    required this.payrollId,
    this.onBack,
    this.onEdit,
    super.key,
  });

  final String payrollId;
  final VoidCallback? onBack;
  final ValueChanged<PayrollModel>? onEdit;

  @override
  State<PaySlipPreviewScreen> createState() => _PaySlipPreviewScreenState();
}

class _PaySlipPreviewScreenState extends State<PaySlipPreviewScreen> {
  final _checkNumberController = TextEditingController();

  static const _statusOptions = ['Unpaid', 'Paid'];
  static const _paidViaOptions = [
    'E-Transfer',
    'Direct Deposit',
    'Cash',
    'Check',
  ];

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
    if (_checkNumberController.text.isEmpty &&
        payroll.checkNumber?.isNotEmpty == true) {
      _checkNumberController.text = payroll.checkNumber!;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  tooltip: 'Back to payroll',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
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
            _OwnerPreview(
              payroll: payroll,
              employee: employee,
              taxableLabel: taxableLabel,
              checkNumberController: _checkNumberController,
              paidViaOptions: _paidViaOptions,
              statusOptions: _statusOptions,
            ),
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
    final onEdit = widget.onEdit;
    if (onEdit != null) {
      onEdit(payroll);
      return;
    }
    context.push(
      AppRoutes.salaryCalculator,
      extra: SalaryCalculatorArgs(
        employeeId: payroll.employeeId,
        payrollId: payroll.id,
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
  const _OwnerPreview({
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
              _PaymentControls(
                payroll: payroll,
                checkNumberController: checkNumberController,
                paidViaOptions: paidViaOptions,
                statusOptions: statusOptions,
              ),
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
            build: (_) => pdfService.buildEmployeePaySlip(
              payroll,
              designation: employee?.role ?? 'Employee',
              otherTaxableLabel: taxableLabel,
              checkNumber: payroll.checkNumber,
              includeOwnerAnnualDetails: true,
            ),
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
              _PaymentControls(
                payroll: payroll,
                checkNumberController: checkNumberController,
                paidViaOptions: paidViaOptions,
                statusOptions: statusOptions,
              ),
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
              checkNumber: payroll.checkNumber,
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

class _PaymentControls extends StatefulWidget {
  const _PaymentControls({
    required this.payroll,
    required this.checkNumberController,
    required this.paidViaOptions,
    required this.statusOptions,
  });

  final PayrollModel payroll;
  final TextEditingController checkNumberController;
  final List<String> paidViaOptions;
  final List<String> statusOptions;

  @override
  State<_PaymentControls> createState() => _PaymentControlsState();
}

class _PaymentControlsState extends State<_PaymentControls> {
  late final TextEditingController _paidAmountController;
  late String _displayedStatus;

  @override
  void initState() {
    super.initState();
    _displayedStatus = widget.payroll.slipStatus;
    _paidAmountController = TextEditingController(
      text: widget.payroll.paidAmount > 0
          ? widget.payroll.paidAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant _PaymentControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payroll.slipStatus != widget.payroll.slipStatus) {
      _displayedStatus = widget.payroll.slipStatus;
    }
    if (oldWidget.payroll.paidAmount != widget.payroll.paidAmount &&
        widget.payroll.paidAmount > 0) {
      _paidAmountController.text = widget.payroll.paidAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  double get _enteredAmount =>
      double.tryParse(_paidAmountController.text.trim()) ?? 0;

  Future<void> _handleAmountChanged() async {
    final amount = _enteredAmount;
    final matchesPayable =
        (amount - widget.payroll.finalPayableAmount).abs() < 0.005;

    if (!matchesPayable && _displayedStatus == 'Paid') {
      setState(() => _displayedStatus = 'Unpaid');
      widget.checkNumberController.clear();
      await context.read<PayrollProvider>().updateSlipPayment(
        payrollId: widget.payroll.id,
        slipStatus: 'Unpaid',
        paidAmount: 0,
      );
      return;
    }

    if (mounted) setState(() {});
  }

  Future<void> _updateStatus(String value, String paidVia) async {
    if (value != 'Paid') {
      setState(() => _displayedStatus = 'Unpaid');
      widget.checkNumberController.clear();
      await context.read<PayrollProvider>().updateSlipPayment(
        payrollId: widget.payroll.id,
        slipStatus: value,
        paidAmount: 0,
      );
      return;
    }

    final amount = _enteredAmount;
    final payable = widget.payroll.finalPayableAmount;
    final assessment = const PayrollService().assessPaymentAmount(
      enteredAmount: amount,
      finalPayableAmount: payable,
    );
    if (assessment.status == PaymentAmountStatus.underpaid) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Amount is less than payable'),
          content: Text(
            'Enter ${DateTimeHelper.currency(payable)} before marking this '
            'slip as paid. The entered amount is '
            '${DateTimeHelper.currency(amount)}.',
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    if (assessment.status == PaymentAmountStatus.overpaid) {
      final extra = assessment.difference;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Warning: amount exceeds payable'),
          content: Text(
            'You entered ${DateTimeHelper.currency(extra)} more than the final '
            'payable amount. This will be saved as extra cash given to the '
            'employee and carried forward as an outstanding credit.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Go Back'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('Proceed Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    await context.read<PayrollProvider>().updateSlipPayment(
      payrollId: widget.payroll.id,
      slipStatus: 'Paid',
      paidVia: paidVia,
      checkNumber: paidVia == 'Check'
          ? widget.checkNumberController.text
          : null,
      paidAmount: amount,
    );
    if (mounted) setState(() => _displayedStatus = 'Paid');
  }

  @override
  Widget build(BuildContext context) {
    final payroll = widget.payroll;
    final paidVia = widget.paidViaOptions.contains(payroll.paidVia)
        ? payroll.paidVia!
        : widget.paidViaOptions.first;
    final showCheck = _displayedStatus == 'Paid' && paidVia == 'Check';
    final hasAmount = _enteredAmount > 0;

    return Column(
      children: [
        TextField(
          controller: _paidAmountController,
          inputFormatters: [AppInputFormatters.number],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount Paid',
            prefixText: r'$',
            helperText:
                'Final payable: ${DateTimeHelper.currency(payroll.finalPayableAmount)}',
          ),
          onChanged: (_) => _handleAmountChanged(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_displayedStatus),
          initialValue: _displayedStatus,
          decoration: const InputDecoration(labelText: 'Payment Status'),
          items: [
            for (final status in widget.statusOptions)
              DropdownMenuItem(value: status, child: Text(status)),
          ],
          onChanged: !hasAmount
              ? null
              : (value) async {
                  if (value == null) return;
                  await _updateStatus(value, paidVia);
                },
        ),
        if (_displayedStatus == 'Paid') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: paidVia,
            decoration: const InputDecoration(labelText: 'Paid Via'),
            items: [
              for (final option in widget.paidViaOptions)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (value) async {
              if (value == null) return;
              if (value != 'Check') widget.checkNumberController.clear();
              await _updateStatus('Paid', value);
            },
          ),
        ],
        if (showCheck) ...[
          const SizedBox(height: 12),
          TextField(
            controller: widget.checkNumberController,
            decoration: const InputDecoration(labelText: 'Check Number'),
            onChanged: (value) {
              context.read<PayrollProvider>().updateSlipPayment(
                payrollId: payroll.id,
                slipStatus: 'Paid',
                paidVia: 'Check',
                checkNumber: value,
                paidAmount: _enteredAmount,
              );
            },
          ),
        ],
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
