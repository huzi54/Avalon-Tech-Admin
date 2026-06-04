import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/employee_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rateController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rateController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    final employee = EmployeeModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: 'Employee',
      hourlyRate: double.parse(_rateController.text),
      department: _departmentController.text.trim(),
    );
    await context.read<EmployeeProvider>().addEmployee(employee);
    _nameController.clear();
    _emailController.clear();
    _rateController.clear();
    _departmentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/payroll'),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Payroll'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final form = _EmployeeForm(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            rateController: _rateController,
            departmentController: _departmentController,
            onSubmit: _addEmployee,
          );
          final list = Consumer<EmployeeProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Employees',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final employee in provider.employees)
                    EmployeeCard(
                      employee: employee,
                      onDelete: () => provider.removeEmployee(employee.id),
                    ),
                ],
              );
            },
          );

          if (compact) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                form,
                const SizedBox(height: 16),
                SizedBox(height: 520, child: list),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 380, child: SingleChildScrollView(child: form)),
              const VerticalDivider(width: 1),
              Expanded(child: list),
            ],
          );
        },
      ),
    );
  }
}

class _EmployeeForm extends StatelessWidget {
  const _EmployeeForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.rateController,
    required this.departmentController,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController rateController;
  final TextEditingController departmentController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
                'Add employee',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: nameController,
                label: 'Name',
                validator: Validators.requiredText,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: emailController,
                label: 'Email',
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: rateController,
                label: 'Hourly rate',
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: departmentController,
                label: 'Department',
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Save employee',
                icon: Icons.save_outlined,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
