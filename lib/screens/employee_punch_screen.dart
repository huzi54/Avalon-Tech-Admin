import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee_model.dart';
import '../providers/auth_provider.dart';
import '../providers/employee_provider.dart';
import '../utils/date_time_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import 'login_screen.dart';

class EmployeePunchScreen extends StatefulWidget {
  const EmployeePunchScreen({super.key});

  static const routeName = '/employee-punch';

  @override
  State<EmployeePunchScreen> createState() => _EmployeePunchScreenState();
}

class _EmployeePunchScreenState extends State<EmployeePunchScreen> {
  EmployeeModel? _selectedEmployee;
  final _attendanceNoteController = TextEditingController();

  @override
  void dispose() {
    _attendanceNoteController.dispose();
    super.dispose();
  }

  Future<void> _recordPunch({required bool isCheckIn}) async {
    final employee = _selectedEmployee;
    if (employee == null) return;

    final now = DateTime.now();
    final saved = await context.read<EmployeeProvider>().recordDailyPunch(
      employeeId: employee.id,
      dateTime: now,
      isCheckIn: isCheckIn,
      attendanceNote: _attendanceNoteController.text,
    );

    if (!saved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are already checked in for today. You can check in again after 12:00 AM.',
          ),
        ),
      );
      return;
    }

    _attendanceNoteController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${isCheckIn ? 'Check in' : 'Check out'} saved at '
          '${DateTimeHelper.formatDateTime(now)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Employee Check In / Check Out'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            },
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          _selectedEmployee ??= provider.employees.firstOrNull;
          final selectedEmployee = _selectedEmployee;
          final hasCheckedInToday =
              selectedEmployee != null &&
              provider.hasCheckedInForDate(
                employeeId: selectedEmployee.id,
                date: DateTime.now(),
              );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Today Attendance',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(DateTimeHelper.formatDateTime(DateTime.now())),
                      const SizedBox(height: 22),
                      CustomDropdown<EmployeeModel>(
                        label: 'Employee',
                        value: _selectedEmployee,
                        items: provider.employees,
                        itemLabel: (employee) =>
                            '${employee.name} (${employee.id})',
                        onChanged: (employee) {
                          setState(() => _selectedEmployee = employee);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _attendanceNoteController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Attendance Note',
                          hintText:
                              'Optional note for today, e.g. late arrival or approved leave',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _selectedEmployee == null || hasCheckedInToday
                                  ? null
                                  : () => _recordPunch(isCheckIn: true),
                              icon: const Icon(Icons.login_outlined),
                              label: Text(
                                hasCheckedInToday
                                    ? 'Checked In Today'
                                    : 'Check In',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectedEmployee == null
                                  ? null
                                  : () => _recordPunch(isCheckIn: false),
                              icon: const Icon(Icons.logout_outlined),
                              label: const Text('Check Out'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        label: 'Back',
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          LoginScreen.routeName,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFEAF2FF)),
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'Note: For now, employees can only check in or check out here. Your report is not visible on this screen. The owner can view and update attendance reports in the Employee Info section.',
                          ),
                        ),
                      ),
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
}
