import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';

class BiometricLoginScreen extends StatelessWidget {
  const BiometricLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.show_chart, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 32),
              Text('InvestPro', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Invest Smart, Grow Rich', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const Spacer(),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.fingerprint, color: AppTheme.primaryGreen, size: 40),
                  onPressed: () {
                    context.showSnackBar('Biometric authentication successful!');
                    context.go('/dashboard');
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tap to login with fingerprint', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Use password instead'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
