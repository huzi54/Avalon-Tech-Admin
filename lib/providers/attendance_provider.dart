import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/attendance_model.dart';
import '../services/firebase_service.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider(this._firebaseService);

  static const _boxName = 'attendance';
  final FirebaseService _firebaseService;
  final List<AttendanceModel> _records = [];
  bool isLoading = false;

  List<AttendanceModel> get records => List.unmodifiable(_records);

  Future<void> loadAttendance(String employeeId) async {
    isLoading = true;
    notifyListeners();
    await _loadLocal(employeeId);
    try {
      final remoteRecords = await _firebaseService.fetchAttendance(employeeId);
      _records
        ..clear()
        ..addAll(remoteRecords);
      await _saveLocal();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> mark({
    required String employeeId,
    required String employeeName,
    required String type,
    String? note,
  }) async {
    final attendance = AttendanceModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      employeeId: employeeId,
      employeeName: employeeName,
      timestamp: DateTime.now(),
      type: type,
      note: note,
    );
    _records.insert(0, attendance);
    notifyListeners();
    await _firebaseService.addAttendance(attendance);
    await _saveLocal();
  }

  Future<void> _loadLocal(String employeeId) async {
    final box = await Hive.openBox<Map>(_boxName);
    _records
      ..clear()
      ..addAll(
        box.values
            .map(
              (item) =>
                  AttendanceModel.fromMap(Map<String, dynamic>.from(item)),
            )
            .where((record) => record.employeeId == employeeId),
      );
  }

  Future<void> _saveLocal() async {
    final box = await Hive.openBox<Map>(_boxName);
    for (final record in _records) {
      await box.put(record.id, record.toMap());
    }
  }
}
