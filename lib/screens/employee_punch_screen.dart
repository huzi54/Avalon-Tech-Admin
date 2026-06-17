import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../models/employee_model.dart';
import '../providers/auth_provider.dart';
import '../providers/employee_punch_form_provider.dart';
import '../providers/employee_provider.dart';
import '../utils/date_time_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';

class EmployeePunchScreen extends StatefulWidget {
  const EmployeePunchScreen({super.key});

  static const routeName = '/employee-punch';

  @override
  State<EmployeePunchScreen> createState() => _EmployeePunchScreenState();
}

class _EmployeePunchScreenState extends State<EmployeePunchScreen> {
  final _attendanceNoteController = TextEditingController();

  @override
  void dispose() {
    _attendanceNoteController.dispose();
    super.dispose();
  }

  Future<void> _recordPunch({required bool isCheckIn}) async {
    final employeeProvider = context.read<EmployeeProvider>();
    final employee = context.read<EmployeePunchFormProvider>().selectedOrFirst(
      employeeProvider.employees,
    );
    if (employee == null) return;

    final now = DateTime.now();
    final saved = await employeeProvider.recordDailyPunch(
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
    return ChangeNotifierProvider(
      create: (_) => EmployeePunchFormProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          title: const Text('Employee Check In / Check Out'),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Logout'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Consumer2<EmployeeProvider, EmployeePunchFormProvider>(
          builder: (context, provider, formProvider, _) {
            final selectedEmployee = formProvider.selectedOrFirst(
              provider.employees,
            );
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
                          value: selectedEmployee,
                          items: provider.employees,
                          itemLabel: (employee) =>
                              '${employee.name} (${employee.id})',
                          onChanged: formProvider.selectEmployee,
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
                                    selectedEmployee == null ||
                                        hasCheckedInToday
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
                                onPressed: selectedEmployee == null
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
                          onPressed: () => context.go(AppRoutes.login),
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
      ),
    );
  }
}
