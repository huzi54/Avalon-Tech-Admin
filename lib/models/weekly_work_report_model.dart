class DailyWorkEntry {
  const DailyWorkEntry({
    required this.dayName,
    this.checkInMinutes,
    this.checkOutMinutes,
    this.attendanceNote,
    this.attendanceStatus = 'Present',
    this.attendanceReason,
    this.hourlyRateOverride,
  });

  final String dayName;
  final int? checkInMinutes;
  final int? checkOutMinutes;
  final String? attendanceNote;
  final String attendanceStatus;
  final String? attendanceReason;
  final double? hourlyRateOverride;

  DailyWorkEntry copyWith({
    int? checkInMinutes,
    int? checkOutMinutes,
    String? attendanceNote,
    String? attendanceStatus,
    String? attendanceReason,
    double? hourlyRateOverride,
    bool clearAttendanceReason = false,
    bool clearHourlyRateOverride = false,
  }) {
    return DailyWorkEntry(
      dayName: dayName,
      checkInMinutes: checkInMinutes ?? this.checkInMinutes,
      checkOutMinutes: checkOutMinutes ?? this.checkOutMinutes,
      attendanceNote: attendanceNote ?? this.attendanceNote,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      attendanceReason: clearAttendanceReason
          ? null
          : attendanceReason ?? this.attendanceReason,
      hourlyRateOverride: clearHourlyRateOverride
          ? null
          : hourlyRateOverride ?? this.hourlyRateOverride,
    );
  }

  double get workingHours {
    if (attendanceStatus != 'Present') return 0;
    final grossMinutes = _grossMinutes;
    if (grossMinutes == 0) return 0;
    return (grossMinutes - breakMinutes).clamp(0, double.infinity) / 60;
  }

  double get grossWorkingHours => _grossMinutes / 60;

  int get breakMinutes {
    if (attendanceStatus != 'Present') return 0;
    final grossHours = grossWorkingHours;
    if (grossHours >= 8) return 30;
    if (grossHours >= 5) return 15;
    return 0;
  }

  int get _grossMinutes {
    final start = checkInMinutes;
    final end = checkOutMinutes;
    if (start == null || end == null) return 0;

    return end >= start ? end - start : (24 * 60 - start) + end;
  }

  factory DailyWorkEntry.fromMap(Map<String, dynamic> map) {
    return DailyWorkEntry(
      dayName: map['dayName'] as String? ?? '',
      checkInMinutes: (map['checkInMinutes'] as num?)?.toInt(),
      checkOutMinutes: (map['checkOutMinutes'] as num?)?.toInt(),
      attendanceNote: map['attendanceNote'] as String?,
      attendanceStatus: map['attendanceStatus'] as String? ?? 'Present',
      attendanceReason: map['attendanceReason'] as String?,
      hourlyRateOverride: (map['hourlyRateOverride'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayName': dayName,
      'checkInMinutes': checkInMinutes,
      'checkOutMinutes': checkOutMinutes,
      'attendanceNote': attendanceNote,
      'attendanceStatus': attendanceStatus,
      'attendanceReason': attendanceReason,
      'hourlyRateOverride': hourlyRateOverride,
    };
  }
}

class WeeklyWorkReportModel {
  const WeeklyWorkReportModel({
    required this.id,
    required this.employeeId,
    required this.weekStart,
    required this.entries,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final DateTime weekStart;
  final List<DailyWorkEntry> entries;
  final DateTime createdAt;

  WeeklyWorkReportModel copyWith({
    DateTime? weekStart,
    List<DailyWorkEntry>? entries,
  }) {
    return WeeklyWorkReportModel(
      id: id,
      employeeId: employeeId,
      weekStart: weekStart ?? this.weekStart,
      entries: entries ?? this.entries,
      createdAt: createdAt,
    );
  }

  double get totalHours {
    return entries.fold<double>(0, (sum, entry) => sum + entry.workingHours);
  }

  factory WeeklyWorkReportModel.fromMap(Map<String, dynamic> map) {
    DateTime readDate(String key) {
      return DateTime.tryParse(map[key] as String? ?? '') ?? DateTime.now();
    }

    return WeeklyWorkReportModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      weekStart: readDate('weekStart'),
      entries: (map['entries'] as List<dynamic>? ?? [])
          .map(
            (entry) =>
                DailyWorkEntry.fromMap(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      createdAt: readDate('createdAt'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'weekStart': weekStart.toIso8601String(),
      'entries': [for (final entry in entries) entry.toMap()],
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
