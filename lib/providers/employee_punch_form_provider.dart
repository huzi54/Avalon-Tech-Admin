import 'package:flutter/foundation.dart';

import '../models/employee_model.dart';

class EmployeePunchFormProvider extends ChangeNotifier {
  EmployeeModel? _selectedEmployee;

  EmployeeModel? get selectedEmployee => _selectedEmployee;

  void selectEmployee(EmployeeModel? employee) {
    if (_selectedEmployee?.id == employee?.id) return;
    _selectedEmployee = employee;
    notifyListeners();
  }

  EmployeeModel? selectedOrFirst(List<EmployeeModel> employees) {
    if (_selectedEmployee != null) return _selectedEmployee;
    return employees.firstOrNull;
  }
}
