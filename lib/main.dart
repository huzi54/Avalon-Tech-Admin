import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_config.dart';
import 'core/features/auth/providers/login_form_provider.dart';
import 'core/localization/localization_service.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_navigation_provider.dart';
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
import 'themes/dark_theme.dart';
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
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
        ChangeNotifierProvider(create: (_) => LoginFormProvider()),
        ChangeNotifierProvider(create: (_) => DashboardNavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => EmployeeProvider(firebaseService),
        ),
        ChangeNotifierProvider(create: (_) => PayrollProvider(firebaseService)),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(firebaseService),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: LightTheme.theme,
            darkTheme: DarkTheme.theme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: LoginScreen.routeName,
            routes: {
              LoginScreen.routeName: (_) => const LoginScreen(),
              OwnerDashboardScreen.routeName: (_) =>
                  const OwnerDashboardScreen(),
              EmployeePunchScreen.routeName: (_) => const EmployeePunchScreen(),
              EmployeeInfoScreen.routeName: (_) => const EmployeeInfoScreen(),
              CreateEmployeeScreen.routeName: (_) =>
                  const CreateEmployeeScreen(),
              PayrollSlipsScreen.routeName: (_) => const PayrollSlipsScreen(),
              RemittanceScreen.routeName: (_) => const RemittanceScreen(),
              SalaryCalculatorScreen.routeName: (_) =>
                  const SalaryCalculatorScreen(),
            },
          );
        },
      ),
    );
  }
}
