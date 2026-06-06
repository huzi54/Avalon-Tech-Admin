import 'package:flutter/material.dart';

class AppConfig {
  const AppConfig._();

  static const String appName = 'Newfoundland Payroll Calculator 2026';
  static const String companyName = 'Avalon Tech & Tailor';
  static const String companyAddress =
      '31 Peet St Suite 105, St. John\'s, NL A1B 3W8, Canada';
  static const String logoPath = 'assets/images/logo.png';
  static const String defaultLanguage = 'en';
  static const String province = 'Newfoundland and Labrador';

  static const Color primaryColor = Color(0xFF155E63);
  static const Color accentColor = Color(0xFFC7822C);
  static const Color backgroundColor = Color(0xFFF4F7F6);
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF172124);
  static const Color mutedTextColor = Color(0xFF667085);
  static const Color borderColor = Color(0xFFD7E0DD);

  static const String employeesCollection = 'employees';
  static const String payrollsCollection = 'payrolls';
  static const String remittancesCollection = 'remittances';
  static const String attendanceCollection = 'attendance';
  static const String weeklyReportsCollection = 'weeklyReports';
  static const String usersCollection = 'users';
  static const String employeeDocumentsPath = 'employee_documents';
}
