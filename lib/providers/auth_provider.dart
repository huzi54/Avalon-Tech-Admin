import 'package:flutter/foundation.dart';

import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._firebaseService);

  final FirebaseService _firebaseService;
  bool isLoading = false;
  String selectedRole = 'Employee';
  String? errorMessage;

  bool get isAuthenticated => _firebaseService.currentUser != null;

  void setRole(String role) {
    selectedRole = role;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _runAuthAction(() => _firebaseService.signIn(email, password));
  }

  Future<bool> register(String email, String password) async {
    return _runAuthAction(() async {
      final credential = await _firebaseService.register(email, password);
      await _firebaseService.saveUserRole(credential.user!.uid, selectedRole);
    });
  }

  Future<void> logout() => _firebaseService.signOut();

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
