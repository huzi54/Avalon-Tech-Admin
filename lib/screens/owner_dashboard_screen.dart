import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payroll_model.dart';
import '../providers/employee_provider.dart';
import '../providers/payroll_provider.dart';
import '../utils/date_time_helper.dart';
import '../utils/responsive.dart';
import 'create_employee_screen.dart';
import 'employee_info_screen.dart';
import 'pay_slip_preview_screen.dart';
import 'payroll_slips_screen.dart';
import 'remittance_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, CreateEmployeeScreen.routeName),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Employee'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, EmployeeInfoScreen.routeName),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Payroll'),
            ),
          ),
        ],
      ),
      body: Consumer2<EmployeeProvider, PayrollProvider>(
        builder: (context, employeeProvider, payrollProvider, _) {
          final payrolls = payrollProvider.payrolls;
          final paid = payrolls
              .where((payroll) => payroll.slipStatus.toLowerCase() == 'paid')
              .toList();
          final unpaid = payrolls
              .where((payroll) => payroll.slipStatus.toLowerCase() != 'paid')
              .toList();
          final totalPayable = payrolls.fold<double>(
            0,
            (sum, payroll) => sum + payroll.finalPayableAmount,
          );
          final unpaidPayable = unpaid.fold<double>(
            0,
            (sum, payroll) => sum + payroll.finalPayableAmount,
          );
          final remittances = payrollProvider.remittances;
          final paidRemittances = remittances
              .where((remittance) => remittance.status.toLowerCase() == 'paid')
              .toList();
          final unpaidRemittances = remittances
              .where((remittance) => remittance.status.toLowerCase() != 'paid')
              .toList();
          final totalRemittance = remittances.fold<double>(
            0,
            (sum, remittance) => sum + remittance.totalRemittance,
          );
          final unpaidRemittance = unpaidRemittances.fold<double>(
            0,
            (sum, remittance) => sum + remittance.totalRemittance,
          );

          final recent = [...payrolls]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final recentRemittances = [...remittances]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView(
            padding: EdgeInsets.all(padding),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    title: 'Employees',
                    value: employeeProvider.employees.length.toString(),
                    icon: Icons.groups_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      EmployeeInfoScreen.routeName,
                    ),
                  ),
                  _SummaryCard(
                    title: 'Total Payroll',
                    value: DateTimeHelper.currency(totalPayable),
                    caption: '${payrolls.length} slips',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      PayrollSlipsScreen.routeName,
                    ),
                  ),
                  _SummaryCard(
                    title: 'Paid Slips',
                    value: paid.length.toString(),
                    icon: Icons.verified_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      PayrollSlipsScreen.routeName,
                      arguments: const PayrollSlipsArgs(statusFilter: 'Paid'),
                    ),
                  ),
                  _SummaryCard(
                    title: 'Unpaid Payroll',
                    value: DateTimeHelper.currency(unpaidPayable),
                    caption: '${unpaid.length} slips',
                    icon: Icons.pending_actions_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      PayrollSlipsScreen.routeName,
                      arguments: const PayrollSlipsArgs(statusFilter: 'Unpaid'),
                    ),
                  ),
                  _SummaryCard(
                    title: 'Remittance',
                    value: DateTimeHelper.currency(totalRemittance),
                    caption: '${remittances.length} records',
                    icon: Icons.account_balance_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RemittanceScreen.routeName,
                    ),
                  ),
                  _SummaryCard(
                    title: 'Unpaid Remittance',
                    value: DateTimeHelper.currency(unpaidRemittance),
                    caption:
                        '${paidRemittances.length} paid, ${unpaidRemittances.length} unpaid',
                    icon: Icons.receipt_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RemittanceScreen.routeName,
                      arguments: const RemittanceArgs(statusFilter: 'Unpaid'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remittance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RemittanceScreen.routeName,
                    ),
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: const Text('View Remittance'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: recentRemittances.isEmpty
                    ? const SizedBox(
                        height: 120,
                        child: Center(
                          child: Text('No remittance records yet.'),
                        ),
                      )
                    : Column(
                        children: [
                          for (final remittance in recentRemittances.take(4))
                            ListTile(
                              leading: const Icon(
                                Icons.account_balance_outlined,
                              ),
                              title: Text(remittance.employeeName),
                              subtitle: Text(
                                '${remittance.employeeId} - '
                                '${DateTimeHelper.formatDate(remittance.createdAt)}',
                              ),
                              trailing: Wrap(
                                spacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    DateTimeHelper.currency(
                                      remittance.totalRemittance,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(remittance.status),
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Payroll Slips',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      PayrollSlipsScreen.routeName,
                    ),
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: recent.isEmpty
                    ? const SizedBox(
                        height: 180,
                        child: Center(child: Text('No payroll slips yet.')),
                      )
                    : Column(
                        children: [
                          for (final payroll in recent.take(6))
                            _RecentPayrollTile(payroll: payroll),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    this.caption,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                if (caption != null) ...[
                  const SizedBox(height: 4),
                  Text(caption!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentPayrollTile extends StatelessWidget {
  const _RecentPayrollTile({required this.payroll});

  final PayrollModel payroll;

  @override
  Widget build(BuildContext context) {
    final statusColor = payroll.slipStatus.toLowerCase() == 'paid'
        ? Colors.green
        : Colors.orange;

    return ListTile(
      leading: Icon(Icons.payments_outlined, color: statusColor),
      title: Text(payroll.employeeName),
      subtitle: Text(
        '${payroll.employeeId} • ${DateTimeHelper.formatDate(payroll.createdAt)}',
      ),
      trailing: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(DateTimeHelper.currency(payroll.finalPayableAmount)),
          Chip(
            label: Text(payroll.slipStatus),
            side: BorderSide.none,
            backgroundColor: statusColor.withValues(alpha: 0.12),
          ),
          IconButton(
            tooltip: 'View pay slip',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              context.read<PayrollProvider>().preview(payroll);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PaySlipPreviewScreen(payrollId: payroll.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
