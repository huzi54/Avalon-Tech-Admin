import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_config.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';

class FirebaseService {
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

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _requireFirebase(
      () => _auth!.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<UserCredential> register(String email, String password) {
    return _requireFirebase(
      () => _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() => _requireFirebase(() => _auth!.signOut());

  Future<void> saveUserRole(String uid, String role) {
    return _requireFirebase(
      () => _firestore!.collection(AppConfig.usersCollection).doc(uid).set({
        'uid': uid,
        'role': role,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)),
    );
  }

  Future<void> addEmployee(EmployeeModel employee) {
    return _requireFirebase(
      () => _firestore!
          .collection(AppConfig.employeesCollection)
          .doc(employee.id)
          .set(employee.toMap()),
    );
  }

  Future<List<EmployeeModel>> fetchEmployees() async {
    final snapshot = await _requireFirebase(
      () => _firestore!.collection(AppConfig.employeesCollection).get(),
    );
    return snapshot.docs
        .map((doc) => EmployeeModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> updateEmployee(EmployeeModel employee) {
    return _requireFirebase(
      () => _firestore!
          .collection(AppConfig.employeesCollection)
          .doc(employee.id)
          .update(employee.toMap()),
    );
  }

  Future<void> removeEmployee(String employeeId) {
    return _requireFirebase(
      () => _firestore!
          .collection(AppConfig.employeesCollection)
          .doc(employeeId)
          .delete(),
    );
  }

  Future<void> addPayroll(PayrollModel payroll) {
    return _requireFirebase(
      () => _firestore!
          .collection(AppConfig.payrollsCollection)
          .doc(payroll.id)
          .set(payroll.toMap()),
    );
  }

  Future<List<PayrollModel>> fetchPayrolls() async {
    final snapshot = await _requireFirebase(
      () => _firestore!.collection(AppConfig.payrollsCollection).get(),
    );
    return snapshot.docs
        .map((doc) => PayrollModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> addAttendance(AttendanceModel attendance) {
    return _requireFirebase(
      () => _firestore!
          .collection(AppConfig.attendanceCollection)
          .doc(attendance.id)
          .set(attendance.toMap()),
    );
  }

  Future<List<AttendanceModel>> fetchAttendance(String employeeId) async {
    final snapshot = await _requireFirebase(
      () => _firestore!
          .collection(AppConfig.attendanceCollection)
          .where('employeeId', isEqualTo: employeeId)
          .get(),
    );
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<T> _requireFirebase<T>(Future<T> Function() action) {
    if (!isAvailable) {
      return Future<T>.error(
        StateError(
          'Firebase is not configured yet. Connect Firebase to enable this action.',
        ),
      );
    }
    return action();
  }
}
