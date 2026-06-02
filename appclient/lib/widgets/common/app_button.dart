import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = variant == AppButtonVariant.primary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isPrimary ? AppColors.primary : AppColors.white,
          foregroundColor: isPrimary ? AppColors.white : AppColors.primary,
          side: BorderSide(
            color: isPrimary ? AppColors.primary : AppColors.primary,
          ),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null)
                    Icon(icon, size: 18)
                  else
                    const SizedBox.shrink(),
                  if (icon != null) const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: isPrimary ? AppColors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
