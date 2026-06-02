import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
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

    final AuthProvider authProvider = context.read<AuthProvider>();
    final DeliveryProvider deliveryProvider = context.read<DeliveryProvider>();

    try {
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await deliveryProvider.loadHistory();

      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/logos/logo-app-mercao-local-entregas.png',
                        height: 110,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Entrar como entregador',
                      style: AppTextStyles.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'entregador@email.com',
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
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Entrar',
                      isLoading: authProvider.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cadastro de entregadores é feito pelo painel administrativo.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
