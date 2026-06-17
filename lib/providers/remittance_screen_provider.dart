import 'package:flutter/foundation.dart';

import '../models/remittance_model.dart';
import '../utils/remittance_filter.dart';
import '../utils/record_date_sort.dart';

class RemittanceScreenProvider extends ChangeNotifier {
  String _query = '';
  String _statusFilter = 'All';
  RecordDateSort _dateSort = RecordDateSort.oldestFirst;
  DateTime? _fromDate;
  DateTime? _toDate;
  final Set<String> _selectedIds = {};

  String get query => _query;
  String get statusFilter => _statusFilter;
  RecordDateSort get dateSort => _dateSort;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

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
    _selectedIds.clear();
    notifyListeners();
  }

  void updateDateSort(RecordDateSort value) {
    if (_dateSort == value) return;
    _dateSort = value;
    notifyListeners();
  }

  void updateDate({required bool isFrom, required DateTime date}) {
    if (isFrom) {
      _fromDate = date;
      if (_toDate != null && _toDate!.isBefore(date)) _toDate = date;
    } else {
      _toDate = date;
      if (_fromDate != null && _fromDate!.isAfter(date)) _fromDate = date;
    }
    _selectedIds.clear();
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = 'All';
    _fromDate = null;
    _toDate = null;
    _dateSort = RecordDateSort.oldestFirst;
    _selectedIds.clear();
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  void updateSelection(String id, bool isSelected) {
    if (isSelected) {
      _selectedIds.add(id);
    } else {
      _selectedIds.remove(id);
    }
    notifyListeners();
  }

  List<RemittanceModel> filtered(List<RemittanceModel> records) {
    final filtered = RemittanceFilter.apply(
      records: records,
      query: _query,
      status: _statusFilter,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    return sortRecordsByDate(
      records: filtered,
      dateOf: (record) => record.payPeriodStart,
      order: _dateSort,
    );
  }
}
