import 'package:flutter/foundation.dart';

enum DashboardSection {
  dashboard,
  employees,
  createEmployee,
  records,
  attendance,
  calculator,
  payroll,
  payrollPreview,
  remittance,
  settings,
}

class DashboardNavigationProvider extends ChangeNotifier {
  DashboardSection _selectedSection = DashboardSection.dashboard;
  String? _attendanceEmployeeId;
  String? _payrollPreviewId;
  String? _calculatorEmployeeId;
  String? _calculatorPayrollId;

  DashboardSection get selectedSection => _selectedSection;
  String? get attendanceEmployeeId => _attendanceEmployeeId;
  String? get payrollPreviewId => _payrollPreviewId;
  String? get calculatorEmployeeId => _calculatorEmployeeId;
  String? get calculatorPayrollId => _calculatorPayrollId;

  void select(DashboardSection section) {
    if (_selectedSection == section) return;
    _selectedSection = section;
    notifyListeners();
  }

  void openAttendance(String employeeId) {
    _attendanceEmployeeId = employeeId;
    _selectedSection = DashboardSection.attendance;
    notifyListeners();
  }

  void openPayrollPreview(String payrollId) {
    _payrollPreviewId = payrollId;
    _selectedSection = DashboardSection.payrollPreview;
    notifyListeners();
  }

  void openCalculator({String? employeeId, String? payrollId}) {
    _calculatorEmployeeId = employeeId;
    _calculatorPayrollId = payrollId;
    _selectedSection = DashboardSection.calculator;
    notifyListeners();
  }
}
