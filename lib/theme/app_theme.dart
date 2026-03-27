import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primary = Color(0xFF2979FF);
  static const Color accent = Color(0xFF00BCD4);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFFF5252);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: accent,
          tertiary: success,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1F36),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.white,
          height: 68,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primary,
          thumbColor: primary,
          overlayColor: primary.withOpacity(0.12),
          inactiveTrackColor: primary.withOpacity(0.15),
          trackHeight: 4,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((s) =>
              s.contains(MaterialState.selected)
                  ? Colors.white
                  : const Color(0xFF8090B0)),
          trackColor: MaterialStateProperty.resolveWith((s) =>
              s.contains(MaterialState.selected)
                  ? primary
                  : const Color(0xFFDDE3F0)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          primary: const Color(0xFF5C9AFF),
          secondary: accent,
          surface: const Color(0xFF131929),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1A2235),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Color(0xFF131929),
          height: 68,
        ),
      );
}

extension AppColors on BuildContext {
  bool get _isDark =>
      Theme.of(this).brightness == Brightness.dark;

  Color get cardBg =>
      _isDark ? const Color(0xFF1A2235) : Colors.white;

  Color get pageBg =>
      _isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7FF);

  Color get textPrimary =>
      _isDark ? Colors.white : const Color(0xFF1A1F36);

  Color get textSecondary =>
      _isDark ? const Color(0xFF8A9BB8) : const Color(0xFF6B7A99);

  Color get divider =>
      _isDark ? const Color(0xFF242E45) : const Color(0xFFEDF0F8);
}
