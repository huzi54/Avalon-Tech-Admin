import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../app_router.dart';
import '../core/features/auth/providers/login_form_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/payroll_provider.dart';
import '../utils/date_time_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ownerPinController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ownerPinController.dispose();
    super.dispose();
  }

  Future<void> _submitAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final registerMode = context.read<LoginFormProvider>().registerMode;
    final success = registerMode
        ? await auth.registerAdmin(
            _emailController.text.trim(),
            _passwordController.text,
          )
        : await auth.loginAdmin(
            _emailController.text.trim(),
            _passwordController.text,
          );
    if (!mounted || !success) return;
    FocusScope.of(context).unfocus();
  }

  Future<void> _activateSubscription(String type) async {
    final now = DateTime.now();
    final end = type == 'Yearly'
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);
    final success = await context.read<AuthProvider>().activateSubscription(
      type: type,
      start: now,
      end: end,
    );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$type subscription activated')));
  }

  Future<void> _openOwner() async {
    const ownerPin = '1234';
    _ownerPinController.clear();
    final verified = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Owner PIN'),
        content: TextField(
          controller: _ownerPinController,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter owner PIN',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => context.pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (verified != true || !mounted) return;

    final enteredPin = _ownerPinController.text.trim();
    if (enteredPin.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter owner PIN.')));
      return;
    }

    if (enteredPin != ownerPin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Owner PIN is incorrect.')));
      return;
    }

    _loadDashboardData();
    if (!mounted) return;
    context.go(AppRoutes.dashboard);
  }

  Future<void> _loadDashboardData() async {
    try {
      await Future.wait([
        context.read<EmployeeProvider>().loadEmployees(),
        context.read<PayrollProvider>().loadPayrolls(),
      ]);
    } catch (_) {
      // Providers expose their own error messages; do not block navigation.
    }
  }

  Future<void> _openEmployee() async {
    await context.read<EmployeeProvider>().loadEmployees();
    if (!mounted) return;
    context.go(AppRoutes.employeePunch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: !auth.isAuthenticated
                        ? _adminLogin(auth)
                        : auth.hasActiveSubscription
                        ? _roleSelector(auth)
                        : _subscriptionGate(auth),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandHeader(String subtitle) {
    return Column(
      children: [
        Image.asset(AppConfig.logoPath, height: 64),
        const SizedBox(height: 18),
        Text(
          AppConfig.companyName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _adminLogin(AuthProvider auth) {
    return Consumer<LoginFormProvider>(
      builder: (context, formProvider, _) {
        final registerMode = formProvider.registerMode;
        return Form(
          key: _formKey,
          child: Column(
            key: const ValueKey('admin-login'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _brandHeader(
                registerMode
                    ? 'Create the main admin account.'
                    : 'Login with the main admin account.',
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Required';
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              _ErrorText(message: auth.errorMessage),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: auth.isLoading ? null : _submitAdmin,
                icon: auth.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_outlined),
                label: Text(
                  registerMode ? 'Create Admin Account' : 'Login Admin',
                ),
              ),
              TextButton(
                onPressed: auth.isLoading
                    ? null
                    : formProvider.toggleRegisterMode,
                child: Text(
                  registerMode
                      ? 'Already have an admin account? Login'
                      : 'Create admin account',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subscriptionGate(AuthProvider auth) {
    final profile = auth.profile;
    return Column(
      key: const ValueKey('subscription-gate'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brandHeader('Subscription required before using payroll.'),
        const SizedBox(height: 24),
        if (profile?.subscriptionEnd != null)
          Text(
            'Last subscription ended: '
            '${DateTimeHelper.formatDate(profile!.subscriptionEnd!)}',
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: auth.isLoading
                    ? null
                    : () => _activateSubscription('Monthly'),
                child: const Text('Activate Monthly'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: auth.isLoading
                    ? null
                    : () => _activateSubscription('Yearly'),
                child: const Text('Activate Yearly'),
              ),
            ),
          ],
        ),
        _ErrorText(message: auth.errorMessage),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: auth.logout,
          icon: const Icon(Icons.logout_outlined),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  Widget _roleSelector(AuthProvider auth) {
    final profile = auth.profile;
    return Column(
      key: const ValueKey('role-selector'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brandHeader('Select how you want to continue.'),
        const SizedBox(height: 12),
        if (profile != null)
          Text(
            '${profile.subscriptionType ?? 'Premium'} active until '
            '${profile.subscriptionEnd == null ? 'No end date' : DateTimeHelper.formatDate(profile.subscriptionEnd!)}',
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: auth.isLoading ? null : _openOwner,
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Login as Owner'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: auth.isLoading ? null : _openEmployee,
          icon: const Icon(Icons.badge_outlined),
          label: const Text('Login as Employee'),
        ),
        _ErrorText(message: auth.errorMessage),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: auth.logout,
          icon: const Icon(Icons.logout_outlined),
          label: const Text('Logout Admin'),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}
