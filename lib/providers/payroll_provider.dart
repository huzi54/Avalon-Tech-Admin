import 'package:flutter/foundation.dart';

import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../models/remittance_model.dart';
import '../services/firebase_service.dart';
import '../services/payroll_service.dart';

class PayrollProvider extends ChangeNotifier {
  PayrollProvider([
    FirebaseService? firebaseService,
    PayrollService? payrollService,
  ]) : _firebaseService = firebaseService ?? FirebaseService(),
       _payrollService = payrollService ?? const PayrollService() {
    loadPayrolls();
  }

  final FirebaseService _firebaseService;
  final PayrollService _payrollService;
  final List<PayrollModel> _payrolls = [];
  final List<RemittanceModel> _remittances = [];
  final Map<String, String> _otherTaxableLabels = {};

  PayrollModel? currentPreview;
  bool isLoading = false;
  String? errorMessage;

  List<PayrollModel> get payrolls => List.unmodifiable(_payrolls);
  List<RemittanceModel> get remittances => List.unmodifiable(_remittances);

  String otherTaxableLabel(String payrollId) =>
      _otherTaxableLabels[payrollId] ?? 'Other Taxable Income';

  double outstandingEmployeeCredit(String employeeId) {
    var credit = 0.0;
    final employeePayrolls =
        _payrolls.where((item) => item.employeeId == employeeId).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final payroll in employeePayrolls) {
      credit += payroll.extraCashGiven;
      if (payroll.nonTaxableDeductionReason == 'Balance carried forward') {
        credit = (credit - payroll.otherNonTaxableDeduction).clamp(
          0,
          double.infinity,
        );
      }
    }
    return credit;
  }

  Future<void> loadPayrolls() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final payrolls = await _firebaseService.fetchPayrolls();
      final remittances = await _firebaseService.fetchRemittances();
      _payrolls
        ..clear()
        ..addAll(payrolls);
      _remittances
        ..clear()
        ..addAll(remittances);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  PayrollCalculationResult previewCalculation({
    required double hours,
    required double rate,
    required int numberOfPayPeriods,
    double? regularIncomeOverride,
    double otherTaxableIncome = 0,
    double otherNonTaxableIncome = 0,
    double otherNonTaxableDeduction = 0,
  }) {
    return _payrollService.calculateAmounts(
      hours: hours,
      rate: rate,
      numberOfPayPeriods: numberOfPayPeriods,
      regularIncomeOverride: regularIncomeOverride,
      otherTaxableIncome: otherTaxableIncome,
      otherNonTaxableIncome: otherNonTaxableIncome,
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
    double? regularIncomeOverride,
    double otherTaxableIncome = 0,
    String? otherTaxableLabel,
    double otherNonTaxableIncome = 0,
    String? nonTaxableIncomeReason,
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
      regularIncomeOverride: regularIncomeOverride,
      otherTaxableIncome: otherTaxableIncome,
      otherNonTaxableIncome: otherNonTaxableIncome,
      nonTaxableIncomeReason: nonTaxableIncomeReason,
      otherNonTaxableDeduction: otherNonTaxableDeduction,
      nonTaxableDeductionReason: nonTaxableDeductionReason,
      nonTaxableDeductionNote: nonTaxableDeductionNote,
    );
    final remittance = _remittanceFromPayroll(payroll, employee);

    await _savePayrollAndRemittance(payroll, remittance);
    _payrolls.insert(0, payroll);
    _remittances.insert(0, remittance);
    _otherTaxableLabels[payroll.id] =
        otherTaxableLabel?.trim().isNotEmpty == true
        ? otherTaxableLabel!.trim()
        : 'Other Taxable Income';
    currentPreview = payroll;
    notifyListeners();
    return payroll;
  }

  Future<void> savePayroll(PayrollModel payroll) async {
    await _run(() => _firebaseService.savePayroll(payroll));
    _payrolls.insert(0, payroll);
    currentPreview = payroll;
    notifyListeners();
  }

  void preview(PayrollModel payroll) {
    currentPreview = payroll;
    notifyListeners();
  }

  Future<void> updateSlipPayment({
    required String payrollId,
    required String slipStatus,
    String? paidVia,
    String? checkNumber,
    double paidAmount = 0,
  }) async {
    final index = _payrolls.indexWhere((payroll) => payroll.id == payrollId);
    if (index == -1) return;

    final original = _payrolls[index];
    final updated = _copyPayroll(
      original,
      slipStatus: slipStatus,
      paidVia: slipStatus.toLowerCase() == 'paid' ? paidVia : null,
      checkNumber:
          slipStatus.toLowerCase() == 'paid' &&
              paidVia?.toLowerCase() == 'check'
          ? checkNumber?.trim()
          : null,
      paidAmount: slipStatus.toLowerCase() == 'paid' ? paidAmount : 0,
      extraCashGiven: _extraCashGiven(
        isPaid: slipStatus.toLowerCase() == 'paid',
        paidAmount: paidAmount,
        finalPayableAmount: original.finalPayableAmount,
      ),
    );

    await _run(() => _firebaseService.savePayroll(updated));
    _payrolls[index] = updated;
    if (currentPreview?.id == payrollId) currentPreview = updated;

    notifyListeners();
  }

  Future<PayrollModel?> updateCalculatedPayroll({
    required String payrollId,
    required EmployeeModel employee,
    required double hours,
    required DateTime payPeriodStart,
    required DateTime payPeriodEnd,
    DateTime? payDate,
    String payFrequency = 'Biweekly',
    int? numberOfPayPeriods,
    double? regularIncomeOverride,
    double otherTaxableIncome = 0,
    String? otherTaxableLabel,
    double otherNonTaxableIncome = 0,
    String? nonTaxableIncomeReason,
    double otherNonTaxableDeduction = 0,
    String? nonTaxableDeductionReason,
    String? nonTaxableDeductionNote,
  }) async {
    final index = _payrolls.indexWhere((payroll) => payroll.id == payrollId);
    if (index == -1) return null;

    final original = _payrolls[index];
    final updated = _payrollService.calculate(
      id: original.id,
      createdAt: original.createdAt,
      employee: employee,
      hours: hours,
      payPeriodStart: payPeriodStart,
      payPeriodEnd: payPeriodEnd,
      payDate: payDate,
      payFrequency: payFrequency,
      numberOfPayPeriods: numberOfPayPeriods,
      regularIncomeOverride: regularIncomeOverride,
      otherTaxableIncome: otherTaxableIncome,
      otherNonTaxableIncome: otherNonTaxableIncome,
      nonTaxableIncomeReason: nonTaxableIncomeReason,
      otherNonTaxableDeduction: otherNonTaxableDeduction,
      nonTaxableDeductionReason: nonTaxableDeductionReason,
      nonTaxableDeductionNote: nonTaxableDeductionNote,
    );
    final preservedPayment = _copyPayroll(
      updated,
      slipStatus: original.slipStatus,
      paidVia: original.paidVia,
      checkNumber: original.checkNumber,
      paidAmount: original.paidAmount,
      extraCashGiven: _extraCashGiven(
        isPaid: original.slipStatus.toLowerCase() == 'paid',
        paidAmount: original.paidAmount,
        finalPayableAmount: updated.finalPayableAmount,
      ),
    );
    final existingRemittance = _remittances
        .where((remittance) => remittance.id == payrollId)
        .firstOrNull;
    final remittance = _remittanceFromPayroll(preservedPayment, employee)
        .copyWith(
          status: existingRemittance?.status,
          paidVia: existingRemittance?.paidVia,
          notes: existingRemittance?.notes,
        );

    await _savePayrollAndRemittance(preservedPayment, remittance);
    _payrolls[index] = preservedPayment;
    final remittanceIndex = _remittances.indexWhere(
      (item) => item.id == payrollId,
    );
    if (remittanceIndex == -1) {
      _remittances.insert(0, remittance);
    } else {
      _remittances[remittanceIndex] = remittance;
    }
    _otherTaxableLabels[payrollId] =
        otherTaxableLabel?.trim().isNotEmpty == true
        ? otherTaxableLabel!.trim()
        : _otherTaxableLabels[payrollId] ?? 'Other Taxable Income';
    currentPreview = preservedPayment;
    notifyListeners();
    return preservedPayment;
  }

  Future<void> updateRemittanceStatus({
    required String remittanceId,
    required String status,
  }) async {
    final index = _remittances.indexWhere(
      (remittance) => remittance.id == remittanceId,
    );
    if (index == -1) return;

    final updated = _remittances[index].copyWith(
      status: status,
      clearPaidVia: true,
    );
    await _run(() => _firebaseService.saveRemittance(updated));
    _remittances[index] = updated;
    notifyListeners();
  }

  Future<void> updateRemittanceStatuses({
    required Set<String> remittanceIds,
    required String status,
  }) async {
    if (remittanceIds.isEmpty) return;

    final updates = <MapEntry<int, RemittanceModel>>[];
    for (var index = 0; index < _remittances.length; index++) {
      final remittance = _remittances[index];
      if (!remittanceIds.contains(remittance.id)) continue;
      updates.add(
        MapEntry(
          index,
          remittance.copyWith(status: status, clearPaidVia: true),
        ),
      );
    }

    await _run(() async {
      for (final update in updates) {
        await _firebaseService.saveRemittance(update.value);
      }
    });
    for (final update in updates) {
      _remittances[update.key] = update.value;
    }
    notifyListeners();
  }

  Future<void> updateRemittancePayment({
    required String remittanceId,
    required String status,
    String? paidVia,
  }) async {
    final index = _remittances.indexWhere(
      (remittance) => remittance.id == remittanceId,
    );
    if (index == -1) return;

    final isPaid = status.toLowerCase() == 'paid';
    final updated = _remittances[index].copyWith(
      status: status,
      paidVia: isPaid ? paidVia : null,
      clearPaidVia: !isPaid,
    );
    _remittances[index] = updated;
    notifyListeners();
    await _run(() => _firebaseService.saveRemittance(updated));
  }

  Future<void> updateRemittanceNotes({
    required String remittanceId,
    required String notes,
  }) async {
    final index = _remittances.indexWhere(
      (remittance) => remittance.id == remittanceId,
    );
    if (index == -1) return;

    final trimmed = notes.trim();
    final updated = _remittances[index].copyWith(
      notes: trimmed,
      clearNotes: trimmed.isEmpty,
    );
    _remittances[index] = updated;
    notifyListeners();
    await _run(() => _firebaseService.saveRemittance(updated));
  }

  PayrollModel _copyPayroll(
    PayrollModel original, {
    required String slipStatus,
    String? paidVia,
    String? checkNumber,
    double? paidAmount,
    double? extraCashGiven,
  }) {
    return PayrollModel(
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
      otherNonTaxableIncome: original.otherNonTaxableIncome,
      nonTaxableIncomeReason: original.nonTaxableIncomeReason,
      otherNonTaxableDeduction: original.otherNonTaxableDeduction,
      nonTaxableDeductionReason: original.nonTaxableDeductionReason,
      nonTaxableDeductionNote: original.nonTaxableDeductionNote,
      slipStatus: slipStatus,
      paidVia: paidVia,
      checkNumber: checkNumber,
      paidAmount: paidAmount ?? original.paidAmount,
      extraCashGiven: extraCashGiven ?? original.extraCashGiven,
      employerCpp: original.employerCpp,
      employerEi: original.employerEi,
    );
  }

  Future<void> _savePayrollAndRemittance(
    PayrollModel payroll,
    RemittanceModel remittance,
  ) async {
    await _run(() async {
      await _firebaseService.savePayroll(payroll);
      await _firebaseService.saveRemittance(remittance);
    });
  }

  double _extraCashGiven({
    required bool isPaid,
    required double paidAmount,
    required double finalPayableAmount,
  }) {
    if (!isPaid) return 0;
    final assessment = _payrollService.assessPaymentAmount(
      enteredAmount: paidAmount,
      finalPayableAmount: finalPayableAmount,
    );
    return assessment.status == PaymentAmountStatus.overpaid
        ? assessment.difference
        : 0;
  }

  Future<void> _run(Future<void> Function() action) async {
    errorMessage = null;
    try {
      await action();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
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
