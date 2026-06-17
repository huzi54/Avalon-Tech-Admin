import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_config.dart';
import '../../app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlutterLogo(size: 72),
            SizedBox(height: 16),
            Text(AppConfig.appName, style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
