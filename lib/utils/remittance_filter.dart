import '../models/remittance_model.dart';

class RemittanceFilter {
  const RemittanceFilter._();

  static List<RemittanceModel> apply({
    required List<RemittanceModel> records,
    String query = '',
    String status = 'All',
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final from = _dateOnly(fromDate);
    final to = _dateOnly(toDate);

    return records.where((record) {
      final periodStart = _dateOnly(record.payPeriodStart)!;
      final periodEnd = _dateOnly(record.payPeriodEnd)!;
      final searchMatches =
          normalizedQuery.isEmpty ||
          record.employeeName.toLowerCase().contains(normalizedQuery) ||
          record.employeeId.toLowerCase().contains(normalizedQuery);
      final statusMatches =
          status == 'All' ||
          record.status.toLowerCase() == status.toLowerCase();
      final dateMatches =
          (from == null || !periodStart.isBefore(from)) &&
          (to == null || !periodEnd.isAfter(to));
      return searchMatches && statusMatches && dateMatches;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static DateTime? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }
}
