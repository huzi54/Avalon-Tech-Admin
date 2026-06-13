import 'package:flutter/foundation.dart';

enum DashboardSection {
  dashboard,
  employees,
  createEmployee,
  calculator,
  payroll,
  remittance,
  settings,
}

class DashboardNavigationProvider extends ChangeNotifier {
  DashboardSection _selectedSection = DashboardSection.dashboard;

  DashboardSection get selectedSection => _selectedSection;

  void select(DashboardSection section) {
    if (_selectedSection == section) return;
    _selectedSection = section;
    notifyListeners();
  }
}
