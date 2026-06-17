import 'package:flutter_payroll_app/models/attendance_report_model.dart';
import 'package:flutter_payroll_app/models/employee_model.dart';
import 'package:flutter_payroll_app/models/payroll_model.dart';
import 'package:flutter_payroll_app/models/weekly_work_report_model.dart';
import 'package:flutter_payroll_app/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds complete employee and owner pay slips', () async {
    final payroll = PayrollModel(
      id: 'payroll-1',
      employeeId: 'EMP-1001',
      employeeName: 'John Doe',
      hours: 80,
      rate: 25,
      regularIncome: 2000,
      grossPay: 2200,
      annualIncome: 57200,
      federalTd1Amount: 16452,
      provincialTd1Amount: 11188,
      canadaEmploymentAmount: 1515,
      cppBasicExemptionPerPeriod: 134.62,
      federalTax: 189.62,
      provincialTax: 73.45,
      cpp: 65.34,
      ei: 35.86,
      totalTax: 263.07,
      totalDeductions: 364.27,
      netPay: 1835.73,
      finalPayableAmount: 1785.73,
      payPeriodStart: DateTime(2026, 5, 12),
      payPeriodEnd: DateTime(2026, 5, 25),
      payDate: DateTime(2026, 5, 27),
      createdAt: DateTime(2026, 5, 27),
      otherTaxableIncome: 200,
      otherNonTaxableIncome: 25,
      nonTaxableIncomeReason: 'Balance carried forward',
      otherNonTaxableDeduction: 50,
      nonTaxableDeductionReason: 'Advance',
      nonTaxableDeductionNote: 'Approved employee advance repayment.',
      slipStatus: 'Paid',
      paidVia: 'Check',
      checkNumber: '12345',
      paidAmount: 1800,
      extraCashGiven: 14.27,
      employerCpp: 65.34,
      employerEi: 50.20,
    );

    const service = PdfService();
    final employeePdf = await service.buildEmployeePaySlip(
      payroll,
      designation: 'Tailor',
      otherTaxableLabel: 'Vacation Pay',
      checkNumber: payroll.checkNumber,
    );
    final ownerPdf = await service.buildEmployeePaySlip(
      payroll,
      designation: 'Tailor',
      otherTaxableLabel: 'Vacation Pay',
      checkNumber: payroll.checkNumber,
      includeOwnerAnnualDetails: true,
    );

    expect(employeePdf, isNotEmpty);
    expect(ownerPdf.length, greaterThan(employeePdf.length));
  });

  test('builds printable weekly attendance report', () async {
    const employee = EmployeeModel(
      id: 'EMP-1001',
      name: 'John Doe',
      email: 'john@example.com',
      role: 'Tailor',
      hourlyRate: 25,
    );
    final rows = [
      AttendanceReportRow(
        date: DateTime(2026, 6, 15),
        entry: const DailyWorkEntry(
          dayName: 'Monday',
          checkInMinutes: 9 * 60,
          checkOutMinutes: 17 * 60,
        ),
        hourlyRate: 25,
      ),
      AttendanceReportRow(
        date: DateTime(2026, 6, 16),
        entry: const DailyWorkEntry(
          dayName: 'Tuesday',
          attendanceStatus: 'Festival',
          attendanceReason: 'Community festival',
        ),
        hourlyRate: 25,
      ),
    ];

    final bytes = await const PdfService().buildAttendanceReport(
      employee: employee,
      rows: rows,
      periodStart: DateTime(2026, 6, 15),
      periodEnd: DateTime(2026, 6, 21),
    );

    expect(bytes, isNotEmpty);
  });
}
