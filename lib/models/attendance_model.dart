class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.timestamp,
    required this.type,
    this.note,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime timestamp;
  final String type;
  final String? note;

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      type: map['type'] as String? ?? 'checkIn',
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'note': note,
    };
  }
}
