import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _confirmAndLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja realmente encerrar sua sessão?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    final AuthProvider authProvider = context.read<AuthProvider>();
    final DeliveryProvider deliveryProvider = context.read<DeliveryProvider>();

    await authProvider.logout();
    deliveryProvider.clearState();

    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final DeliveryProvider deliveryProvider = context.watch<DeliveryProvider>();

    final UserModel? user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.gray900,
        ),
        body: const EmptyStateWidget(
          title: 'Usuário não autenticado',
          subtitle: 'Realize login para visualizar seu perfil.',
          icon: Icons.person_outline,
        ),
      );
    }

    final int totalDeliveries = deliveryProvider.deliveryHistory
        .where((delivery) => delivery.status == 'delivered')
        .length;

    const double averageRating = 0;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Perfil do entregador'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
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
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget:
                        (BuildContext context, String url, dynamic error) {
                          return Container(
                            width: 72,
                            height: 72,
                            color: AppColors.gray100,
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.gray500,
                            ),
                          );
                        },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.name,
                        style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(user.email, style: AppTextStyles.body),
                      const SizedBox(height: 2),
                      Text(user.phone ?? '-', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Média de avaliação', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    ...List<Widget>.generate(
                      5,
                      (int index) => Icon(
                        index < averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      averageRating > 0
                          ? averageRating.toStringAsFixed(1)
                          : 'Sem avaliação',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total de entregas concluídas: $totalDeliveries',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Sair da conta',
            variant: AppButtonVariant.secondary,
            icon: Icons.logout_outlined,
            isLoading: _isLoggingOut,
            onPressed: _confirmAndLogout,
          ),
        ],
      ),
    );
  }
}
