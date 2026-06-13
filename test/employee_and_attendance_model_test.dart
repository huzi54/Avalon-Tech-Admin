import 'package:flutter_payroll_app/models/employee_model.dart';
import 'package:flutter_payroll_app/models/weekly_work_report_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deducts a 30-minute unpaid break from completed attendance', () {
    const entry = DailyWorkEntry(
      dayName: 'Monday',
      checkInMinutes: 9 * 60,
      checkOutMinutes: 17 * 60,
    );

    expect(entry.grossWorkingHours, 8);
    expect(entry.breakMinutes, 30);
    expect(entry.workingHours, 7.5);
  });

  test('returns the hourly rate effective on the attendance date', () {
    final employee = EmployeeModel(
      id: 'EMP-1',
      name: 'Taylor',
      email: 'taylor@example.com',
      role: 'Employee',
      hourlyRate: 30,
      hourlyRateHistory: [
        HourlyRateChange(
          previousRate: 20,
          newRate: 25,
          effectiveAt: DateTime(2026, 2),
        ),
        HourlyRateChange(
          previousRate: 25,
          newRate: 30,
          effectiveAt: DateTime(2026, 5),
        ),
      ],
    );

    expect(employee.hourlyRateAt(DateTime(2026, 1, 15)), 20);
    expect(employee.hourlyRateAt(DateTime(2026, 3, 15)), 25);
    expect(employee.hourlyRateAt(DateTime(2026, 6, 15)), 30);
  });
}
