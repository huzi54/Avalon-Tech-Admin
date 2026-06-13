class RemittanceModel {
  const RemittanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.email,
    required this.payFrequency,
    required this.payPeriodStart,
    required this.payPeriodEnd,
    required this.grossPay,
    required this.employeeIncomeTax,
    required this.cppDeduction,
    required this.employeeCpp,
    required this.employerCpp,
    required this.employeeEi,
    required this.employerEi,
    required this.netPay,
    required this.totalRemittance,
    required this.createdAt,
    this.status = 'Unpaid',
    this.paidVia,
    this.notes,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String email;
  final String payFrequency;
  final DateTime payPeriodStart;
  final DateTime payPeriodEnd;
  final double grossPay;
  final double employeeIncomeTax;
  final double cppDeduction;
  final double employeeCpp;
  final double employerCpp;
  final double employeeEi;
  final double employerEi;
  final double netPay;
  final double totalRemittance;
  final DateTime createdAt;
  final String status;
  final String? paidVia;
  final String? notes;

  RemittanceModel copyWith({
    String? status,
    String? paidVia,
    bool clearPaidVia = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return RemittanceModel(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      email: email,
      payFrequency: payFrequency,
      payPeriodStart: payPeriodStart,
      payPeriodEnd: payPeriodEnd,
      grossPay: grossPay,
      employeeIncomeTax: employeeIncomeTax,
      cppDeduction: cppDeduction,
      employeeCpp: employeeCpp,
      employerCpp: employerCpp,
      employeeEi: employeeEi,
      employerEi: employerEi,
      netPay: netPay,
      totalRemittance: totalRemittance,
      createdAt: createdAt,
      status: status ?? this.status,
      paidVia: clearPaidVia ? null : paidVia ?? this.paidVia,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }

  factory RemittanceModel.fromMap(Map<String, dynamic> map) {
    DateTime readDate(String key) {
      return DateTime.tryParse(map[key] as String? ?? '') ?? DateTime.now();
    }

    return RemittanceModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      payFrequency: map['payFrequency'] as String? ?? 'Biweekly',
      payPeriodStart: readDate('payPeriodStart'),
      payPeriodEnd: readDate('payPeriodEnd'),
      grossPay: (map['grossPay'] as num? ?? 0).toDouble(),
      employeeIncomeTax: (map['employeeIncomeTax'] as num? ?? 0).toDouble(),
      cppDeduction: (map['cppDeduction'] as num? ?? 0).toDouble(),
      employeeCpp: (map['employeeCpp'] as num? ?? 0).toDouble(),
      employerCpp: (map['employerCpp'] as num? ?? 0).toDouble(),
      employeeEi: (map['employeeEi'] as num? ?? 0).toDouble(),
      employerEi: (map['employerEi'] as num? ?? 0).toDouble(),
      netPay: (map['netPay'] as num? ?? 0).toDouble(),
      totalRemittance: (map['totalRemittance'] as num? ?? 0).toDouble(),
      createdAt: readDate('createdAt'),
      status: map['status'] as String? ?? 'Unpaid',
      paidVia: map['paidVia'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'email': email,
      'payFrequency': payFrequency,
      'payPeriodStart': payPeriodStart.toIso8601String(),
      'payPeriodEnd': payPeriodEnd.toIso8601String(),
      'grossPay': grossPay,
      'employeeIncomeTax': employeeIncomeTax,
      'cppDeduction': cppDeduction,
      'employeeCpp': employeeCpp,
      'employerCpp': employerCpp,
      'employeeEi': employeeEi,
      'employerEi': employerEi,
      'netPay': netPay,
      'totalRemittance': totalRemittance,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'paidVia': paidVia,
      'notes': notes,
    };
  }
}
