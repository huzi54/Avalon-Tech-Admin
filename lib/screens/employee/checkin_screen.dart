import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_router.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/date_time_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _idController = TextEditingController(text: 'demo-employee');
  final _nameController = TextEditingController(text: 'Demo Employee');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _mark(String type) async {
    await context.read<AttendanceProvider>().mark(
      employeeId: _idController.text.trim(),
      employeeName: _nameController.text.trim(),
      type: type,
      note: _noteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Attendance'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.attendanceHistory),
            icon: const Icon(Icons.history),
            label: const Text('History'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    DateTimeHelper.formatDateTime(now),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _idController,
                    label: 'Employee ID',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _nameController, label: 'Name'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _noteController,
                    label: 'Manual note',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      CustomButton(
                        label: 'Check in',
                        icon: Icons.login,
                        onPressed: () => _mark('checkIn'),
                      ),
                      CustomButton(
                        label: 'Check out',
                        icon: Icons.logout,
                        onPressed: () => _mark('checkOut'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Consumer<AttendanceProvider>(
                    builder: (context, provider, _) {
                      final latest = provider.records.isEmpty
                          ? null
                          : provider.records.first;
                      return Text(
                        latest == null
                            ? 'No attendance saved this session.'
                            : 'Last ${latest.type}: '
                                  '${DateTimeHelper.formatDateTime(latest.timestamp)}',
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
