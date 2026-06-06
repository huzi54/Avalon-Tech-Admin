import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_config.dart';
import 'firebase_options.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/payroll_provider.dart';
import 'screens/create_employee_screen.dart';
import 'screens/employee_info_screen.dart';
import 'screens/employee_punch_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/payroll_slips_screen.dart';
import 'screens/remittance_screen.dart';
import 'screens/salary_calculator_screen.dart';
import 'services/firebase_service.dart';
import 'themes/light_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PayrollDesktopApp());
}

class PayrollDesktopApp extends StatelessWidget {
  const PayrollDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    return MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
        ChangeNotifierProvider(
          create: (_) => EmployeeProvider(firebaseService),
        ),
        ChangeNotifierProvider(create: (_) => PayrollProvider(firebaseService)),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(firebaseService),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: LightTheme.theme,
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          OwnerDashboardScreen.routeName: (_) => const OwnerDashboardScreen(),
          EmployeePunchScreen.routeName: (_) => const EmployeePunchScreen(),
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
