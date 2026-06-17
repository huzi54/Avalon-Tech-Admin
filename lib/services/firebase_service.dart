import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as image;

import '../app_config.dart';
import '../models/attendance_model.dart';
import '../models/employee_document_model.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../models/remittance_model.dart';
import '../models/weekly_work_report_model.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.isPremium,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.subscriptionType,
  });

  final String uid;
  final String email;
  final String role;
  final bool isPremium;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final String? subscriptionType;

  bool get hasActiveSubscription {
    if (!isPremium) return false;
    final end = subscriptionEnd;
    return end == null || end.isAfter(DateTime.now());
  }

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'admin',
      isPremium: map['isPremium'] as bool? ?? false,
      subscriptionStart: DateTime.tryParse(
        map['subscriptionStart'] as String? ?? '',
      ),
      subscriptionEnd: DateTime.tryParse(
        map['subscriptionEnd'] as String? ?? '',
      ),
      subscriptionType: map['subscriptionType'] as String?,
    );
  }
}

class AppServiceException implements Exception {
  const AppServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseService {
  static const int _maxProfileDocumentBytes = 550 * 1024;
  static const String _documentCacheBox = 'employeeDocumentCache';

  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    this.isAvailable = true,
  }) : _auth = isAvailable ? auth ?? FirebaseAuth.instance : null,
       _firestore = isAvailable
           ? firestore ?? FirebaseFirestore.instance
           : null;

  final bool isAvailable;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final Map<String, EmployeeDocumentData> _employeeDocumentCache = {};

  User? get currentUser => _auth?.currentUser;
  Stream<User?> authStateChanges() =>
      _auth?.authStateChanges() ?? const Stream.empty();

  Future<UserCredential> signIn(String email, String password) {
    return _guard(
      () => _auth!.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<UserCredential> registerAdmin(String email, String password) {
    return _guard(() async {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await saveUserProfile(
        uid: credential.user!.uid,
        email: email,
        role: 'admin',
        isPremium: false,
      );
      return credential;
    });
  }

  Future<void> verifyOwnerPassword(String password) {
    return _guard(() async {
      final user = _auth!.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw const AppServiceException('Please login as admin first.');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    });
  }

  Future<void> signOut() => _guard(() => _auth!.signOut());

  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String role,
    required bool isPremium,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    String? subscriptionType,
  }) {
    return _guard(
      () => _firestore!.collection(AppConfig.usersCollection).doc(uid).set({
        'uid': uid,
        'email': email,
        'role': role,
        'isPremium': isPremium,
        'subscriptionStart': subscriptionStart?.toIso8601String(),
        'subscriptionEnd': subscriptionEnd?.toIso8601String(),
        'subscriptionType': subscriptionType,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)),
    );
  }

  Future<AppUserProfile?> fetchCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _guard(
      () =>
          _firestore!.collection(AppConfig.usersCollection).doc(user.uid).get(),
    );
    if (!doc.exists) {
      await saveUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        role: 'admin',
        isPremium: false,
      );
      return AppUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        role: 'admin',
        isPremium: false,
      );
    }
    return AppUserProfile.fromMap({...doc.data()!, 'uid': doc.id});
  }

  Future<void> updateSubscription({
    required bool isPremium,
    required String subscriptionType,
    required DateTime subscriptionStart,
    required DateTime subscriptionEnd,
  }) async {
    final user = currentUser;
    if (user == null) throw const AppServiceException('Please login first.');
    await saveUserProfile(
      uid: user.uid,
      email: user.email ?? '',
      role: 'admin',
      isPremium: isPremium,
      subscriptionStart: subscriptionStart,
      subscriptionEnd: subscriptionEnd,
      subscriptionType: subscriptionType,
    );
  }

  Future<void> addEmployee(EmployeeModel employee) {
    return _guard(
      () => _firestore!
          .collection(AppConfig.employeesCollection)
          .doc(employee.id)
          .set(employee.toMap(), SetOptions(merge: true)),
    );
  }

  Future<List<EmployeeModel>> fetchEmployees() async {
    final snapshot = await _guard(
      () => _firestore!
          .collection(AppConfig.employeesCollection)
          .orderBy('name')
          .get(),
    );
    return snapshot.docs
        .map((doc) => EmployeeModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> updateEmployee(EmployeeModel employee) {
    return _guard(
      () => _firestore!
          .collection(AppConfig.employeesCollection)
          .doc(employee.id)
          .set(employee.toMap(), SetOptions(merge: true)),
    );
  }

  Future<void> removeEmployee(String employeeId) {
    return _guard(
      () => _firestore!
          .collection(AppConfig.employeesCollection)
          .doc(employeeId)
          .delete(),
    );
  }

  Future<void> savePayroll(PayrollModel payroll) {
    return _guard(
      () => _firestore!
          .collection(AppConfig.payrollsCollection)
          .doc(payroll.id)
          .set(payroll.toMap(), SetOptions(merge: true)),
    );
  }

  Future<List<PayrollModel>> fetchPayrolls() async {
    final snapshot = await _guard(
      () => _firestore!
          .collection(AppConfig.payrollsCollection)
          .orderBy('createdAt', descending: true)
          .get(),
    );
    return snapshot.docs
        .map((doc) => PayrollModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> saveRemittance(RemittanceModel remittance) {
    return _guard(
      () => _firestore!
          .collection(AppConfig.remittancesCollection)
          .doc(remittance.id)
          .set(remittance.toMap(), SetOptions(merge: true)),
    );
  }

  Future<List<RemittanceModel>> fetchRemittances() async {
    final snapshot = await _guard(
      () => _firestore!
          .collection(AppConfig.remittancesCollection)
          .orderBy('createdAt', descending: true)
          .get(),
    );
    return snapshot.docs
        .map((doc) => RemittanceModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> saveWeeklyReport(WeeklyWorkReportModel report) {
    return _guard(
      () => _firestore!
          .collection(AppConfig.weeklyReportsCollection)
          .doc(report.id)
          .set(report.toMap(), SetOptions(merge: true)),
    );
  }

  Future<List<WeeklyWorkReportModel>> fetchWeeklyReports({
    String? employeeId,
  }) async {
    Query<Map<String, dynamic>> query = _firestore!.collection(
      AppConfig.weeklyReportsCollection,
    );
    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }
    final snapshot = await _guard(() => query.get());
    return snapshot.docs
        .map(
          (doc) => WeeklyWorkReportModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();
  }

  Future<void> addAttendance(AttendanceModel attendance) {
    return _guard(
      () => _firestore!
          .collection(AppConfig.attendanceCollection)
          .doc(attendance.id)
          .set(attendance.toMap(), SetOptions(merge: true)),
    );
  }

  Future<List<AttendanceModel>> fetchAttendance(String employeeId) async {
    final snapshot = await _guard(
      () => _firestore!
          .collection(AppConfig.attendanceCollection)
          .where('employeeId', isEqualTo: employeeId)
          .get(),
    );
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<String> uploadEmployeeDocument({
    required String employeeId,
    required String localPath,
    required String documentType,
  }) {
    return _guard(() async {
      final file = File(localPath);
      if (!await file.exists()) {
        throw const AppServiceException('Selected file was not found.');
      }

      final extension = localPath.split('.').last.toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png'].contains(extension);
      final bytes = await _compressedBytes(file, extension);
      if (bytes.length > _maxProfileDocumentBytes) {
        throw const AppServiceException(
          'Document is too large after compression. Please choose a file under 550KB.',
        );
      }
      final storedExtension = isImage ? 'jpg' : extension;
      final contentType = _contentType(storedExtension);
      final fileName =
          '$documentType-${DateTime.now().microsecondsSinceEpoch}.$storedExtension';
      final documentId =
          '$employeeId-$documentType-${DateTime.now().microsecondsSinceEpoch}';
      final compressedForStorage = _gzipIfSmaller(bytes);
      final createdAt = DateTime.now();

      // Each file has its own Firestore document. This keeps the employee
      // profile well below Firestore's 1 MiB document limit.
      await _firestore!
          .collection(AppConfig.employeeDocumentsCollection)
          .doc(documentId)
          .set({
            'storageType': 'firestoreBase64',
            'employeeId': employeeId,
            'documentType': documentType,
            'fileName': fileName,
            'contentType': contentType,
            'sizeBytes': bytes.length,
            'encoding': compressedForStorage.isGzipped ? 'gzip' : 'identity',
            'base64Data': base64Encode(compressedForStorage.bytes),
            'createdAt': createdAt.toIso8601String(),
          });

      final reference = EmployeeDocumentReference(
        id: documentId,
        employeeId: employeeId,
        documentType: documentType,
        fileName: fileName,
        contentType: contentType,
        sizeBytes: bytes.length,
        createdAt: createdAt,
      );
      _employeeDocumentCache[documentId] = EmployeeDocumentData(
        reference: reference,
        bytes: bytes,
      );
      await _writeDocumentCache(reference, bytes);
      return reference.toStoredValue();
    });
  }

  Future<EmployeeDocumentData> fetchEmployeeDocument(String storedReference) {
    return _guard(() async {
      final payload = Map<String, dynamic>.from(
        jsonDecode(storedReference) as Map,
      );

      // Compatibility with employee profiles created before documents were
      // moved into their own Firestore collection.
      final legacyBase64 = payload['base64Data'] as String?;
      if (legacyBase64 != null && legacyBase64.isNotEmpty) {
        final cacheKey = 'legacy-${storedReference.hashCode}';
        final cached = _employeeDocumentCache[cacheKey];
        if (cached != null) return cached;
        final reference = EmployeeDocumentReference.fromStoredValue(
          storedReference,
        );
        final persisted = await _readDocumentCache(reference, key: cacheKey);
        if (persisted != null) {
          _employeeDocumentCache[cacheKey] = persisted;
          return persisted;
        }
        final document = EmployeeDocumentData(
          reference: reference,
          bytes: base64Decode(legacyBase64),
        );
        _employeeDocumentCache[cacheKey] = document;
        await _writeDocumentCache(reference, document.bytes, key: cacheKey);
        return document;
      }

      final reference = EmployeeDocumentReference.fromStoredValue(
        storedReference,
      );
      if (reference.id.isEmpty) {
        throw const AppServiceException('Invalid employee document reference.');
      }
      final cached = _employeeDocumentCache[reference.id];
      if (cached != null) return cached;
      final persisted = await _readDocumentCache(reference);
      if (persisted != null) {
        _employeeDocumentCache[reference.id] = persisted;
        return persisted;
      }

      final snapshot = await _firestore!
          .collection(AppConfig.employeeDocumentsCollection)
          .doc(reference.id)
          .get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw const AppServiceException('Employee document was not found.');
      }

      var bytes = base64Decode(data['base64Data'] as String? ?? '');
      if (data['encoding'] == 'gzip') {
        bytes = Uint8List.fromList(gzip.decode(bytes));
      }
      final document = EmployeeDocumentData(reference: reference, bytes: bytes);
      _employeeDocumentCache[reference.id] = document;
      await _writeDocumentCache(reference, bytes);
      return document;
    });
  }

  bool isEmployeeDocumentCached(String storedReference) {
    try {
      final payload = Map<String, dynamic>.from(
        jsonDecode(storedReference) as Map,
      );
      if (payload['base64Data'] != null) {
        return _employeeDocumentCache.containsKey(
          'legacy-${storedReference.hashCode}',
        );
      }
      final reference = EmployeeDocumentReference.fromStoredValue(
        storedReference,
      );
      return _employeeDocumentCache.containsKey(reference.id);
    } catch (_) {
      return false;
    }
  }

  Future<EmployeeDocumentData?> _readDocumentCache(
    EmployeeDocumentReference reference, {
    String? key,
  }) async {
    final box = await Hive.openBox<Map>(_documentCacheBox);
    final cacheKey = key ?? reference.id;
    final cached = box.get(cacheKey);
    if (cached == null) return null;
    try {
      final map = Map<String, dynamic>.from(cached);
      final bytes = base64Decode(map['base64Data'] as String? ?? '');
      if (bytes.isEmpty) return null;
      return EmployeeDocumentData(reference: reference, bytes: bytes);
    } catch (_) {
      await box.delete(cacheKey);
      return null;
    }
  }

  Future<void> _writeDocumentCache(
    EmployeeDocumentReference reference,
    Uint8List bytes, {
    String? key,
  }) async {
    final box = await Hive.openBox<Map>(_documentCacheBox);
    await box.put(key ?? reference.id, {
      'base64Data': base64Encode(bytes),
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Uint8List> _compressedBytes(File file, String extension) async {
    final bytes = await file.readAsBytes();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) return bytes;

    final decoded = image.decodeImage(bytes);
    if (decoded == null) return bytes;

    var resized = decoded.width > 1200
        ? image.copyResize(decoded, width: 1200)
        : decoded;

    for (final quality in [70, 60, 50, 42, 35]) {
      final encoded = Uint8List.fromList(
        image.encodeJpg(resized, quality: quality),
      );
      if (encoded.length <= _maxProfileDocumentBytes || quality == 35) {
        return encoded;
      }
      if (resized.width > 900) {
        resized = image.copyResize(resized, width: 900);
      }
    }

    return bytes;
  }

  _StoredDocumentBytes _gzipIfSmaller(Uint8List bytes) {
    final compressed = Uint8List.fromList(gzip.encode(bytes));
    if (compressed.length < bytes.length) {
      return _StoredDocumentBytes(bytes: compressed, isGzipped: true);
    }
    return _StoredDocumentBytes(bytes: bytes, isGzipped: false);
  }

  String _contentType(String extension) {
    return switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (!isAvailable) {
      throw const AppServiceException(
        'Firebase is not configured. Please connect Firebase first.',
      );
    }
    try {
      return await action();
    } on AppServiceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AppServiceException(_authMessage(error));
    } on FirebaseException catch (error) {
      throw AppServiceException(_firebaseMessage(error));
    } on SocketException {
      throw const AppServiceException(
        'Network unavailable. Please check your internet connection.',
      );
    } catch (error) {
      throw AppServiceException('Something went wrong: $error');
    }
  }

  String _authMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Invalid email or password.',
      'email-already-in-use' => 'This email is already registered.',
      'weak-password' => 'Password is too weak.',
      'network-request-failed' =>
        'Network unavailable. Please check your internet connection.',
      _ => error.message ?? 'Authentication failed.',
    };
  }

  String _firebaseMessage(FirebaseException error) {
    if (error.code == 'unavailable') {
      return 'Firebase is unavailable. Please try again when online.';
    }
    if (error.code == 'permission-denied') {
      return 'You do not have permission to perform this action.';
    }
    return error.message ?? 'Firebase request failed.';
  }
}

class _StoredDocumentBytes {
  const _StoredDocumentBytes({required this.bytes, required this.isGzipped});

  final Uint8List bytes;
  final bool isGzipped;
}
