import 'package:flutter/widgets.dart';

class Responsive extends StatelessWidget {
  const Responsive({required this.desktop, this.compact, super.key});

  final Widget desktop;
  final Widget? compact;

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 820;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1180;
  }

  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 700) return 16;
    if (width < 1180) return 24;
    return 32;
  }

  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 760) return 1;
    if (width < 1180) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return compact ?? desktop;
        }
        return desktop;
      },
    );
  }
}
