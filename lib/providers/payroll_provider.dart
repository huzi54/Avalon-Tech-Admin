import 'package:flutter/foundation.dart';

import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../models/remittance_model.dart';
import '../services/payroll_service.dart';

class PayrollProvider extends ChangeNotifier {
  PayrollProvider([Object? unusedService, PayrollService? payrollService])
    : _payrollService = payrollService ?? const PayrollService();

  final PayrollService _payrollService;
  final List<PayrollModel> _payrolls = [];
  final List<RemittanceModel> _remittances = [];

  PayrollModel? currentPreview;
  bool isLoading = false;

  List<PayrollModel> get payrolls => List.unmodifiable(_payrolls);
  List<RemittanceModel> get remittances => List.unmodifiable(_remittances);

  Future<void> loadPayrolls() async {
    notifyListeners();
  }

  PayrollCalculationResult previewCalculation({
    required double hours,
    required double rate,
    required int numberOfPayPeriods,
    double otherTaxableIncome = 0,
    double otherNonTaxableDeduction = 0,
  }) {
    return _payrollService.calculateAmounts(
      hours: hours,
      rate: rate,
      numberOfPayPeriods: numberOfPayPeriods,
      otherTaxableIncome: otherTaxableIncome,
      otherNonTaxableDeduction: otherNonTaxableDeduction,
    );
  }

  Future<PayrollModel> calculateAndSave({
    required EmployeeModel employee,
    required double hours,
    required DateTime payPeriodStart,
    required DateTime payPeriodEnd,
    DateTime? payDate,
    String payFrequency = 'Biweekly',
    int? numberOfPayPeriods,
    double otherTaxableIncome = 0,
    double otherNonTaxableDeduction = 0,
    String? nonTaxableDeductionReason,
    String? nonTaxableDeductionNote,
  }) async {
    final payroll = _payrollService.calculate(
      employee: employee,
      hours: hours,
      payPeriodStart: payPeriodStart,
      payPeriodEnd: payPeriodEnd,
      payDate: payDate,
      payFrequency: payFrequency,
      numberOfPayPeriods: numberOfPayPeriods,
      otherTaxableIncome: otherTaxableIncome,
      otherNonTaxableDeduction: otherNonTaxableDeduction,
      nonTaxableDeductionReason: nonTaxableDeductionReason,
      nonTaxableDeductionNote: nonTaxableDeductionNote,
    );

    _payrolls.insert(0, payroll);
    _remittances.insert(0, _remittanceFromPayroll(payroll, employee));
    currentPreview = payroll;
    notifyListeners();
    return payroll;
  }

  void savePayroll(PayrollModel payroll) {
    _payrolls.insert(0, payroll);
    currentPreview = payroll;
    notifyListeners();
  }

  void preview(PayrollModel payroll) {
    currentPreview = payroll;
    notifyListeners();
  }

  void updateSlipPayment({
    required String payrollId,
    required String slipStatus,
    String? paidVia,
  }) {
    final index = _payrolls.indexWhere((payroll) => payroll.id == payrollId);
    if (index == -1) return;

    final original = _payrolls[index];
    final updated = PayrollModel(
      id: original.id,
      employeeId: original.employeeId,
      employeeName: original.employeeName,
      hours: original.hours,
      rate: original.rate,
      regularIncome: original.regularIncome,
      grossPay: original.grossPay,
      annualIncome: original.annualIncome,
      federalTd1Amount: original.federalTd1Amount,
      provincialTd1Amount: original.provincialTd1Amount,
      canadaEmploymentAmount: original.canadaEmploymentAmount,
      cppBasicExemptionPerPeriod: original.cppBasicExemptionPerPeriod,
      federalTax: original.federalTax,
      provincialTax: original.provincialTax,
      cpp: original.cpp,
      ei: original.ei,
      totalTax: original.totalTax,
      totalDeductions: original.totalDeductions,
      netPay: original.netPay,
      finalPayableAmount: original.finalPayableAmount,
      payPeriodStart: original.payPeriodStart,
      payPeriodEnd: original.payPeriodEnd,
      createdAt: original.createdAt,
      payDate: original.payDate,
      payFrequency: original.payFrequency,
      numberOfPayPeriods: original.numberOfPayPeriods,
      otherTaxableIncome: original.otherTaxableIncome,
      otherNonTaxableDeduction: original.otherNonTaxableDeduction,
      nonTaxableDeductionReason: original.nonTaxableDeductionReason,
      nonTaxableDeductionNote: original.nonTaxableDeductionNote,
      slipStatus: slipStatus,
      paidVia: slipStatus.toLowerCase() == 'paid' ? paidVia : null,
      employerCpp: original.employerCpp,
      employerEi: original.employerEi,
    );

    _payrolls[index] = updated;
    if (currentPreview?.id == payrollId) {
      currentPreview = updated;
    }
    notifyListeners();
  }

  void updateRemittanceStatus({
    required String remittanceId,
    required String status,
  }) {
    final index = _remittances.indexWhere(
      (remittance) => remittance.id == remittanceId,
    );
    if (index == -1) return;

    _remittances[index] = _remittances[index].copyWith(status: status);
    notifyListeners();
  }

  RemittanceModel _remittanceFromPayroll(
    PayrollModel payroll,
    EmployeeModel employee,
  ) {
    return RemittanceModel(
      id: payroll.id,
      employeeId: payroll.employeeId,
      employeeName: payroll.employeeName,
      email: employee.email,
      payFrequency: payroll.payFrequency,
      payPeriodStart: payroll.payPeriodStart,
      payPeriodEnd: payroll.payPeriodEnd,
      grossPay: payroll.grossPay,
      employeeIncomeTax: payroll.employeeIncomeTax,
      cppDeduction: payroll.cpp,
      employeeCpp: payroll.cpp,
      employerCpp: payroll.employerCpp,
      employeeEi: payroll.ei,
      employerEi: payroll.employerEi,
      netPay: payroll.netPay,
      totalRemittance: payroll.totalRemittance,
      createdAt: payroll.createdAt,
      status: 'Unpaid',
    );
  }
}
