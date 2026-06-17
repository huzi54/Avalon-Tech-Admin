import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../core/localization/localization_service.dart';
import '../models/payroll_model.dart';
import '../models/remittance_model.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_navigation_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/payroll_provider.dart';
import '../utils/date_time_helper.dart';
import 'create_employee_screen.dart';
import 'employee_info_screen.dart';
import 'login_screen.dart';
import 'pay_slip_preview_screen.dart';
import 'payroll_slips_screen.dart';
import 'remittance_screen.dart';
import 'salary_calculator_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<DashboardNavigationProvider>();
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedSection: navigation.selectedSection,
            onSelected: navigation.select,
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
          Expanded(child: _buildMainContent(context, navigation)),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    DashboardNavigationProvider navigation,
  ) {
    return switch (navigation.selectedSection) {
      DashboardSection.dashboard => _DashboardHome(
        onSectionSelected: navigation.select,
      ),
      DashboardSection.employees => EmployeeInfoScreen(
        onCreateEmployee: () =>
            navigation.select(DashboardSection.createEmployee),
        onOpenAttendance: (employee) => navigation.openAttendance(employee.id),
      ),
      DashboardSection.createEmployee => CreateEmployeeScreen(
        onBack: () => navigation.select(DashboardSection.employees),
        onSaved: (_) => navigation.select(DashboardSection.employees),
      ),
      DashboardSection.attendance => _AttendanceContent(
        employeeId: navigation.attendanceEmployeeId,
        onBack: () => navigation.select(DashboardSection.employees),
      ),
      DashboardSection.calculator => const SalaryCalculatorScreen(),
      DashboardSection.payroll => const PayrollSlipsScreen(),
      DashboardSection.remittance => const RemittanceScreen(),
      DashboardSection.settings => const _SettingsContent(),
    };
  }
}

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent({required this.employeeId, required this.onBack});

  final String? employeeId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final employee = employeeId == null
        ? null
        : context.watch<EmployeeProvider>().findById(employeeId!);
    if (employee == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to employees',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Attendance Records'),
        ),
        body: const Center(child: Text('Employee record not found.')),
      );
    }

    return AttendanceRecordsScreen(employee: employee, onBack: onBack);
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({required this.onSectionSelected});

  final ValueChanged<DashboardSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmployeeProvider, PayrollProvider>(
      builder: (context, employeeProvider, payrollProvider, _) {
        final payrolls = [...payrollProvider.payrolls]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final remittances = [...payrollProvider.remittances]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final paid = payrolls
            .where((payroll) => payroll.slipStatus.toLowerCase() == 'paid')
            .toList();
        final unpaid = payrolls
            .where((payroll) => payroll.slipStatus.toLowerCase() != 'paid')
            .toList();
        final totalPayroll = payrolls.fold<double>(
          0,
          (sum, payroll) => sum + payroll.finalPayableAmount,
        );
        final unpaidPayroll = unpaid.fold<double>(
          0,
          (sum, payroll) => sum + payroll.finalPayableAmount,
        );
        final unpaidRemittance = remittances
            .where((remittance) => remittance.status.toLowerCase() != 'paid')
            .fold<double>(
              0,
              (sum, remittance) => sum + remittance.totalRemittance,
            );
        final totalRemittance = remittances.fold<double>(
          0,
          (sum, remittance) => sum + remittance.totalRemittance,
        );

        return Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                children: [
                  Text(
                    'Top Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          title: 'Employee',
                          subtitle: 'Add, view and manage employees',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF2563EB),
                          onTap: () => onSectionSelected(
                            DashboardSection.createEmployee,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionCard(
                          title: 'Payroll',
                          subtitle: 'Calculate, manage and view payrolls',
                          icon: Icons.calculate_rounded,
                          color: const Color(0xFF16A34A),
                          onTap: () =>
                              onSectionSelected(DashboardSection.calculator),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - (16 * 5)) / 6;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _SummaryTile(
                            width: width.clamp(150, 220).toDouble(),
                            label: 'Employees',
                            value: employeeProvider.employees.length.toString(),
                            icon: Icons.group_outlined,
                            color: const Color(0xFF2563EB),
                            onTap: () =>
                                onSectionSelected(DashboardSection.employees),
                          ),
                          _SummaryTile(
                            width: width.clamp(150, 220).toDouble(),
                            label: 'Total Payroll',
                            value: DateTimeHelper.currency(totalPayroll),
                            icon: Icons.attach_money,
                            color: const Color(0xFF16A34A),
                            onTap: () =>
                                onSectionSelected(DashboardSection.payroll),
                          ),
                          _SummaryTile(
                            width: width.clamp(150, 220).toDouble(),
                            label: 'Paid Slips',
                            value: paid.length.toString(),
                            icon: Icons.description_outlined,
                            color: const Color(0xFF9333EA),
                            onTap: () =>
                                onSectionSelected(DashboardSection.payroll),
                          ),
                          _SummaryTile(
                            width: width.clamp(150, 220).toDouble(),
                            label: 'Unpaid Payroll',
                            value: DateTimeHelper.currency(unpaidPayroll),
                            icon: Icons.pending_actions_outlined,
                            color: const Color(0xFFF97316),
                            onTap: () =>
                                onSectionSelected(DashboardSection.payroll),
                          ),
                          _SummaryTile(
                            width: width.clamp(150, 220).toDouble(),
                            label: 'Remittance',
                            value: DateTimeHelper.currency(totalRemittance),
                            icon: Icons.account_balance_outlined,
                            color: const Color(0xFF2563EB),
                            onTap: () =>
                                onSectionSelected(DashboardSection.remittance),
                          ),
                          _SummaryTile(
                            width: width.clamp(150, 220).toDouble(),
                            label: 'Unpaid Remittance',
                            value: DateTimeHelper.currency(unpaidRemittance),
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444),
                            onTap: () =>
                                onSectionSelected(DashboardSection.remittance),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _RemittancePanel(
                    remittances: remittances.take(5).toList(),
                    onViewAll: () =>
                        onSectionSelected(DashboardSection.remittance),
                  ),
                  const SizedBox(height: 22),
                  _PayrollPanel(
                    payrolls: payrolls.take(5).toList(),
                    onViewAll: () =>
                        onSectionSelected(DashboardSection.payroll),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            context.tr('appearance'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButtonFormField<ThemeMode>(
                    initialValue: settings.themeMode,
                    decoration: InputDecoration(
                      labelText: context.tr('theme'),
                      prefixIcon: const Icon(Icons.contrast_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(context.tr('light')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(context.tr('dark')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(context.tr('system')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) settings.setThemeMode(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: settings.locale.languageCode,
                    decoration: InputDecoration(
                      labelText: context.tr('language'),
                      prefixIcon: const Icon(Icons.language_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(context.tr('english')),
                      ),
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(context.tr('frenchCanada')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.setLocale(Locale(value, 'CA'));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('support'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: Text(context.tr('contactSupport')),
              subtitle: Text(
                '${context.tr('supportDescription')}\n${AppConfig.supportEmail}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(context.tr('subscription')),
              subtitle: Text(context.tr('subscriptionManagedByAdmin')),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  LoginScreen.routeName,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_outlined),
              label: Text(context.tr('logout')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedSection, required this.onSelected});

  final DashboardSection selectedSection;
  final ValueChanged<DashboardSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  AppConfig.logoPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConfig.companyName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConfig.companyAddress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.55,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 42),
            _NavItem(
              icon: Icons.home_outlined,
              label: context.tr('dashboard'),
              selected: selectedSection == DashboardSection.dashboard,
              onTap: () => onSelected(DashboardSection.dashboard),
            ),
            _NavItem(
              icon: Icons.people_alt_outlined,
              label: context.tr('employees'),
              selected:
                  selectedSection == DashboardSection.employees ||
                  selectedSection == DashboardSection.createEmployee ||
                  selectedSection == DashboardSection.attendance,
              onTap: () => onSelected(DashboardSection.employees),
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              label: context.tr('payroll'),
              selected:
                  selectedSection == DashboardSection.payroll ||
                  selectedSection == DashboardSection.calculator,
              onTap: () => onSelected(DashboardSection.payroll),
            ),
            _NavItem(
              icon: Icons.account_balance_outlined,
              label: context.tr('remittance'),
              selected: selectedSection == DashboardSection.remittance,
              onTap: () => onSelected(DashboardSection.remittance),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: context.tr('settings'),
              selected: selectedSection == DashboardSection.settings,
              onTap: () => onSelected(DashboardSection.settings),
            ),
            const Spacer(),
            Text(
              '© 2026 ${AppConfig.companyName}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            Text(
              'All rights reserved.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF334155),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome back! Here\'s what\'s happening with your business.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF2563EB),
            child: Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Owner',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.keyboard_arrow_down_rounded),
          const SizedBox(width: 18),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginScreen.routeName,
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      onTap: onTap,
      child: SizedBox(
        height: 118,
        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 34),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _Panel(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 152,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E2EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }
}

class _RemittancePanel extends StatelessWidget {
  const _RemittancePanel({required this.remittances, required this.onViewAll});

  final List<RemittanceModel> remittances;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _DataPanel(
      title: 'Recent Remittance Records',
      icon: Icons.account_balance_outlined,
      color: const Color(0xFF2563EB),
      viewAllLabel: 'View All',
      onViewAll: onViewAll,
      headers: const [
        'Employee Name',
        'Employee ID',
        'Created Date',
        'Total Remittance Amount',
        'Remittance Status',
        'Action',
      ],
      rows: remittances.isEmpty
          ? []
          : [
              for (final remittance in remittances)
                [
                  Text(remittance.employeeName),
                  Text(remittance.employeeId),
                  Text(DateTimeHelper.formatDate(remittance.createdAt)),
                  Text(DateTimeHelper.currency(remittance.totalRemittance)),
                  _StatusBadge(status: remittance.status),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: onViewAll,
                      child: const Text('View Remittance'),
                    ),
                  ),
                ],
            ],
      emptyText: 'No remittance records yet.',
    );
  }
}

class _PayrollPanel extends StatelessWidget {
  const _PayrollPanel({required this.payrolls, required this.onViewAll});

  final List<PayrollModel> payrolls;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _DataPanel(
      title: 'Recent Payroll Slips',
      icon: Icons.description_outlined,
      color: const Color(0xFF9333EA),
      viewAllLabel: 'View All',
      onViewAll: onViewAll,
      headers: const [
        'Employee Name',
        'Employee ID',
        'Created Date',
        'Final Payable Amount',
        'Slip Status',
        'Action',
      ],
      rows: payrolls.isEmpty
          ? []
          : [
              for (final payroll in payrolls)
                [
                  Text(payroll.employeeName),
                  Text(payroll.employeeId),
                  Text(DateTimeHelper.formatDate(payroll.createdAt)),
                  Text(DateTimeHelper.currency(payroll.finalPayableAmount)),
                  _StatusBadge(status: payroll.slipStatus),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<PayrollProvider>().preview(payroll);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PaySlipPreviewScreen(payrollId: payroll.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('PDF Preview'),
                    ),
                  ),
                ],
            ],
      emptyText: 'No payroll slips yet.',
    );
  }
}

class _DataPanel extends StatelessWidget {
  const _DataPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.viewAllLabel,
    required this.onViewAll,
    required this.headers,
    required this.rows,
    required this.emptyText,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String viewAllLabel;
  final VoidCallback onViewAll;
  final List<String> headers;
  final List<List<Widget>> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E2EF)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton(onPressed: onViewAll, child: Text(viewAllLabel)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (rows.isEmpty)
            SizedBox(height: 140, child: Center(child: Text(emptyText)))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(1.0),
                2: FlexColumnWidth(1.15),
                3: FlexColumnWidth(1.45),
                4: FlexColumnWidth(1.0),
                5: FlexColumnWidth(1.35),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  children: [
                    for (final header in headers)
                      _TableCell(
                        child: Text(
                          header,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [for (final cell in row) _TableCell(child: cell)],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status.toLowerCase() == 'paid';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: paid ? const Color(0xFFE3F8EC) : const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: paid ? const Color(0xFF0F8F45) : const Color(0xFFDC2626),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
