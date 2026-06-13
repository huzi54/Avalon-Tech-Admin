class PayrollModel {
  const PayrollModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.hours,
    required this.rate,
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
    required this.payPeriodStart,
    required this.payPeriodEnd,
    required this.createdAt,
    this.payDate,
    this.payFrequency = 'Biweekly',
    this.numberOfPayPeriods = 26,
    this.otherTaxableIncome = 0,
    this.otherNonTaxableDeduction = 0,
    this.nonTaxableDeductionReason,
    this.nonTaxableDeductionNote,
    this.slipStatus = 'Unpaid',
    this.paidVia,
    this.checkNumber,
    this.employerCpp = 0,
    this.employerEi = 0,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final double hours;
  final double rate;
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
  final DateTime payPeriodStart;
  final DateTime payPeriodEnd;
  final DateTime createdAt;
  final DateTime? payDate;
  final String payFrequency;
  final int numberOfPayPeriods;
  final double otherTaxableIncome;
  final double otherNonTaxableDeduction;
  final String? nonTaxableDeductionReason;
  final String? nonTaxableDeductionNote;
  final String slipStatus;
  final String? paidVia;
  final String? checkNumber;
  final double employerCpp;
  final double employerEi;

  double get employeeIncomeTax => federalTax + provincialTax;
  double get totalRemittance =>
      employeeIncomeTax + cpp + ei + employerCpp + employerEi;

  factory PayrollModel.fromMap(Map<String, dynamic> map) {
    DateTime readDate(String key) {
      return DateTime.tryParse(map[key] as String? ?? '') ?? DateTime.now();
    }

    return PayrollModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      hours: (map['hours'] as num? ?? 0).toDouble(),
      rate: (map['rate'] as num? ?? 0).toDouble(),
      regularIncome: (map['regularIncome'] as num? ?? 0).toDouble(),
      grossPay: (map['grossPay'] as num? ?? 0).toDouble(),
      annualIncome: (map['annualIncome'] as num? ?? 0).toDouble(),
      federalTd1Amount: (map['federalTd1Amount'] as num? ?? 0).toDouble(),
      provincialTd1Amount: (map['provincialTd1Amount'] as num? ?? 0).toDouble(),
      canadaEmploymentAmount: (map['canadaEmploymentAmount'] as num? ?? 0)
          .toDouble(),
      cppBasicExemptionPerPeriod:
          (map['cppBasicExemptionPerPeriod'] as num? ?? 0).toDouble(),
      federalTax: (map['federalTax'] as num? ?? 0).toDouble(),
      provincialTax: (map['provincialTax'] as num? ?? 0).toDouble(),
      cpp: (map['cpp'] as num? ?? 0).toDouble(),
      ei: (map['ei'] as num? ?? 0).toDouble(),
      totalTax: (map['totalTax'] as num? ?? 0).toDouble(),
      totalDeductions: (map['totalDeductions'] as num? ?? 0).toDouble(),
      netPay: (map['netPay'] as num? ?? 0).toDouble(),
      finalPayableAmount:
          (map['finalPayableAmount'] as num?)?.toDouble() ??
          ((map['netPay'] as num? ?? 0) -
                  (map['otherNonTaxableDeduction'] as num? ?? 0))
              .toDouble(),
      payPeriodStart: readDate('payPeriodStart'),
      payPeriodEnd: readDate('payPeriodEnd'),
      createdAt: readDate('createdAt'),
      payDate: DateTime.tryParse(map['payDate'] as String? ?? ''),
      payFrequency: map['payFrequency'] as String? ?? 'Biweekly',
      numberOfPayPeriods: (map['numberOfPayPeriods'] as num? ?? 26).toInt(),
      otherTaxableIncome: (map['otherTaxableIncome'] as num? ?? 0).toDouble(),
      otherNonTaxableDeduction: (map['otherNonTaxableDeduction'] as num? ?? 0)
          .toDouble(),
      nonTaxableDeductionReason: map['nonTaxableDeductionReason'] as String?,
      nonTaxableDeductionNote: map['nonTaxableDeductionNote'] as String?,
      slipStatus: map['slipStatus'] as String? ?? 'Unpaid',
      paidVia: map['paidVia'] as String?,
      checkNumber: map['checkNumber'] as String?,
      employerCpp: (map['employerCpp'] as num? ?? 0).toDouble(),
      employerEi: (map['employerEi'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'hours': hours,
      'rate': rate,
      'regularIncome': regularIncome,
      'grossPay': grossPay,
      'annualIncome': annualIncome,
      'federalTd1Amount': federalTd1Amount,
      'provincialTd1Amount': provincialTd1Amount,
      'canadaEmploymentAmount': canadaEmploymentAmount,
      'cppBasicExemptionPerPeriod': cppBasicExemptionPerPeriod,
      'federalTax': federalTax,
      'provincialTax': provincialTax,
      'cpp': cpp,
      'ei': ei,
      'totalTax': totalTax,
      'totalDeductions': totalDeductions,
      'netPay': netPay,
      'finalPayableAmount': finalPayableAmount,
      'payPeriodStart': payPeriodStart.toIso8601String(),
      'payPeriodEnd': payPeriodEnd.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'payDate': payDate?.toIso8601String(),
      'payFrequency': payFrequency,
      'numberOfPayPeriods': numberOfPayPeriods,
      'otherTaxableIncome': otherTaxableIncome,
      'otherNonTaxableDeduction': otherNonTaxableDeduction,
      'nonTaxableDeductionReason': nonTaxableDeductionReason,
      'nonTaxableDeductionNote': nonTaxableDeductionNote,
      'slipStatus': slipStatus,
      'paidVia': paidVia,
      'checkNumber': checkNumber,
      'employerCpp': employerCpp,
      'employerEi': employerEi,
    };
  }
}
