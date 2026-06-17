import 'package:flutter/foundation.dart';

enum DashboardSection {
  dashboard,
  employees,
  createEmployee,
  attendance,
  calculator,
  payroll,
  remittance,
  settings,
}

class DashboardNavigationProvider extends ChangeNotifier {
  DashboardSection _selectedSection = DashboardSection.dashboard;
  String? _attendanceEmployeeId;

  DashboardSection get selectedSection => _selectedSection;
  String? get attendanceEmployeeId => _attendanceEmployeeId;

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
}
