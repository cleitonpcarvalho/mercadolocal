import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message = 'Carregando...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
