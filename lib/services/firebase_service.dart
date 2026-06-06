import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as image;

import '../app_config.dart';
import '../models/attendance_model.dart';
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
  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    this.isAvailable = true,
  }) : _auth = isAvailable ? auth ?? FirebaseAuth.instance : null,
       _firestore = isAvailable
           ? firestore ?? FirebaseFirestore.instance
           : null,
       _storage = isAvailable ? storage ?? FirebaseStorage.instance : null;

  final bool isAvailable;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

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
      final bytes = await _compressedBytes(file, extension);
      final fileName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
      final ref = _storage!.ref().child(
        '${AppConfig.employeeDocumentsPath}/$employeeId/$documentType/$fileName',
      );
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _contentType(extension)),
      );
      return ref.getDownloadURL();
    });
  }

  Future<Uint8List> _compressedBytes(File file, String extension) async {
    final bytes = await file.readAsBytes();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) return bytes;

    final decoded = image.decodeImage(bytes);
    if (decoded == null) return bytes;

    final resized = decoded.width > 1600
        ? image.copyResize(decoded, width: 1600)
        : decoded;
    return Uint8List.fromList(image.encodeJpg(resized, quality: 72));
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
