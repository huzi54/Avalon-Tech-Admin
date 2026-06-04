import 'package:flutter/material.dart';

import '../models/employee_model.dart';
import '../utils/date_time_helper.dart';

class EmployeeCard extends StatelessWidget {
  const EmployeeCard({
    required this.employee,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final EmployeeModel employee;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(employee.name.characters.firstOrNull ?? '?'),
        ),
        title: Text(employee.name),
        subtitle: Text(
          '${employee.email} • ${employee.department ?? 'General'} • '
          '${DateTimeHelper.currency(employee.hourlyRate)}/hr',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
