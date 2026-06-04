class Validators {
  const Validators._();

  static String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  static String? email(String? value) {
    if (requiredText(value) != null) return requiredText(value);
    if (!value!.contains('@')) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (requiredText(value) != null) return requiredText(value);
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? positiveNumber(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }
}
