import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextTheme {
  // ฟอนต์หลัก
  static const String fontFamily = 'Roboto';

  static TextTheme get defaultTextTheme => const TextTheme(
    // หัวข้อใหญ่
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    // หัวข้อรอง
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    // หัวข้อย่อย
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    // หัวข้อหลักในหน้า
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // หัวข้อส่วนใหญ่
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // หัวข้อย่อยในส่วน
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // เนื้อหาที่เน้น
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    ),
    // เนื้อหาหลัก
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    ),
    // เนื้อหาเล็ก
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    ),
    // ข้อความในปุ่ม
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // คำอธิบายเล็ก
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    // คำอธิบายเล็กมาก
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 10.0,
      fontWeight: FontWeight.w500,
      color: AppColors.textHint,
    ),
  );
}