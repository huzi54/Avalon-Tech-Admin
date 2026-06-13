import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_payroll_app/models/employee_model.dart';
import 'package:flutter_payroll_app/models/payroll_model.dart';
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

  test('adds other non-taxable income after statutory deductions', () {
    final payroll = const PayrollService().calculate(
      employee: const EmployeeModel(
        id: 'emp-1',
        name: 'Taylor',
        email: 'taylor@example.com',
        role: 'Employee',
        hourlyRate: 25,
      ),
      hours: 40,
      otherNonTaxableIncome: 75,
      nonTaxableIncomeReason: 'Balance carried forward',
      otherNonTaxableDeduction: 50,
      nonTaxableDeductionNote: r'Recovery note: #A-10 / 50% approved!',
      payPeriodStart: DateTime(2026, 6),
      payPeriodEnd: DateTime(2026, 6, 15),
    );

    expect(payroll.netPay, closeTo(854.70, 0.01));
    expect(payroll.finalPayableAmount, closeTo(879.70, 0.01));
    expect(payroll.otherNonTaxableIncome, 75);
    expect(payroll.nonTaxableIncomeReason, 'Balance carried forward');
    expect(
      payroll.nonTaxableDeductionNote,
      r'Recovery note: #A-10 / 50% approved!',
    );
  });

  test('assesses underpayment, exact payment, and overpayment', () {
    const service = PayrollService();

    expect(
      service
          .assessPaymentAmount(enteredAmount: 90, finalPayableAmount: 100)
          .status,
      PaymentAmountStatus.underpaid,
    );
    expect(
      service
          .assessPaymentAmount(enteredAmount: 100, finalPayableAmount: 100)
          .status,
      PaymentAmountStatus.exact,
    );
    final overpayment = service.assessPaymentAmount(
      enteredAmount: 115.25,
      finalPayableAmount: 100,
    );
    expect(overpayment.status, PaymentAmountStatus.overpaid);
    expect(overpayment.difference, 15.25);
  });

  test('persists new income, payment, credit, and symbol-note fields', () {
    final payroll = const PayrollService().calculate(
      employee: const EmployeeModel(
        id: 'emp-1',
        name: 'Taylor',
        email: 'taylor@example.com',
        role: 'Employee',
        hourlyRate: 25,
      ),
      hours: 40,
      otherNonTaxableIncome: 75,
      nonTaxableIncomeReason: 'Custom credit',
      nonTaxableDeductionNote: r'Approved: #A-10, 50% + adjustment!',
      payPeriodStart: DateTime(2026, 6),
      payPeriodEnd: DateTime(2026, 6, 15),
    );
    final restored = PayrollModel.fromMap({
      ...payroll.toMap(),
      'paidAmount': payroll.finalPayableAmount + 10,
      'extraCashGiven': 10,
    });

    expect(restored.otherNonTaxableIncome, 75);
    expect(restored.nonTaxableIncomeReason, 'Custom credit');
    expect(
      restored.nonTaxableDeductionNote,
      r'Approved: #A-10, 50% + adjustment!',
    );
    expect(restored.extraCashGiven, 10);
  });
}
