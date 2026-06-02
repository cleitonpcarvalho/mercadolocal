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
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
