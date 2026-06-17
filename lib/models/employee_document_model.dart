import 'dart:convert';
import 'dart:typed_data';

class EmployeeDocumentReference {
  const EmployeeDocumentReference({
    required this.id,
    required this.employeeId,
    required this.documentType,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final String documentType;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;

  factory EmployeeDocumentReference.fromStoredValue(String value) {
    final map = Map<String, dynamic>.from(jsonDecode(value) as Map);
    return EmployeeDocumentReference(
      id: map['documentId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      documentType: map['documentType'] as String? ?? 'document',
      fileName: map['fileName'] as String? ?? 'document',
      contentType: map['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: (map['sizeBytes'] as num? ?? 0).toInt(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toStoredValue() {
    return jsonEncode({
      'storageType': 'firestoreDocument',
      'documentId': id,
      'employeeId': employeeId,
      'documentType': documentType,
      'fileName': fileName,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
    });
  }
}

class EmployeeDocumentData {
  const EmployeeDocumentData({required this.reference, required this.bytes});

  final EmployeeDocumentReference reference;
  final Uint8List bytes;
}
