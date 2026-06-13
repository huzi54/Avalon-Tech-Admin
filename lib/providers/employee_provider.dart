import 'package:flutter/foundation.dart';

import '../models/employee_model.dart';
import '../models/weekly_work_report_model.dart';
import '../services/firebase_service.dart';

class EmployeeProvider extends ChangeNotifier {
  EmployeeProvider([FirebaseService? firebaseService])
    : _firebaseService = firebaseService ?? FirebaseService() {
    loadEmployees();
  }

  final FirebaseService _firebaseService;
  final List<EmployeeModel> _employees = [];
  final Map<String, List<WeeklyWorkReportModel>> _weeklyReports = {};
  bool isLoading = false;
  String? errorMessage;

  List<EmployeeModel> get employees => List.unmodifiable(_employees);

  List<WeeklyWorkReportModel> weeklyReportsFor(String employeeId) {
    final reports = [..._weeklyReports[employeeId] ?? const []]
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return List.unmodifiable(reports);
  }

  double attendanceHoursForPeriod({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final reports = _weeklyReports[employeeId];
    if (reports == null) return 0;

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final from = start.isBefore(end) ? start : end;
    final to = start.isBefore(end) ? end : start;
    var hours = 0.0;

    for (final report in reports) {
      for (var index = 0; index < report.entries.length; index++) {
        final entryDate = report.weekStart.add(Duration(days: index));
        final date = DateTime(entryDate.year, entryDate.month, entryDate.day);
        if (date.isBefore(from) || date.isAfter(to)) continue;
        hours += report.entries[index].workingHours;
      }
    }
    return hours;
  }

  DailyWorkEntry? dailyEntryForDate({
    required String employeeId,
    required DateTime date,
  }) {
    final weekStart = _startOfWeek(date);
    final reports = _weeklyReports[employeeId];
    if (reports == null) return null;

    final reportIndex = reports.indexWhere(
      (report) => _sameDate(report.weekStart, weekStart),
    );
    if (reportIndex == -1) return null;

    final entryIndex = date.weekday - DateTime.monday;
    if (entryIndex < 0 || entryIndex >= reports[reportIndex].entries.length) {
      return null;
    }
    return reports[reportIndex].entries[entryIndex];
  }

  bool hasCheckedInForDate({
    required String employeeId,
    required DateTime date,
  }) {
    return dailyEntryForDate(
          employeeId: employeeId,
          date: date,
        )?.checkInMinutes !=
        null;
  }

  EmployeeModel? findById(String id) {
    try {
      return _employees.firstWhere((employee) => employee.id == id);
    } on StateError {
      return null;
    }
  }

  Future<void> loadEmployees() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final employees = await _firebaseService.fetchEmployees();
      final reports = await _firebaseService.fetchWeeklyReports();
      _employees
        ..clear()
        ..addAll(employees);
      _weeklyReports
        ..clear()
        ..addEntries(_groupReports(reports).entries);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    await _run(() => _firebaseService.addEmployee(employee));
    _employees.add(employee);
    notifyListeners();
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    final index = _employees.indexWhere((item) => item.id == employee.id);
    if (index == -1) return;
    await _run(() => _firebaseService.updateEmployee(employee));
    _employees[index] = employee;
    notifyListeners();
  }

  Future<void> removeEmployee(String employeeId) async {
    await _run(() => _firebaseService.removeEmployee(employeeId));
    _employees.removeWhere((employee) => employee.id == employeeId);
    _weeklyReports.remove(employeeId);
    notifyListeners();
  }

  Future<void> addWeeklyReport(WeeklyWorkReportModel report) async {
    await _run(() => _firebaseService.saveWeeklyReport(report));
    final reports = _weeklyReports.putIfAbsent(report.employeeId, () => []);
    reports.insert(0, report);
    notifyListeners();
  }

  Future<void> updateWeeklyReport(WeeklyWorkReportModel report) async {
    final reports = _weeklyReports[report.employeeId];
    if (reports == null) return;

    final index = reports.indexWhere((item) => item.id == report.id);
    if (index == -1) return;

    await _run(() => _firebaseService.saveWeeklyReport(report));
    reports[index] = report;
    notifyListeners();
  }

  Future<bool> recordDailyPunch({
    required String employeeId,
    required DateTime dateTime,
    required bool isCheckIn,
    String? attendanceNote,
  }) async {
    if (isCheckIn &&
        hasCheckedInForDate(employeeId: employeeId, date: dateTime)) {
      return false;
    }

    final weekStart = _startOfWeek(dateTime);
    final reports = _weeklyReports.putIfAbsent(employeeId, () => []);
    var reportIndex = reports.indexWhere(
      (report) => _sameDate(report.weekStart, weekStart),
    );

    if (reportIndex == -1) {
      reports.insert(
        0,
        WeeklyWorkReportModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          employeeId: employeeId,
          weekStart: weekStart,
          entries: _emptyEntries(),
          createdAt: DateTime.now(),
        ),
      );
      reportIndex = 0;
    }

    final report = reports[reportIndex];
    final entries = [...report.entries];
    final entryIndex = dateTime.weekday - DateTime.monday;
    final minutes = (dateTime.hour * 60) + dateTime.minute;
    final original = entries[entryIndex];
    final note = attendanceNote?.trim();

    entries[entryIndex] = DailyWorkEntry(
      dayName: original.dayName,
      checkInMinutes: isCheckIn ? minutes : original.checkInMinutes,
      checkOutMinutes: isCheckIn ? original.checkOutMinutes : minutes,
      attendanceNote: note == null || note.isEmpty
          ? original.attendanceNote
          : note,
    );

    final updated = report.copyWith(entries: entries);
    await _run(() => _firebaseService.saveWeeklyReport(updated));
    reports[reportIndex] = updated;
    notifyListeners();
    return true;
  }

  Map<String, List<WeeklyWorkReportModel>> _groupReports(
    List<WeeklyWorkReportModel> reports,
  ) {
    final grouped = <String, List<WeeklyWorkReportModel>>{};
    for (final report in reports) {
      grouped.putIfAbsent(report.employeeId, () => []).add(report);
    }
    return grouped;
  }

  Future<void> _run(Future<void> Function() action) async {
    errorMessage = null;
    try {
      await action();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  static List<DailyWorkEntry> _emptyEntries() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return [for (final day in days) DailyWorkEntry(dayName: day)];
  }

  static DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  static bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
