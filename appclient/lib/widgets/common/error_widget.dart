import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: AppColors.danger, size: 42),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
