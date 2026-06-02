import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.gray900,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.gray900,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.gray700,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.gray500,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );
}
