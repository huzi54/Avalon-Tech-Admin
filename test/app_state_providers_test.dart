import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_payroll_app/core/features/auth/providers/login_form_provider.dart';
import 'package:flutter_payroll_app/providers/app_settings_provider.dart';
import 'package:flutter_payroll_app/providers/dashboard_navigation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads Canadian English and light theme by default', () async {
      final provider = AppSettingsProvider();

      await provider.load();

      expect(provider.isLoaded, isTrue);
      expect(provider.locale, const Locale('en', 'CA'));
      expect(provider.themeMode, ThemeMode.light);
    });

    test('persists Canadian French and dark theme', () async {
      final provider = AppSettingsProvider();
      await provider.load();

      await provider.setLocale(const Locale('fr', 'CA'));
      await provider.setThemeMode(ThemeMode.dark);

      final restored = AppSettingsProvider();
      await restored.load();
      expect(restored.locale, const Locale('fr', 'CA'));
      expect(restored.themeMode, ThemeMode.dark);
    });
  });

  test('DashboardNavigationProvider changes the visible section', () {
    final provider = DashboardNavigationProvider();

    provider.select(DashboardSection.remittance);

    expect(provider.selectedSection, DashboardSection.remittance);
  });

  test('LoginFormProvider toggles registration mode', () {
    final provider = LoginFormProvider();

    provider.toggleRegisterMode();

    expect(provider.registerMode, isTrue);
  });
}
