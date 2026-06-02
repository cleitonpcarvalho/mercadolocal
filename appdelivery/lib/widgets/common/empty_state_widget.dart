import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.title,
    super.key,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: AppColors.gray300),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.gray500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
