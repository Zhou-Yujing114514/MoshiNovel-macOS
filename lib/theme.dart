import 'package:flutter/material.dart';

/// 摩柿配色（与 iOS 版一致）
class AppColors {
  // 深色模式
  static const bg = Color(0xFF0f1117);
  static const card = Color(0xFF171a23);
  static const border = Color(0xFF262b38);
  static const text = Color(0xFFe6e9f0);
  static const muted = Color(0xFF8b93a7);
  static const accent = Color(0xFF4f8cff);
  static const green = Color(0xFF34c98a);
  static const red = Color(0xFFff5c6c);
  static const amber = Color(0xFFf5b64c);

  // 日间模式
  static const dayBg = Color(0xFFf5f5f0);
  static const dayCard = Color(0xFFffffff);
  static const dayBorder = Color(0xFFe0e0e0);
  static const dayText = Color(0xFF333333);
  static const dayMuted = Color(0xFF666666);
}

class AppTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: dark ? AppColors.bg : AppColors.dayBg,
      cardColor: dark ? AppColors.card : AppColors.dayCard,
      dividerColor: dark ? AppColors.border : AppColors.dayBorder,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.card : AppColors.dayCard,
        foregroundColor: dark ? AppColors.text : AppColors.dayText,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: (dark
              ? const TextTheme(
                  bodyMedium: TextStyle(color: AppColors.text, fontSize: 14),
                  bodySmall: TextStyle(color: AppColors.muted, fontSize: 12),
                )
              : const TextTheme(
                  bodyMedium: TextStyle(color: AppColors.dayText, fontSize: 14),
                  bodySmall: TextStyle(color: AppColors.dayMuted, fontSize: 12),
                ))
          .apply(
        bodyColor: dark ? AppColors.text : AppColors.dayText,
        displayColor: dark ? AppColors.text : AppColors.dayText,
      ),
      useMaterial3: true,
    );
  }
}
