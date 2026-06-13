import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  const AppText.body(
    this.text, {
    super.key,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : type = AppTextType.body;

  const AppText.headline(
    this.text, {
    super.key,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : type = AppTextType.headline;

  const AppText.error(
    this.text, {
    super.key,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : type = AppTextType.error;

  final String text;
  final AppTextType type;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = switch (type) {
      AppTextType.headline => theme.textTheme.headlineMedium,
      AppTextType.body => theme.textTheme.bodyMedium,
      AppTextType.error => theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.error,
      ),
    };

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

enum AppTextType { headline, body, error }
