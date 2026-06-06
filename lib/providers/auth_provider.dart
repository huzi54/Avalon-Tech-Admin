import 'package:flutter/foundation.dart';

import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._firebaseService) {
    refreshProfile();
  }

  final FirebaseService _firebaseService;
  bool isLoading = false;
  String? errorMessage;
  AppUserProfile? profile;

  bool get isAuthenticated => _firebaseService.currentUser != null;
  bool get hasActiveSubscription => profile?.hasActiveSubscription ?? false;

  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    await _run(() async {
      profile = await _firebaseService.fetchCurrentUserProfile();
    });
  }

  Future<bool> loginAdmin(String email, String password) {
    return _run(() async {
      await _firebaseService.signIn(email, password);
      profile = await _firebaseService.fetchCurrentUserProfile();
    });
  }

  Future<bool> registerAdmin(String email, String password) {
    return _run(() async {
      await _firebaseService.registerAdmin(email, password);
      profile = await _firebaseService.fetchCurrentUserProfile();
    });
  }

  Future<bool> verifyOwnerPassword(String password) {
    return _run(() => _firebaseService.verifyOwnerPassword(password));
  }

  Future<bool> activateSubscription({
    required String type,
    required DateTime start,
    required DateTime end,
  }) {
    return _run(() async {
      await _firebaseService.updateSubscription(
        isPremium: true,
        subscriptionType: type,
        subscriptionStart: start,
        subscriptionEnd: end,
      );
      profile = await _firebaseService.fetchCurrentUserProfile();
    });
  }

  Future<void> logout() async {
    await _firebaseService.signOut();
    profile = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
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
