import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
      onChanged: onChanged,
      readOnly: readOnly,
      style: AppTextStyles.body.copyWith(color: AppColors.gray900),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.gray500),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray300),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}
