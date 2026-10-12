import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/splash/launch_splash_screen.dart';
import 'screens/splash/onboarding_screen.dart';
import 'theme/app_theme.dart';

class BloodDonorApp extends StatelessWidget {
  const BloodDonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _RootRouter(),
    );
  }
}

/// Figures out whether to show onboarding, login, or the authenticated
/// home shell, then routes there.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // Small delay so the branded splash is visible even on fast connections.
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 900)),
      _storage.hasSeenOnboarding(),
      context.read<AuthProvider>().bootstrap(),
    ]);

    final seenOnboarding = results[1] as bool;
    if (!mounted) return;

    if (!seenOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final authStatus = context.read<AuthProvider>().status;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authStatus == AuthStatus.authenticated
            ? const HomeShell()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LaunchSplashScreen();
  }
}
