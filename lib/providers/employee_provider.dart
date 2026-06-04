import 'package:flutter/foundation.dart';

import '../models/employee_model.dart';

class EmployeeProvider extends ChangeNotifier {
  EmployeeProvider([Object? unusedService]) {
    _employees.addAll(_starterEmployees);
  }

  final List<EmployeeModel> _employees = [];
  bool isLoading = false;

  List<EmployeeModel> get employees => List.unmodifiable(_employees);

  EmployeeModel? findById(String id) {
    try {
      return _employees.firstWhere((employee) => employee.id == id);
    } on StateError {
      return null;
    }
  }

  Future<void> loadEmployees() async {
    notifyListeners();
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    _employees.add(employee);
    notifyListeners();
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    final index = _employees.indexWhere((item) => item.id == employee.id);
    if (index == -1) return;
    _employees[index] = employee;
    notifyListeners();
  }

  Future<void> removeEmployee(String employeeId) async {
    _employees.removeWhere((employee) => employee.id == employeeId);
    notifyListeners();
  }

  static const List<EmployeeModel> _starterEmployees = [
    EmployeeModel(
      id: 'EMP-1001',
      name: 'Avery Morgan',
      email: 'avery.morgan@example.com',
      role: 'Tailor',
      hourlyRate: 24,
      defaultHours: 80,
      department: 'Production',
      phone: '709-555-0141',
    ),
    EmployeeModel(
      id: 'EMP-1002',
      name: 'Jamie Patel',
      email: 'jamie.patel@example.com',
      role: 'Supervisor',
      hourlyRate: 31.5,
      defaultHours: 78,
      department: 'Operations',
      phone: '709-555-0199',
    ),
    EmployeeModel(
      id: 'EMP-1003',
      name: 'Noor Williams',
      email: 'noor.williams@example.com',
      role: 'Technician',
      hourlyRate: 28.75,
      defaultHours: 75,
      department: 'Maintenance',
    ),
  ];
}
