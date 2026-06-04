import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_payroll_app/models/employee_model.dart';
import 'package:flutter_payroll_app/services/payroll_service.dart';

void main() {
  test('calculates gross pay, deductions, and net pay', () {
    final payroll = const PayrollService().calculate(
      employee: const EmployeeModel(
        id: 'emp-1',
        name: 'Taylor',
        email: 'taylor@example.com',
        role: 'Employee',
        hourlyRate: 25,
      ),
      hours: 40,
      payPeriodStart: DateTime(2026, 6),
      payPeriodEnd: DateTime(2026, 6, 15),
    );

    expect(payroll.regularIncome, 1000);
    expect(payroll.grossPay, 1000);
    expect(payroll.annualIncome, 26000);
    expect(payroll.federalTd1Amount, 16452);
    expect(payroll.provincialTd1Amount, 11188);
    expect(payroll.canadaEmploymentAmount, 1515);
    expect(payroll.cppBasicExemptionPerPeriod, closeTo(134.62, 0.01));
    expect(payroll.federalTax, closeTo(33.84, 0.01));
    expect(payroll.provincialTax, closeTo(43.67, 0.01));
    expect(payroll.totalTax, closeTo(77.51, 0.01));
    expect(payroll.cpp, closeTo(51.49, 0.01));
    expect(payroll.ei, closeTo(16.3, 0.01));
    expect(payroll.totalDeductions, closeTo(145.30, 0.01));
    expect(payroll.netPay, closeTo(854.70, 0.01));
    expect(payroll.finalPayableAmount, closeTo(854.70, 0.01));
    expect(payroll.slipStatus, 'Unpaid');
    expect(payroll.paidVia, isNull);
    expect(payroll.employerCpp, closeTo(51.49, 0.01));
    expect(payroll.employerEi, closeTo(22.82, 0.01));
  });

  test('keeps other non-taxable deduction outside total deductions', () {
    final payroll = const PayrollService().calculate(
      employee: const EmployeeModel(
        id: 'emp-1',
        name: 'Taylor',
        email: 'taylor@example.com',
        role: 'Employee',
        hourlyRate: 25,
      ),
      hours: 40,
      otherNonTaxableDeduction: 50,
      payPeriodStart: DateTime(2026, 6),
      payPeriodEnd: DateTime(2026, 6, 15),
    );

    expect(payroll.totalDeductions, closeTo(145.30, 0.01));
    expect(payroll.netPay, closeTo(854.70, 0.01));
    expect(payroll.finalPayableAmount, closeTo(804.70, 0.01));
    expect(payroll.otherNonTaxableDeduction, 50);
  });
}
