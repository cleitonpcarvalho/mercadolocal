import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MarketService _marketService = const MarketService();

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _didInitUser = false;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _showPasswordSection = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitUser) return;

    final UserModel? user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _cityController.text = user.city ?? '';
      _stateController.text = user.state ?? '';
    }

    _didInitUser = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingProfile = true;
    });

    final AuthProvider authProvider = context.read<AuthProvider>();

    try {
      final UserModel updatedUser = await _marketService
          .updateProfile(<String, dynamic>{
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
          });

      await authProvider.updateUser(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Perfil atualizado com sucesso.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
    });

    try {
      await _marketService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Senha alterada com sucesso.'),
        ),
      );
      setState(() {
        _showPasswordSection = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (!mounted) return;
    context.go('/home');
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/search');
      case 2:
        context.go('/orders');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final UserModel? user = authProvider.user;

    if (authProvider.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: AppColors.gray50,
        body: LoadingWidget(),
      );
    }

    if (!authProvider.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.gray900,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const EmptyStateWidget(
                title: 'Entre para acessar seu perfil',
                subtitle: 'Seus dados e configuracoes ficam aqui.',
                icon: Icons.person_outline,
              ),
              AppButton(
                label: 'Ir para login',
                onPressed: () => context.go('/login?next=%2Fprofile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: _onBottomNavTap,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildHeader(user),
          const SizedBox(height: 14),
          _buildProfileForm(),
          const SizedBox(height: 14),
          _buildPasswordSection(),
          const SizedBox(height: 14),
          AppButton(
            label: 'Sair da conta',
            variant: AppButtonVariant.secondary,
            icon: Icons.logout_outlined,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.avatar ?? '',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 70,
                height: 70,
                color: AppColors.gray100,
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(user.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(user.email, style: AppTextStyles.body),
                if (user.city != null || user.state != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    '${user.city ?? ''}${user.city != null && user.state != null ? ' - ' : ''}${user.state ?? ''}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Editar perfil',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nameController,
              label: 'Nome',
              validator: (String? value) =>
                  Validators.requiredField(value, label: 'Nome'),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _phoneController,
              label: 'Telefone',
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _cityController,
              label: 'Cidade',
              validator: (String? value) =>
                  Validators.requiredField(value, label: 'Cidade'),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _stateController,
              label: 'Estado',
              validator: (String? value) =>
                  Validators.requiredField(value, label: 'Estado'),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Salvar alteracoes',
              isLoading: _isSavingProfile,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Alterar senha',
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showPasswordSection = !_showPasswordSection;
                    });
                  },
                  child: Text(
                    _showPasswordSection ? 'Fechar' : 'Abrir',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (_showPasswordSection) ...<Widget>[
              const SizedBox(height: 8),
              AppTextField(
                controller: _oldPasswordController,
                label: 'Senha atual',
                obscureText: _obscureOldPassword,
                validator: Validators.password,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureOldPassword = !_obscureOldPassword;
                    });
                  },
                  icon: Icon(
                    _obscureOldPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.gray500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: _newPasswordController,
                label: 'Nova senha',
                obscureText: _obscureNewPassword,
                validator: Validators.password,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.gray500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Atualizar senha',
                isLoading: _isChangingPassword,
                onPressed: _changePassword,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
