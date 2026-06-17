import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/auth/register_screen.dart';
import 'screens/create_employee_screen.dart';
import 'screens/employee/history_screen.dart';
import 'screens/employee_info_screen.dart';
import 'screens/employee_punch_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/pay_slip_preview_screen.dart';
import 'screens/payroll_slips_screen.dart';
import 'screens/remittance_preview_screen.dart';
import 'screens/remittance_screen.dart';
import 'screens/salary_calculator_screen.dart';
import 'providers/employee_provider.dart';

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const dashboard = '/';
  static const employeePunch = '/employee-punch';
  static const employeeInfo = '/employee-info';
  static const createEmployee = '/create-employee';
  static const payrollSlips = '/payroll-slips';
  static const remittances = '/remittances';
  static const salaryCalculator = '/salary-calculator';
  static const register = '/register';
  static const attendanceHistory = '/history';

  static String attendanceRecord(String employeeId) =>
      '/employees/$employeeId/attendance';

  static String paySlipPreview(String payrollId) => '/pay-slips/$payrollId';

  static String remittancePreview(String remittanceId) =>
      '/remittances/$remittanceId';
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _page(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) =>
            _page(state, const OwnerDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.employeePunch,
        pageBuilder: (context, state) =>
            _page(state, const EmployeePunchScreen()),
      ),
      GoRoute(
        path: AppRoutes.employeeInfo,
        pageBuilder: (context, state) =>
            _page(state, const EmployeeInfoScreen()),
      ),
      GoRoute(
        path: '/employees/:employeeId/attendance',
        pageBuilder: (context, state) {
          final employeeId = state.pathParameters['employeeId'] ?? '';
          final employee = context.read<EmployeeProvider>().findById(
            employeeId,
          );
          return _page(
            state,
            employee == null
                ? const _MissingRouteRecord(title: 'Employee record not found.')
                : AttendanceRecordsScreen(employee: employee),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createEmployee,
        pageBuilder: (context, state) =>
            _page(state, const CreateEmployeeScreen()),
      ),
      GoRoute(
        path: AppRoutes.payrollSlips,
        pageBuilder: (context, state) =>
            _page(state, const PayrollSlipsScreen()),
      ),
      GoRoute(
        path: AppRoutes.remittances,
        pageBuilder: (context, state) => _page(state, const RemittanceScreen()),
      ),
      GoRoute(
        path: AppRoutes.salaryCalculator,
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _page(
            state,
            SalaryCalculatorScreen(
              initialArgs: extra is SalaryCalculatorArgs ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/pay-slips/:payrollId',
        pageBuilder: (context, state) => _page(
          state,
          PaySlipPreviewScreen(
            payrollId: state.pathParameters['payrollId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/remittances/:remittanceId',
        pageBuilder: (context, state) => _page(
          state,
          RemittancePreviewScreen(
            remittanceId: state.pathParameters['remittanceId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _page(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.attendanceHistory,
        pageBuilder: (context, state) => _page(state, const HistoryScreen()),
      ),
    ],
  );
}

Page<void> _page(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

class _MissingRouteRecord extends StatelessWidget {
  const _MissingRouteRecord({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}
