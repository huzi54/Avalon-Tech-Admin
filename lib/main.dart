import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_config.dart';
import 'providers/employee_provider.dart';
import 'providers/payroll_provider.dart';
import 'screens/create_employee_screen.dart';
import 'screens/employee_info_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/payroll_slips_screen.dart';
import 'screens/remittance_screen.dart';
import 'screens/salary_calculator_screen.dart';
import 'themes/light_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PayrollDesktopApp());
}

class PayrollDesktopApp extends StatelessWidget {
  const PayrollDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => PayrollProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: LightTheme.theme,
        initialRoute: OwnerDashboardScreen.routeName,
        routes: {
          OwnerDashboardScreen.routeName: (_) => const OwnerDashboardScreen(),
          EmployeeInfoScreen.routeName: (_) => const EmployeeInfoScreen(),
          CreateEmployeeScreen.routeName: (_) => const CreateEmployeeScreen(),
          PayrollSlipsScreen.routeName: (_) => const PayrollSlipsScreen(),
          RemittanceScreen.routeName: (_) => const RemittanceScreen(),
          SalaryCalculatorScreen.routeName: (_) =>
              const SalaryCalculatorScreen(),
        },
      ),
    );
  }
}
