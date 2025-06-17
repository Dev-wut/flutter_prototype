import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'text_theme.dart';

class AppTheme {
  // ธีมหลักของแอพ (โหมดมืด)
  static ThemeData get darkTheme => ThemeData(
        // สีหลักของแอพ
        primaryColor: AppColors.primary,
        primaryColorDark: AppColors.primary,
        primaryColorLight: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),

        // พื้นหลัง
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        cardColor: AppColors.cardBackground,

        // ข้อความ
        textTheme: AppTextTheme.defaultTextTheme,

        // อินพุท
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: AppDimensions.borderWidthRegular,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: AppDimensions.borderWidthRegular,
            ),
          ),
          hintStyle: AppTextTheme.defaultTextTheme.bodyMedium?.copyWith(
            color: AppColors.textHint,
          ),
        ),

        // ปุ่ม
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            textStyle: AppTextTheme.defaultTextTheme.labelLarge?.copyWith(
              color: AppColors.black,
            ),
            minimumSize:
                const Size(double.infinity, AppDimensions.buttonHeightM),
          ),
        ),

        // ปุ่มแบบ Text
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            textStyle: AppTextTheme.defaultTextTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),

        // ปุ่มแบบเส้นขอบ
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(
              color: AppColors.primary,
              width: AppDimensions.borderWidthRegular,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            textStyle: AppTextTheme.defaultTextTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
            minimumSize:
                const Size(double.infinity, AppDimensions.buttonHeightM),
          ),
        ),

        // การ์ด
        // cardTheme: CardTheme(
        //   color: AppColors.cardBackground,
        //   elevation: 0,
        //   margin: const EdgeInsets.all(AppDimensions.paddingS),
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        //   ),
        // ),

        // แถบนำทาง
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextTheme.defaultTextTheme.headlineMedium,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),

        // แทบ
        // tabBarTheme: TabBarTheme(
        //   labelColor: AppColors.primary,
        //   unselectedLabelColor: AppColors.textSecondary,
        //   labelStyle: AppTextTheme.defaultTextTheme.labelLarge,
        //   unselectedLabelStyle: AppTextTheme.defaultTextTheme.labelLarge,
        //   indicatorSize: TabBarIndicatorSize.label,
        //   indicator: const UnderlineTabIndicator(
        //     borderSide: BorderSide(
        //       color: AppColors.primary,
        //       width: AppDimensions.borderWidthThick,
        //     ),
        //   ),
        // ),

        // ตัวแบ่ง
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: AppDimensions.borderWidthThin,
          space: AppDimensions.spacingM,
        ),

        // เช็คบ็อกซ์
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surface;
          }),
          checkColor: WidgetStateProperty.all(AppColors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
          ),
        ),

        // วงกลมแสดงการโหลด
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          circularTrackColor: AppColors.surface,
        ),

        // การเปลี่ยนหน้า
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),

        // ใช้ Material 3
        useMaterial3: true,
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      );
}
