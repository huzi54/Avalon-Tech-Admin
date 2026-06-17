import 'package:flutter_payroll_app/utils/record_date_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final records = [
    (id: 'newest', date: DateTime(2026, 6, 15)),
    (id: 'oldest', date: DateTime(2026, 6, 1)),
    (id: 'middle', date: DateTime(2026, 6, 8)),
  ];

  test('sorts records from oldest to newest by default order', () {
    final sorted = sortRecordsByDate(
      records: records,
      dateOf: (record) => record.date,
      order: RecordDateSort.oldestFirst,
    );

    expect(sorted.map((record) => record.id), ['oldest', 'middle', 'newest']);
  });

  test('sorts records from newest to oldest', () {
    final sorted = sortRecordsByDate(
      records: records,
      dateOf: (record) => record.date,
      order: RecordDateSort.newestFirst,
    );

    expect(sorted.map((record) => record.id), ['newest', 'middle', 'oldest']);
  });
}
