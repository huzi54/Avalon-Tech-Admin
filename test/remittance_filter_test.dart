import 'package:flutter_payroll_app/models/remittance_model.dart';
import 'package:flutter_payroll_app/providers/remittance_screen_provider.dart';
import 'package:flutter_payroll_app/utils/remittance_filter.dart';
import 'package:flutter_payroll_app/utils/record_date_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('from date filters by pay-period start, not created date', () {
    final juneFirst = _record(
      id: 'early',
      periodStart: DateTime(2026, 6),
      periodEnd: DateTime(2026, 6, 7),
      createdAt: DateTime(2026, 6, 13),
    );
    final juneThirteenth = _record(
      id: 'matching',
      periodStart: DateTime(2026, 6, 13, 8),
      periodEnd: DateTime(2026, 6, 19),
      createdAt: DateTime(2026, 6, 13),
    );

    final filtered = RemittanceFilter.apply(
      records: [juneFirst, juneThirteenth],
      fromDate: DateTime(2026, 6, 13),
    );

    expect(filtered.map((record) => record.id), ['matching']);
  });

  test('date boundaries are inclusive and to date uses period end', () {
    final matching = _record(
      id: 'matching',
      periodStart: DateTime(2026, 6, 13),
      periodEnd: DateTime(2026, 6, 20, 23, 59),
      createdAt: DateTime(2026, 6, 21),
    );
    final endsLater = _record(
      id: 'later',
      periodStart: DateTime(2026, 6, 13),
      periodEnd: DateTime(2026, 6, 21),
      createdAt: DateTime(2026, 6, 21),
    );

    final filtered = RemittanceFilter.apply(
      records: [matching, endsLater],
      fromDate: DateTime(2026, 6, 13),
      toDate: DateTime(2026, 6, 20),
    );

    expect(filtered.map((record) => record.id), ['matching']);
  });

  test('screen date order sorts by pay-period start', () {
    final provider = RemittanceScreenProvider();
    final juneFirst = _record(
      id: 'period-first-created-later',
      periodStart: DateTime(2026, 6),
      periodEnd: DateTime(2026, 6, 7),
      createdAt: DateTime(2026, 6, 30),
    );
    final juneThirteenth = _record(
      id: 'period-later-created-earlier',
      periodStart: DateTime(2026, 6, 13),
      periodEnd: DateTime(2026, 6, 20),
      createdAt: DateTime(2026, 6, 1),
    );

    expect(
      provider.filtered([juneThirteenth, juneFirst]).map((record) => record.id),
      ['period-first-created-later', 'period-later-created-earlier'],
    );

    provider.updateDateSort(RecordDateSort.newestFirst);
    expect(
      provider.filtered([juneThirteenth, juneFirst]).map((record) => record.id),
      ['period-later-created-earlier', 'period-first-created-later'],
    );

    provider.dispose();
  });
}

RemittanceModel _record({
  required String id,
  required DateTime periodStart,
  required DateTime periodEnd,
  required DateTime createdAt,
}) {
  return RemittanceModel(
    id: id,
    employeeId: 'EMP-1',
    employeeName: 'Taylor',
    email: 'taylor@example.com',
    payFrequency: 'Biweekly',
    payPeriodStart: periodStart,
    payPeriodEnd: periodEnd,
    grossPay: 1000,
    employeeIncomeTax: 100,
    cppDeduction: 50,
    employeeCpp: 50,
    employerCpp: 50,
    employeeEi: 15,
    employerEi: 21,
    netPay: 835,
    totalRemittance: 236,
    createdAt: createdAt,
    status: 'Unpaid',
  );
}
