class DailyWorkEntry {
  const DailyWorkEntry({
    required this.dayName,
    this.checkInMinutes,
    this.checkOutMinutes,
    this.attendanceNote,
  });

  final String dayName;
  final int? checkInMinutes;
  final int? checkOutMinutes;
  final String? attendanceNote;

  DailyWorkEntry copyWith({
    int? checkInMinutes,
    int? checkOutMinutes,
    String? attendanceNote,
  }) {
    return DailyWorkEntry(
      dayName: dayName,
      checkInMinutes: checkInMinutes ?? this.checkInMinutes,
      checkOutMinutes: checkOutMinutes ?? this.checkOutMinutes,
      attendanceNote: attendanceNote ?? this.attendanceNote,
    );
  }

  double get workingHours {
    final start = checkInMinutes;
    final end = checkOutMinutes;
    if (start == null || end == null) return 0;

    final minutes = end >= start ? end - start : (24 * 60 - start) + end;
    return minutes / 60;
  }

  factory DailyWorkEntry.fromMap(Map<String, dynamic> map) {
    return DailyWorkEntry(
      dayName: map['dayName'] as String? ?? '',
      checkInMinutes: (map['checkInMinutes'] as num?)?.toInt(),
      checkOutMinutes: (map['checkOutMinutes'] as num?)?.toInt(),
      attendanceNote: map['attendanceNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayName': dayName,
      'checkInMinutes': checkInMinutes,
      'checkOutMinutes': checkOutMinutes,
      'attendanceNote': attendanceNote,
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
