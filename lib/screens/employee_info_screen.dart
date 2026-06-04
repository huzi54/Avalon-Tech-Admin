import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee_model.dart';
import '../providers/employee_provider.dart';
import '../utils/responsive.dart';
import '../widgets/custom_dropdown.dart';
import 'create_employee_screen.dart';
import 'salary_calculator_screen.dart';

class EmployeeInfoScreen extends StatefulWidget {
  const EmployeeInfoScreen({super.key});

  static const routeName = '/employee-info';

  @override
  State<EmployeeInfoScreen> createState() => _EmployeeInfoScreenState();
}

class _EmployeeInfoScreenState extends State<EmployeeInfoScreen> {
  final _idController = TextEditingController();
  final _designationController = TextEditingController();
  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();

  EmployeeModel? _selectedEmployee;

  @override
  void dispose() {
    _idController.dispose();
    _designationController.dispose();
    _hoursController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _selectEmployee(EmployeeModel? employee) {
    setState(() {
      _selectedEmployee = employee;
      _idController.text = employee?.id ?? '';
      _designationController.text = employee?.role ?? '';
      _hoursController.text = employee?.defaultHours.toStringAsFixed(2) ?? '';
      _rateController.text = employee?.hourlyRate.toStringAsFixed(2) ?? '';
    });
  }

  void _openCalculator() {
    final employee = _selectedEmployee;
    if (employee == null) return;

    Navigator.pushNamed(
      context,
      SalaryCalculatorScreen.routeName,
      arguments: SalaryCalculatorArgs(
        employeeId: employee.id,
        hours: double.tryParse(_hoursController.text) ?? employee.defaultHours,
      ),
    );
  }

  Future<void> _openCreateEmployee() async {
    final employeeId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const CreateEmployeeScreen()),
    );
    if (!mounted || employeeId == null) return;

    final employee = context.read<EmployeeProvider>().findById(employeeId);
    if (employee != null) {
      _selectEmployee(employee);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Information'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _openCreateEmployee,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Create Employee'),
            ),
          ),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          _selectedEmployee ??= provider.employees.firstOrNull;
          if (_selectedEmployee != null && _idController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _selectEmployee(_selectedEmployee),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Responsive(
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildForm(provider.employees)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildEmployeeList(provider.employees)),
                    ],
                  ),
                  compact: ListView(
                    children: [
                      _buildForm(provider.employees),
                      const SizedBox(height: 20),
                      _buildEmployeeList(provider.employees),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(List<EmployeeModel> employees) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payroll Setup',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            CustomDropdown<EmployeeModel>(
              label: 'Employee Name',
              value: _selectedEmployee,
              items: employees,
              itemLabel: (employee) => employee.name,
              onChanged: _selectEmployee,
            ),
            const SizedBox(height: 16),
            // Wrap(
            //   spacing: 16,
            //   runSpacing: 16,
            //   children: [
            //     _field(_idController, 'Employee ID'),
            //     _field(_designationController, 'Designation'),
            //     _field(_hoursController, 'Working Hours'),
            //     _field(_rateController, 'Hourly Rate', prefixText: r'$'),
            //   ],
            // ),
            // const SizedBox(height: 24),
            // OutlinedButton.icon(
            //   onPressed: _openCreateEmployee,
            //   icon: const Icon(Icons.person_add_alt_1_outlined),
            //   label: const Text('Create Employee Profile'),
            // ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selectedEmployee == null ? null : _openCalculator,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Open Salary Calculator'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList(List<EmployeeModel> employees) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Employees', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final employee in employees)
              ListTile(
                selected: employee.id == _selectedEmployee?.id,
                leading: const Icon(Icons.badge_outlined),
                title: Text(employee.name),
                subtitle: Text(
                  '${employee.role} - ${employee.department ?? ''}',
                ),
                trailing: Text(
                  r'$'
                  '${employee.hourlyRate.toStringAsFixed(2)}',
                ),
                onTap: () => _selectEmployee(employee),
              ),
          ],
        ),
      ),
    );
  }
}
