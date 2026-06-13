import 'package:flutter/foundation.dart';

class LoginFormProvider extends ChangeNotifier {
  bool _registerMode = false;

  bool get registerMode => _registerMode;

  void toggleRegisterMode() {
    _registerMode = !_registerMode;
    notifyListeners();
  }
}
