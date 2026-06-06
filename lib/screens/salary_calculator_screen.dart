import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../providers/employee_provider.dart';
import '../providers/payroll_provider.dart';
import '../services/payroll_service.dart';
import '../utils/app_input_formatters.dart';
import '../utils/date_time_helper.dart';
import '../utils/responsive.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/payroll_table.dart';
import 'pay_slip_preview_screen.dart';

class SalaryCalculatorArgs {
  const SalaryCalculatorArgs({
    required this.employeeId,
    this.hours,
    this.payrollId,
  });

  final String employeeId;
  final double? hours;
  final String? payrollId;
}

class SalaryCalculatorScreen extends StatefulWidget {
  const SalaryCalculatorScreen({this.initialArgs, super.key});

  static const routeName = '/salary-calculator';

  final SalaryCalculatorArgs? initialArgs;

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();
  final _periodsController = TextEditingController(text: '26');
  final _taxableController = TextEditingController(text: '0.00');
  final _customTaxableTypeController = TextEditingController();
  final _nonTaxableController = TextEditingController(text: '0.00');
  final _otherReasonController = TextEditingController();
  final _nonTaxableNoteController = TextEditingController();

  EmployeeModel? _selectedEmployee;
  String _payFrequency = 'Biweekly';
  String _otherTaxableType = 'Vacation Pay';
  String _deductionReason = 'Advance';
  String? _editingPayrollId;
  DateTime _periodStart = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _periodEnd = DateTime.now();
  DateTime _payDate = DateTime.now();
  bool _handledArgs = false;

  static const _taxableTypeOptions = [
    'Vacation Pay',
    'Bonus',
    'Pay Back',
    'Custom',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledArgs) return;
    _handledArgs = true;

    final employees = context.read<EmployeeProvider>().employees;
    final args =
        widget.initialArgs ?? ModalRoute.of(context)?.settings.arguments;
    if (args is SalaryCalculatorArgs) {
      final employee = context.read<EmployeeProvider>().findById(
        args.employeeId,
      );
      _selectEmployee(employee);
      _editingPayrollId = args.payrollId;
      final payroll = args.payrollId == null
          ? null
          : context
                .read<PayrollProvider>()
                .payrolls
                .where((item) => item.id == args.payrollId)
                .firstOrNull;
      if (payroll != null) {
        _hoursController.text = payroll.hours.toStringAsFixed(2);
        _rateController.text = payroll.rate.toStringAsFixed(2);
        _periodsController.text = payroll.numberOfPayPeriods.toString();
        _taxableController.text = payroll.otherTaxableIncome.toStringAsFixed(2);
        _nonTaxableController.text = payroll.otherNonTaxableDeduction
            .toStringAsFixed(2);
        _periodStart = payroll.payPeriodStart;
        _periodEnd = payroll.payPeriodEnd;
        _payDate = payroll.payDate ?? payroll.payPeriodEnd;
        _payFrequency = payroll.payFrequency;
        _deductionReason = payroll.nonTaxableDeductionReason ?? 'Advance';
        _nonTaxableNoteController.text = payroll.nonTaxableDeductionNote ?? '';
        final label = context.read<PayrollProvider>().otherTaxableLabel(
          payroll.id,
        );
        if (_taxableTypeOptions.contains(label)) {
          _otherTaxableType = label;
        } else {
          _otherTaxableType = 'Custom';
          _customTaxableTypeController.text = label;
        }
      }
    } else if (employees.isNotEmpty) {
      _selectEmployee(employees.first);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _rateController.dispose();
    _periodsController.dispose();
    _taxableController.dispose();
    _customTaxableTypeController.dispose();
    _nonTaxableController.dispose();
    _otherReasonController.dispose();
    _nonTaxableNoteController.dispose();
    super.dispose();
  }

  void _selectEmployee(EmployeeModel? employee) {
    setState(() {
      _selectedEmployee = employee;
    });
  }

  void _setFrequency(String? value) {
    if (value == null) return;
    setState(() {
      _payFrequency = value;
      _periodsController.text = PayrollService.payPeriodsByFrequency[value]!
          .toString();
    });
  }

  Future<void> _pickDate(
    DateTime initial,
    ValueChanged<DateTime> update,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => update(picked));
  }

  PayrollCalculationResult _calculation(PayrollProvider provider) {
    return provider.previewCalculation(
      hours: _number(_hoursController),
      rate: _number(_rateController),
      numberOfPayPeriods: int.tryParse(_periodsController.text) ?? 26,
      otherTaxableIncome: _number(_taxableController),
      otherNonTaxableDeduction: _number(_nonTaxableController),
    );
  }

  Future<void> _savePayroll() async {
    final employee = _selectedEmployee;
    if (employee == null) return;

    final provider = context.read<PayrollProvider>();
    final taxableLabel = _otherTaxableType == 'Custom'
        ? _customTaxableTypeController.text.trim()
        : _otherTaxableType;
    final editingPayrollId = _editingPayrollId;
    final payroll = editingPayrollId == null
        ? await provider.calculateAndSave(
            employee: employee.copyWith(hourlyRate: _number(_rateController)),
            hours: _number(_hoursController),
            payPeriodStart: _periodStart,
            payPeriodEnd: _periodEnd,
            payDate: _payDate,
            payFrequency: _payFrequency,
            numberOfPayPeriods: int.tryParse(_periodsController.text) ?? 26,
            otherTaxableIncome: _number(_taxableController),
            otherTaxableLabel: taxableLabel,
            otherNonTaxableDeduction: _number(_nonTaxableController),
            nonTaxableDeductionReason: _deductionReason == 'Other'
                ? _otherReasonController.text.trim()
                : _deductionReason,
            nonTaxableDeductionNote:
                _nonTaxableNoteController.text.trim().isEmpty
                ? null
                : _nonTaxableNoteController.text.trim(),
          )
        : await provider.updateCalculatedPayroll(
            payrollId: editingPayrollId,
            employee: employee.copyWith(hourlyRate: _number(_rateController)),
            hours: _number(_hoursController),
            payPeriodStart: _periodStart,
            payPeriodEnd: _periodEnd,
            payDate: _payDate,
            payFrequency: _payFrequency,
            numberOfPayPeriods: int.tryParse(_periodsController.text) ?? 26,
            otherTaxableIncome: _number(_taxableController),
            otherTaxableLabel: taxableLabel,
            otherNonTaxableDeduction: _number(_nonTaxableController),
            nonTaxableDeductionReason: _deductionReason == 'Other'
                ? _otherReasonController.text.trim()
                : _deductionReason,
            nonTaxableDeductionNote:
                _nonTaxableNoteController.text.trim().isEmpty
                ? null
                : _nonTaxableNoteController.text.trim(),
          );

    if (payroll == null) return;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          editingPayrollId == null ? 'Payroll Calculated' : 'Payroll Updated',
        ),
        content: Text(
          'Final Payable Amount: '
          '${DateTimeHelper.currency(payroll.finalPayableAmount)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  double _number(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  void _openPaySlipPreview(PayrollModel payroll) {
    context.read<PayrollProvider>().preview(payroll);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaySlipPreviewScreen(payrollId: payroll.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Salary Calculator')),
      body: Consumer2<EmployeeProvider, PayrollProvider>(
        builder: (context, employeeProvider, payrollProvider, _) {
          final calculation = _calculation(payrollProvider);

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Responsive(
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 430, child: _inputPanel(employeeProvider)),
                  const SizedBox(width: 20),
                  Expanded(child: _resultsPanel(calculation, payrollProvider)),
                ],
              ),
              compact: ListView(
                children: [
                  _inputPanel(employeeProvider),
                  const SizedBox(height: 20),
                  _resultsPanel(calculation, payrollProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inputPanel(EmployeeProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payroll Inputs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CustomDropdown<EmployeeModel>(
              label: 'Employee',
              value: _selectedEmployee,
              items: provider.employees,
              itemLabel: (employee) => '${employee.name} (${employee.id})',
              onChanged: _selectEmployee,
            ),
            const SizedBox(height: 12),
            CustomDropdown<String>(
              label: 'Pay Frequency',
              value: _payFrequency,
              items: PayrollService.payPeriodsByFrequency.keys.toList(),
              itemLabel: (value) => value,
              onChanged: _setFrequency,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _periodsController,
              label: 'Number of Pay Periods',
              keyboardType: TextInputType.number,
              inputFormatters: [AppInputFormatters.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _dateButton('Pay Period Start', _periodStart, (value) {
              _periodStart = value;
            }),
            const SizedBox(height: 12),
            _dateButton('Pay Period End', _periodEnd, (value) {
              _periodEnd = value;
            }),
            const SizedBox(height: 12),
            _dateButton('Pay Date', _payDate, (value) {
              _payDate = value;
            }),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _hoursController,
              label: 'Total / Working Hours',
              keyboardType: TextInputType.number,
              inputFormatters: [AppInputFormatters.number],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _rateController,
              label: 'Hourly Rate',
              keyboardType: TextInputType.number,
              prefixText: r'$',
              inputFormatters: [AppInputFormatters.number],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _taxableController,
              label: 'Other Taxable Income Amount',
              keyboardType: TextInputType.number,
              prefixText: r'$',
              inputFormatters: [AppInputFormatters.number],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomDropdown<String>(
              label: 'Other Taxable Income Type',
              value: _otherTaxableType,
              items: _taxableTypeOptions,
              itemLabel: (value) => value,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _otherTaxableType = value);
              },
            ),
            if (_otherTaxableType == 'Custom') ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: _customTaxableTypeController,
                label: 'Custom Taxable Income Type',
                inputFormatters: [
                  AppInputFormatters.textOnly,
                  AppInputFormatters.capitalizeFirst,
                ],
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: 12),
            CustomDropdown<String>(
              label: 'Other Non-Taxable Deduction Reason',
              value: _deductionReason,
              items: const ['Arrears', 'Advance', 'Purchase', 'Other'],
              itemLabel: (value) => value,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _deductionReason = value);
              },
            ),
            if (_deductionReason == 'Other') ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: _otherReasonController,
                label: 'Custom Reason',
                inputFormatters: [
                  AppInputFormatters.textOnly,
                  AppInputFormatters.capitalizeFirst,
                ],
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: 12),
            CustomTextField(
              controller: _nonTaxableController,
              label: 'Other Non-Taxable Deduction',
              keyboardType: TextInputType.number,
              prefixText: r'$',
              inputFormatters: [AppInputFormatters.number],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _nonTaxableNoteController,
              label: 'Non-Taxable Deduction Note (Optional)',
              inputFormatters: [
                AppInputFormatters.sentenceText,
                AppInputFormatters.capitalizeFirst,
              ],
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _selectedEmployee == null ? null : _savePayroll,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _editingPayrollId == null ? 'Save Payroll' : 'Update Payroll',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(
    String label,
    DateTime value,
    ValueChanged<DateTime> update,
  ) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_month_outlined),
      onPressed: () => _pickDate(value, update),
      label: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(DateTimeHelper.formatDate(value))],
      ),
    );
  }

  Widget _resultsPanel(
    PayrollCalculationResult calculation,
    PayrollProvider provider,
  ) {
    return ListView(
      shrinkWrap: true,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Calculation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _summaryGrid(calculation),
                const SizedBox(height: 18),
                _amountTable('Deductions', [
                  _AmountLine('Regular Earnings', calculation.regularIncome),
                  _AmountLine(
                    'Other Taxable Income',
                    _number(_taxableController),
                  ),
                  _AmountLine('Gross Pay', calculation.grossPay),
                  _AmountLine('Annual Income', calculation.annualIncome),
                  _AmountLine(
                    'Federal TD1 Amount',
                    calculation.federalTd1Amount,
                  ),
                  _AmountLine(
                    'Provincial TD1 Amount',
                    calculation.provincialTd1Amount,
                  ),
                  _AmountLine(
                    'Canada Employment Amount',
                    calculation.canadaEmploymentAmount,
                  ),
                  _AmountLine(
                    'CPP Basic Exemption Per Period',
                    calculation.cppBasicExemptionPerPeriod,
                  ),
                  _AmountLine('EI Deduction', calculation.ei),
                  _AmountLine('Federal Tax', calculation.federalTax),
                  _AmountLine('Provincial Tax', calculation.provincialTax),
                  _AmountLine(
                    'Total Tax (Federal Tax + Provincial Tax)',
                    calculation.totalTax,
                  ),
                  _AmountLine('Total Deductions', calculation.totalDeductions),
                  _AmountLine(
                    'Net Pay (Before other deductions)',
                    calculation.netPay,
                  ),
                  _AmountLine(
                    'Other Non-Taxable Deduction',
                    _number(_nonTaxableController),
                  ),
                  _AmountLine(
                    'Final Payable Amount',
                    calculation.finalPayableAmount,
                  ),
                ]),
                const SizedBox(height: 18),
                _amountTable('Remittance', [
                  _AmountLine(
                    'Employee Income Tax (Federal Tax + Provincial Tax)',
                    calculation.federalTax + calculation.provincialTax,
                  ),
                  _AmountLine('Employee CPP', calculation.cpp),
                  _AmountLine('Employee EI Deduction', calculation.ei),
                  _AmountLine('Employer CPP', calculation.employerCpp),
                  _AmountLine('Employer EI', calculation.employerEi),
                  _AmountLine(
                    'Total Remittance',
                    calculation.federalTax +
                        calculation.provincialTax +
                        calculation.cpp +
                        calculation.ei +
                        calculation.employerCpp +
                        calculation.employerEi,
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 290,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: PayrollTable(
                payrolls: provider.payrolls,
                onPreview: _openPaySlipPreview,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryGrid(PayrollCalculationResult calculation) {
    final values = [
      _AmountLine('Regular Income', calculation.regularIncome),
      _AmountLine('Gross Pay', calculation.grossPay),
      _AmountLine('Annual Income', calculation.annualIncome),
      _AmountLine('Total Deductions', calculation.totalDeductions),
      _AmountLine('Net Salary', calculation.netPay),
      _AmountLine('Final Payable Amount', calculation.finalPayableAmount),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final value in values)
          SizedBox(
            width: 210,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value.label),
                    const SizedBox(height: 8),
                    Text(
                      DateTimeHelper.currency(value.amount),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _amountTable(String title, List<_AmountLine> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Theme.of(context).dividerColor),
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth()},
          children: [
            for (final line in lines)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(line.label),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(DateTimeHelper.currency(line.amount)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _AmountLine {
  const _AmountLine(this.label, this.amount);

  final String label;
  final double amount;
}
