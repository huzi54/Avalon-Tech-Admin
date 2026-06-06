import 'package:flutter/services.dart';

class AppInputFormatters {
  const AppInputFormatters._();

  static final number = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text;
    if (text.isEmpty || RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  });

  static final digitsOnly = FilteringTextInputFormatter.digitsOnly;

  static final phone = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9+\-()\s]'),
  );

  static final textOnly = FilteringTextInputFormatter.allow(
    RegExp(r"[A-Za-z\s'\-]"),
  );

  static final sentenceText = FilteringTextInputFormatter.allow(
    RegExp(r"[A-Za-z0-9\s.,'()\-]"),
  );

  static final capitalizeFirst = _CapitalizeFirstLetterFormatter();
}

class _CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final firstLetterIndex = text.indexOf(RegExp('[A-Za-z]'));
    if (firstLetterIndex == -1) return newValue;

    final capitalized =
        text.substring(0, firstLetterIndex) +
        text[firstLetterIndex].toUpperCase() +
        text.substring(firstLetterIndex + 1);

    return newValue.copyWith(
      text: capitalized,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
