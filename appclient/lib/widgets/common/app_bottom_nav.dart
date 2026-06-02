import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.gray500,
      backgroundColor: AppColors.white,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
