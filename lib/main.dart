import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app_config.dart';
import 'app_router.dart';
import 'core/features/auth/providers/login_form_provider.dart';
import 'core/localization/localization_service.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_navigation_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/payroll_provider.dart';
import 'services/firebase_service.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PayrollDesktopApp());
}

class PayrollDesktopApp extends StatefulWidget {
  const PayrollDesktopApp({super.key});

  @override
  State<PayrollDesktopApp> createState() => _PayrollDesktopAppState();
}

class _PayrollDesktopAppState extends State<PayrollDesktopApp> {
  late final GoRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = createAppRouter();
  }

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
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: LightTheme.theme,
            darkTheme: DarkTheme.theme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            routerConfig: _appRouter,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
