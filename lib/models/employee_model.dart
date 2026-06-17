class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.hourlyRate,
    this.employmentType = 'Full-time',
    this.defaultHours = 80,
    this.phone,
    this.department,
    this.socialSecurityNumber,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.joiningDate,
    this.endDate,
    this.legalStatus,
    this.passportFilePath,
    this.workPermitFilePath,
    this.offerLetterFilePath,
    this.additionalDocumentPaths = const [],
    this.hourlyRateHistory = const [],
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final double hourlyRate;
  final String employmentType;
  final double defaultHours;
  final String? phone;
  final String? department;
  final String? socialSecurityNumber;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? joiningDate;
  final DateTime? endDate;
  final String? legalStatus;
  final String? passportFilePath;
  final String? workPermitFilePath;
  final String? offerLetterFilePath;
  final List<String> additionalDocumentPaths;
  final List<HourlyRateChange> hourlyRateHistory;

  double hourlyRateAt(DateTime date) {
    if (hourlyRateHistory.isEmpty) return hourlyRate;
    final changes = [...hourlyRateHistory]
      ..sort((a, b) => a.effectiveAt.compareTo(b.effectiveAt));
    var rate = changes.first.previousRate;
    for (final change in changes) {
      if (change.effectiveAt.isAfter(date)) break;
      rate = change.newRate;
    }
    return rate;
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    double? hourlyRate,
    String? employmentType,
    double? defaultHours,
    String? phone,
    String? department,
    String? socialSecurityNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? joiningDate,
    DateTime? endDate,
    String? legalStatus,
    String? passportFilePath,
    String? workPermitFilePath,
    String? offerLetterFilePath,
    List<String>? additionalDocumentPaths,
    List<HourlyRateChange>? hourlyRateHistory,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      employmentType: employmentType ?? this.employmentType,
      defaultHours: defaultHours ?? this.defaultHours,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      socialSecurityNumber: socialSecurityNumber ?? this.socialSecurityNumber,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      joiningDate: joiningDate ?? this.joiningDate,
      endDate: endDate ?? this.endDate,
      legalStatus: legalStatus ?? this.legalStatus,
      passportFilePath: passportFilePath ?? this.passportFilePath,
      workPermitFilePath: workPermitFilePath ?? this.workPermitFilePath,
      offerLetterFilePath: offerLetterFilePath ?? this.offerLetterFilePath,
      additionalDocumentPaths:
          additionalDocumentPaths ?? this.additionalDocumentPaths,
      hourlyRateHistory: hourlyRateHistory ?? this.hourlyRateHistory,
    );
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'Employee',
      hourlyRate: (map['hourlyRate'] as num? ?? 0).toDouble(),
      employmentType: map['employmentType'] as String? ?? 'Full-time',
      defaultHours: (map['defaultHours'] as num? ?? 80).toDouble(),
      phone: map['phone'] as String?,
      department: map['department'] as String?,
      socialSecurityNumber: map['socialSecurityNumber'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      joiningDate: DateTime.tryParse(map['joiningDate'] as String? ?? ''),
      endDate: DateTime.tryParse(map['endDate'] as String? ?? ''),
      legalStatus: map['legalStatus'] as String?,
      passportFilePath: map['passportFilePath'] as String?,
      workPermitFilePath: map['workPermitFilePath'] as String?,
      offerLetterFilePath: map['offerLetterFilePath'] as String?,
      additionalDocumentPaths:
          (map['additionalDocumentPaths'] as List<dynamic>? ?? [])
              .map((path) => path.toString())
              .toList(),
      hourlyRateHistory:
          (map['hourlyRateHistory'] as List<dynamic>? ?? const [])
              .map(
                (item) => HourlyRateChange.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'hourlyRate': hourlyRate,
      'employmentType': employmentType,
      'defaultHours': defaultHours,
      'phone': phone,
      'department': department,
      'socialSecurityNumber': socialSecurityNumber,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'joiningDate': joiningDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'legalStatus': legalStatus,
      'passportFilePath': passportFilePath,
      'workPermitFilePath': workPermitFilePath,
      'offerLetterFilePath': offerLetterFilePath,
      'additionalDocumentPaths': additionalDocumentPaths,
      'hourlyRateHistory': [
        for (final change in hourlyRateHistory) change.toMap(),
      ],
    };
  }
}

class HourlyRateChange {
  const HourlyRateChange({
    required this.previousRate,
    required this.newRate,
    required this.effectiveAt,
  });

  final double previousRate;
  final double newRate;
  final DateTime effectiveAt;

  factory HourlyRateChange.fromMap(Map<String, dynamic> map) {
    return HourlyRateChange(
      previousRate: (map['previousRate'] as num? ?? 0).toDouble(),
      newRate: (map['newRate'] as num? ?? 0).toDouble(),
      effectiveAt:
          DateTime.tryParse(map['effectiveAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'previousRate': previousRate,
      'newRate': newRate,
      'effectiveAt': effectiveAt.toIso8601String(),
    };
  }
}
