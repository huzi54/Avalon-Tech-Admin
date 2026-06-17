import 'package:flutter_payroll_app/models/employee_model.dart';
import 'package:flutter_payroll_app/models/employee_document_model.dart';
import 'package:flutter_payroll_app/models/attendance_report_model.dart';
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

  test('deducts 15 minutes for five-hour shifts and none below five', () {
    const fiveHours = DailyWorkEntry(
      dayName: 'Monday',
      checkInMinutes: 9 * 60,
      checkOutMinutes: 14 * 60,
    );
    const shortShift = DailyWorkEntry(
      dayName: 'Tuesday',
      checkInMinutes: 9 * 60,
      checkOutMinutes: (13 * 60) + 59,
    );

    expect(fiveHours.breakMinutes, 15);
    expect(fiveHours.workingHours, 4.75);
    expect(shortShift.breakMinutes, 0);
  });

  test('non-present status has zero hours and persists reason and rate', () {
    const entry = DailyWorkEntry(
      dayName: 'Monday',
      checkInMinutes: 9 * 60,
      checkOutMinutes: 17 * 60,
      attendanceStatus: 'Store Holiday',
      attendanceReason: 'Store closed for inventory',
      hourlyRateOverride: 22.5,
    );
    final restored = DailyWorkEntry.fromMap(entry.toMap());

    expect(restored.workingHours, 0);
    expect(restored.breakMinutes, 0);
    expect(restored.attendanceStatus, 'Store Holiday');
    expect(restored.attendanceReason, 'Store closed for inventory');
    expect(restored.hourlyRateOverride, 22.5);
  });

  test(
    'attendance period summary totals daily breaks, earnings and absences',
    () {
      final rows = [
        AttendanceReportRow(
          date: DateTime(2026, 6, 1),
          entry: const DailyWorkEntry(
            dayName: 'Monday',
            checkInMinutes: 9 * 60,
            checkOutMinutes: 17 * 60,
          ),
          hourlyRate: 20,
        ),
        AttendanceReportRow(
          date: DateTime(2026, 6, 2),
          entry: const DailyWorkEntry(
            dayName: 'Tuesday',
            checkInMinutes: 9 * 60,
            checkOutMinutes: 14 * 60,
          ),
          hourlyRate: 20,
        ),
        AttendanceReportRow(
          date: DateTime(2026, 6, 3),
          entry: const DailyWorkEntry(
            dayName: 'Wednesday',
            attendanceStatus: 'Absent',
          ),
          hourlyRate: 20,
        ),
        AttendanceReportRow(
          date: DateTime(2026, 6, 4),
          entry: const DailyWorkEntry(
            dayName: 'Thursday',
            attendanceStatus: 'Holiday',
          ),
          hourlyRate: 20,
        ),
      ];

      final summary = AttendancePeriodSummary.fromRows(rows);

      expect(summary.totalGrossHours, 13);
      expect(summary.totalBreakMinutes, 45);
      expect(summary.totalNetHours, 12.25);
      expect(summary.totalEarnings, 245);
      expect(summary.presentDays, 2);
      expect(summary.absentDays, 1);
      expect(summary.holidayDays, 1);
    },
  );

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

  test(
    'employee employment type persists with a backward-compatible default',
    () {
      const employee = EmployeeModel(
        id: 'EMP-1',
        name: 'Taylor',
        email: 'taylor@example.com',
        role: 'Employee',
        hourlyRate: 25,
        employmentType: 'Seasonal',
      );

      expect(
        EmployeeModel.fromMap(employee.toMap()).employmentType,
        'Seasonal',
      );
      expect(
        EmployeeModel.fromMap({
          'id': 'EMP-2',
          'name': 'Jordan',
          'email': 'jordan@example.com',
          'role': 'Employee',
          'hourlyRate': 20,
        }).employmentType,
        'Full-time',
      );
    },
  );

  test('employee document reference stores metadata without Base64 bytes', () {
    final reference = EmployeeDocumentReference(
      id: 'DOC-1',
      employeeId: 'EMP-1',
      documentType: 'passport',
      fileName: 'passport.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 120000,
      createdAt: DateTime(2026, 6, 15),
    );

    final stored = reference.toStoredValue();
    final restored = EmployeeDocumentReference.fromStoredValue(stored);

    expect(stored, isNot(contains('base64Data')));
    expect(restored.id, reference.id);
    expect(restored.fileName, reference.fileName);
    expect(restored.sizeBytes, reference.sizeBytes);
  });
}
