import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));

    if (!mounted) return;

    final AuthProvider authProvider = context.read<AuthProvider>();
    await authProvider.loadUser();

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              'assets/logos/mercado-local-logo-sem-fundo.png',
              width: 260,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              'O shopping da sua cidade',
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
