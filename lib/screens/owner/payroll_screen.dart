import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../services/print_service.dart';
import '../../utils/date_time_helper.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/payroll_table.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  EmployeeModel? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
      context.read<PayrollProvider>().loadPayrolls();
    });
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) return;
    final now = DateTime.now();
    await context.read<PayrollProvider>().calculateAndSave(
      employee: _selectedEmployee!,
      hours: double.parse(_hoursController.text),
      payPeriodStart: DateTime(now.year, now.month, 1),
      payPeriodEnd: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final printService = const PrintService();

    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Calculator')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final calculator = _CalculatorPanel(
            formKey: _formKey,
            hoursController: _hoursController,
            selectedEmployee: _selectedEmployee,
            onEmployeeChanged: (employee) {
              setState(() => _selectedEmployee = employee);
            },
            onCalculate: _calculate,
          );
          final records = Consumer<PayrollProvider>(
            builder: (context, provider, _) => PayrollTable(
              payrolls: provider.payrolls,
              onPreview: provider.preview,
            ),
          );
          final preview = Consumer<PayrollProvider>(
            builder: (context, provider, _) {
              final payroll = provider.currentPreview;
              if (payroll == null) {
                return const Center(
                  child: Text('Select a payroll to preview.'),
                );
              }
              return Column(
                children: [
                  ListTile(
                    title: Text('Pay slip: ${payroll.employeeName}'),
                    subtitle: Text(
                      'Net ${DateTimeHelper.currency(payroll.netPay)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Print',
                      onPressed: () => printService.printPaySlip(payroll),
                      icon: const Icon(Icons.print_outlined),
                    ),
                  ),
                  Expanded(
                    child: PdfPreview(
                      build: (_) => printService.buildPaySlip(payroll),
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                    ),
                  ),
                ],
              );
            },
          );

          if (compact) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                calculator,
                const SizedBox(height: 16),
                SizedBox(height: 320, child: records),
                const SizedBox(height: 16),
                SizedBox(height: 560, child: preview),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 360,
                child: SingleChildScrollView(child: calculator),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: records),
              const VerticalDivider(width: 1),
              SizedBox(width: 460, child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _CalculatorPanel extends StatelessWidget {
  const _CalculatorPanel({
    required this.formKey,
    required this.hoursController,
    required this.selectedEmployee,
    required this.onEmployeeChanged,
    required this.onCalculate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController hoursController;
  final EmployeeModel? selectedEmployee;
  final ValueChanged<EmployeeModel?> onEmployeeChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<EmployeeProvider>().employees;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Calculate pay',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EmployeeModel>(
                initialValue: selectedEmployee,
                items: employees
                    .map(
                      (employee) => DropdownMenuItem(
                        value: employee,
                        child: Text(employee.name),
                      ),
                    )
                    .toList(),
                onChanged: onEmployeeChanged,
                decoration: const InputDecoration(labelText: 'Employee'),
                validator: (value) =>
                    value == null ? 'Select an employee' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: hoursController,
                label: 'Hours worked',
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Calculate and save',
                icon: Icons.calculate_outlined,
                onPressed: onCalculate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
