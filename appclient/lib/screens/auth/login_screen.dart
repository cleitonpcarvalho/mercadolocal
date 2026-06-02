import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AuthProvider authProvider = context.read<AuthProvider>();

    try {
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      final String? next = GoRouterState.of(
        context,
      ).uri.queryParameters['next'];
      if (next != null && next.startsWith('/')) {
        context.go(next);
      } else {
        context.go('/home');
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -120,
              right: -70,
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -50,
              child: Container(
                height: 190,
                width: 190,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: 430,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => context.go('/home'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.gray100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.gray700,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voltar',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Image.asset(
                            'assets/logos/logo-mercado-local-horizontal-sem-fundo.png',
                            width: 190,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Bem-vindo de volta',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entre para concluir pedidos e acompanhar suas compras.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: _emailController,
                          label: 'E-mail',
                          hintText: 'seuemail@dominio.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          hintText: '********',
                          obscureText: _obscurePassword,
                          validator: Validators.password,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.gray500,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.gray500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Entrar',
                          isLoading: authProvider.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Continuar sem login',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => context.go('/home'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(
                            'Não tem conta? Cadastre-se',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Entregadores utilizam o app de entregas.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
