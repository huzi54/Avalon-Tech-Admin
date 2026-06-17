import 'weekly_work_report_model.dart';

class AttendanceReportRow {
  const AttendanceReportRow({
    required this.date,
    required this.entry,
    required this.hourlyRate,
  });

  final DateTime date;
  final DailyWorkEntry entry;
  final double hourlyRate;

  double get breakDeduction => (entry.breakMinutes / 60) * hourlyRate;
  double get netPay => entry.workingHours * hourlyRate;
}

class AttendancePeriodSummary {
  const AttendancePeriodSummary({
    required this.totalGrossHours,
    required this.totalBreakMinutes,
    required this.totalNetHours,
    required this.totalEarnings,
    required this.presentDays,
    required this.absentDays,
    required this.holidayDays,
  });

  final double totalGrossHours;
  final int totalBreakMinutes;
  final double totalNetHours;
  final double totalEarnings;
  final int presentDays;
  final int absentDays;
  final int holidayDays;

  factory AttendancePeriodSummary.fromRows(Iterable<AttendanceReportRow> rows) {
    var grossHours = 0.0;
    var breakMinutes = 0;
    var netHours = 0.0;
    var earnings = 0.0;
    var present = 0;
    var absent = 0;
    var holidays = 0;

    for (final row in rows) {
      grossHours += row.entry.grossWorkingHours;
      breakMinutes += row.entry.breakMinutes;
      netHours += row.entry.workingHours;
      earnings += row.netPay;
      switch (row.entry.attendanceStatus.toLowerCase()) {
        case 'present':
          present++;
        case 'absent':
          absent++;
        case 'holiday':
        case 'store holiday':
        case 'festival':
          holidays++;
      }
    }

    return AttendancePeriodSummary(
      totalGrossHours: grossHours,
      totalBreakMinutes: breakMinutes,
      totalNetHours: netHours,
      totalEarnings: earnings,
      presentDays: present,
      absentDays: absent,
      holidayDays: holidays,
    );
  }
}
