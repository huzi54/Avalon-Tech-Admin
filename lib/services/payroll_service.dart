import 'dart:math';

import '../models/employee_model.dart';
import '../models/payroll_model.dart';

class PayrollCalculationResult {
  const PayrollCalculationResult({
    required this.regularIncome,
    required this.grossPay,
    required this.annualIncome,
    required this.federalTd1Amount,
    required this.provincialTd1Amount,
    required this.canadaEmploymentAmount,
    required this.cppBasicExemptionPerPeriod,
    required this.federalTax,
    required this.provincialTax,
    required this.cpp,
    required this.ei,
    required this.totalTax,
    required this.totalDeductions,
    required this.netPay,
    required this.finalPayableAmount,
    required this.employerCpp,
    required this.employerEi,
  });

  final double regularIncome;
  final double grossPay;
  final double annualIncome;
  final double federalTd1Amount;
  final double provincialTd1Amount;
  final double canadaEmploymentAmount;
  final double cppBasicExemptionPerPeriod;
  final double federalTax;
  final double provincialTax;
  final double cpp;
  final double ei;
  final double totalTax;
  final double totalDeductions;
  final double netPay;
  final double finalPayableAmount;
  final double employerCpp;
  final double employerEi;
}

enum PaymentAmountStatus { underpaid, exact, overpaid }

class PaymentAmountAssessment {
  const PaymentAmountAssessment({
    required this.status,
    required this.difference,
  });

  final PaymentAmountStatus status;
  final double difference;
}

class PayrollService {
  const PayrollService();

  static const Map<String, int> payPeriodsByFrequency = {
    'Biweekly': 26,
    'Weekly': 52,
    'Monthly': 12,
  };

  static const double _cppRate = 0.0595;
  static const double _eiRate = 0.0163;
  static const double _federalTd1Amount = 16452;
  static const double _provincialTd1Amount = 11188;
  static const double _canadaEmploymentAmount = 1515;
  static const double _cppBasicAnnualExemption = 3500;

  PaymentAmountAssessment assessPaymentAmount({
    required double enteredAmount,
    required double finalPayableAmount,
  }) {
    final difference = _round2(enteredAmount - finalPayableAmount);
    if (difference < 0) {
      return PaymentAmountAssessment(
        status: PaymentAmountStatus.underpaid,
        difference: difference.abs(),
      );
    }
    if (difference > 0) {
      return PaymentAmountAssessment(
        status: PaymentAmountStatus.overpaid,
        difference: difference,
      );
    }
    return const PaymentAmountAssessment(
      status: PaymentAmountStatus.exact,
      difference: 0,
    );
  }

  PayrollCalculationResult calculateAmounts({
    required double hours,
    required double rate,
    required int numberOfPayPeriods,
    double? regularIncomeOverride,
    double otherTaxableIncome = 0,
    double otherNonTaxableIncome = 0,
    double otherNonTaxableDeduction = 0,
  }) {
    final safePayPeriods = numberOfPayPeriods <= 0 ? 26 : numberOfPayPeriods;

    // B45 = B43 * B44. Regular income is normal hourly earnings for the period.
    final regularIncome = _round2(regularIncomeOverride ?? (hours * rate));

    // B47 = B45 + B46. Gross pay includes taxable additions before deductions.
    final grossPay = _round2(regularIncome + otherTaxableIncome);

    // B48 = B47 * B42. Annual income is used for annual tax bracket formulas.
    final annualIncome = _round2(grossPay * safePayPeriods);

    // B52 = 3500 / B42. The CPP basic exemption is prorated per pay period.
    final cppBasicExemptionPerPeriod = _round2(
      _cppBasicAnnualExemption / safePayPeriods,
    );

    // B53 = ROUND((B47 - B52) * 0.0595, 2).
    final cppPensionableEarnings = (grossPay - cppBasicExemptionPerPeriod)
        .clamp(0, double.infinity);
    final cpp = _round2(cppPensionableEarnings * _cppRate);

    // B54 = ROUND(B47 * 0.0163, 2).
    final ei = _round2(grossPay * _eiRate);

    // B55. Federal tax follows the supplied spreadsheet formula, including
    // TD1, Canada employment amount, CPP, and EI credit adjustments.
    final federalBaseTax = annualIncome <= 58523
        ? annualIncome * 0.14
        : annualIncome <= 117045
        ? (58523 * 0.14) + ((annualIncome - 58523) * 0.205)
        : 0.0;
    final federalTax = _round2(
      max(
        0,
        (federalBaseTax / safePayPeriods) -
            ((_federalTd1Amount * 0.14) / safePayPeriods) -
            ((_canadaEmploymentAmount * 0.14) / safePayPeriods) -
            (cpp * 0.14) -
            (ei * 0.14) +
            (annualIncome <= 58523 ? 0.08 : -0.01),
      ),
    );

    // B56. Provincial tax follows the supplied NL spreadsheet formula.
    final provincialTaxableAnnualIncome =
        (grossPay - (cpp * (0.01 / 0.0595))) * safePayPeriods;
    final provincialBaseTax = provincialTaxableAnnualIncome <= 44678
        ? provincialTaxableAnnualIncome * 0.087
        : provincialTaxableAnnualIncome <= 89354
        ? (provincialTaxableAnnualIncome * 0.145) - 2591
        : (provincialTaxableAnnualIncome * 0.158) - 3753;
    final provincialTax = _round2(
      max(
        0,
        (provincialBaseTax -
                (_provincialTd1Amount * 0.087) -
                (safePayPeriods * cpp * (0.0495 / 0.0595) * 0.087) -
                (safePayPeriods * ei * 0.087)) /
            safePayPeriods,
      ),
    );

    // B57/B60/B61. Total deductions are payroll statutory deductions only.
    // Other non-taxable deductions are shown separately and reduce net pay
    // after Total Deductions is calculated.
    final totalTax = _round2(federalTax + provincialTax);
    final totalDeductions = _round2(cpp + ei + totalTax);
    final netPay = _round2(grossPay - totalDeductions);
    final finalPayableAmount = _round2(
      netPay + otherNonTaxableIncome - otherNonTaxableDeduction,
    );

    return PayrollCalculationResult(
      regularIncome: regularIncome,
      grossPay: grossPay,
      annualIncome: annualIncome,
      federalTd1Amount: _federalTd1Amount,
      provincialTd1Amount: _provincialTd1Amount,
      canadaEmploymentAmount: _canadaEmploymentAmount,
      cppBasicExemptionPerPeriod: cppBasicExemptionPerPeriod,
      federalTax: federalTax,
      provincialTax: provincialTax,
      cpp: cpp,
      ei: ei,
      totalTax: totalTax,
      totalDeductions: totalDeductions,
      netPay: netPay,
      finalPayableAmount: finalPayableAmount,
      employerCpp: cpp,
      employerEi: _round2(ei * 1.4),
    );
  }

  PayrollModel calculate({
    required EmployeeModel employee,
    required double hours,
    required DateTime payPeriodStart,
    required DateTime payPeriodEnd,
    String? id,
    DateTime? createdAt,
    DateTime? payDate,
    String payFrequency = 'Biweekly',
    int? numberOfPayPeriods,
    double? regularIncomeOverride,
    double otherTaxableIncome = 0,
    double otherNonTaxableIncome = 0,
    String? nonTaxableIncomeReason,
    double otherNonTaxableDeduction = 0,
    String? nonTaxableDeductionReason,
    String? nonTaxableDeductionNote,
  }) {
    final periods =
        numberOfPayPeriods ?? payPeriodsByFrequency[payFrequency] ?? 26;
    final result = calculateAmounts(
      hours: hours,
      rate: employee.hourlyRate,
      numberOfPayPeriods: periods,
      regularIncomeOverride: regularIncomeOverride,
      otherTaxableIncome: otherTaxableIncome,
      otherNonTaxableIncome: otherNonTaxableIncome,
      otherNonTaxableDeduction: otherNonTaxableDeduction,
    );

    return PayrollModel(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      employeeId: employee.id,
      employeeName: employee.name,
      hours: hours,
      rate: employee.hourlyRate,
      regularIncome: result.regularIncome,
      grossPay: result.grossPay,
      annualIncome: result.annualIncome,
      federalTd1Amount: result.federalTd1Amount,
      provincialTd1Amount: result.provincialTd1Amount,
      canadaEmploymentAmount: result.canadaEmploymentAmount,
      cppBasicExemptionPerPeriod: result.cppBasicExemptionPerPeriod,
      federalTax: result.federalTax,
      provincialTax: result.provincialTax,
      cpp: result.cpp,
      ei: result.ei,
      totalTax: result.totalTax,
      totalDeductions: result.totalDeductions,
      netPay: result.netPay,
      finalPayableAmount: result.finalPayableAmount,
      payPeriodStart: payPeriodStart,
      payPeriodEnd: payPeriodEnd,
      createdAt: createdAt ?? DateTime.now(),
      payDate: payDate,
      payFrequency: payFrequency,
      numberOfPayPeriods: periods,
      otherTaxableIncome: otherTaxableIncome,
      otherNonTaxableIncome: otherNonTaxableIncome,
      nonTaxableIncomeReason: nonTaxableIncomeReason,
      otherNonTaxableDeduction: otherNonTaxableDeduction,
      nonTaxableDeductionReason: nonTaxableDeductionReason,
      nonTaxableDeductionNote: nonTaxableDeductionNote,
      employerCpp: result.employerCpp,
      employerEi: result.employerEi,
    );
  }

  double _round2(double value) => (value * 100).round() / 100;
}
