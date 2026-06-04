import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/attendance_provider.dart';
import '../../utils/date_time_helper.dart';
import '../../widgets/custom_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _employeeIdController = TextEditingController(text: 'demo-employee');

  @override
  void dispose() {
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _employeeIdController,
                    decoration: const InputDecoration(labelText: 'Employee ID'),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'Load',
                  icon: Icons.refresh,
                  onPressed: () => context
                      .read<AttendanceProvider>()
                      .loadAttendance(_employeeIdController.text.trim()),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.records.isEmpty
                ? const Center(child: Text('No attendance records found.'))
                : ListView.separated(
                    itemCount: provider.records.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = provider.records[index];
                      return ListTile(
                        leading: Icon(
                          record.type == 'checkIn' ? Icons.login : Icons.logout,
                        ),
                        title: Text(record.employeeName),
                        subtitle: Text(
                          DateTimeHelper.formatDateTime(record.timestamp),
                        ),
                        trailing: Text(record.type),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
