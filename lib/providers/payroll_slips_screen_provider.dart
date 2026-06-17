import 'package:flutter/foundation.dart';

import '../models/payroll_model.dart';
import '../utils/record_date_sort.dart';

class PayrollSlipsScreenProvider extends ChangeNotifier {
  String _query = '';
  String _statusFilter = 'All';
  String _dateFilter = 'All';
  RecordDateSort _dateSort = RecordDateSort.oldestFirst;

  String get query => _query;
  String get statusFilter => _statusFilter;
  String get dateFilter => _dateFilter;
  RecordDateSort get dateSort => _dateSort;

  void applyInitialStatus(String? status) {
    if (status == null || _statusFilter == status) return;
    _statusFilter = status;
    notifyListeners();
  }

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void updateStatus(String value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
  }

  void updateDateFilter(String value) {
    if (_dateFilter == value) return;
    _dateFilter = value;
    notifyListeners();
  }

  void updateDateSort(RecordDateSort value) {
    if (_dateSort == value) return;
    _dateSort = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = 'All';
    _dateFilter = 'All';
    _dateSort = RecordDateSort.oldestFirst;
    notifyListeners();
  }

  List<PayrollModel> filtered(List<PayrollModel> payrolls) {
    final normalizedQuery = _query.trim().toLowerCase();
    final now = DateTime.now();

    final filtered = payrolls.where((payroll) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          payroll.employeeName.toLowerCase().contains(normalizedQuery) ||
          payroll.employeeId.toLowerCase().contains(normalizedQuery);

      final matchesStatus =
          _statusFilter == 'All' ||
          payroll.slipStatus.toLowerCase() == _statusFilter.toLowerCase();

      final created = payroll.createdAt;
      final matchesDate = switch (_dateFilter) {
        'Today' =>
          created.year == now.year &&
              created.month == now.month &&
              created.day == now.day,
        'Last 7 Days' => created.isAfter(now.subtract(const Duration(days: 7))),
        'Last 30 Days' => created.isAfter(
          now.subtract(const Duration(days: 30)),
        ),
        'This Month' => created.year == now.year && created.month == now.month,
        _ => true,
      };

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();

    return sortRecordsByDate(
      records: filtered,
      dateOf: (payroll) => payroll.createdAt,
      order: _dateSort,
    );
  }
}
