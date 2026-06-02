import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('As senhas nao coincidem'),
        ),
      );
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();

    try {
      await authProvider.register(<String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
        'role': 'customer',
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
      });

      if (!mounted) return;
      context.go('/home');
    } catch (error) {
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        backgroundColor: AppColors.gray50,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _nameController,
                  label: 'Nome completo',
                  validator: (String? value) =>
                      Validators.requiredField(value, label: 'Nome'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  label: 'Senha',
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar senha',
                  obscureText: _obscureConfirm,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _phoneController,
                  label: 'Telefone',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _cityController,
                  label: 'Cidade',
                  validator: (String? value) =>
                      Validators.requiredField(value, label: 'Cidade'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _stateController,
                  label: 'Estado',
                  validator: (String? value) =>
                      Validators.requiredField(value, label: 'Estado'),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Text(
                    'Tipo de conta: Cliente',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Criar conta',
                  isLoading: authProvider.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Ja possui conta? Entrar',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
