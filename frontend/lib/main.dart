import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Flutter framework error: ${details.exceptionAsString()}');
      debugPrintStack(stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught platform error: $error');
      debugPrintStack(stackTrace: stack);
    }
    return false;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    // Listen at the top so toggling the theme rebuilds MaterialApp.theme,
    // not just the home widget.
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => _buildApp(appState),
    );
  }

  Widget _buildApp(AppState appState) {
    return MaterialApp(
      title: 'FillyEngine Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: appState.themeBrightness,
        colorScheme: appState.themeBrightness == Brightness.dark
            ? ColorScheme.dark(
                primary: AppColors.gold,
                secondary: AppColors.gold,
                // In Material 3 ist die frühere `background`-Rolle mit `surface`
                // verschmolzen (deprecated); der Fenster-Hintergrund wird ohnehin
                // separat über scaffoldBackgroundColor gesetzt.
                surface: AppColors.obsidianSurface,
                error: Colors.redAccent,
              )
            : ColorScheme.light(
                primary: AppColors.goldMuted,
                secondary: AppColors.goldMuted,
                surface: AppColors.alabasterSurface,
                error: Colors.redAccent,
              ),
        scaffoldBackgroundColor: AppColors.bg(appState.themeBrightness),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(height: 1.4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.gold),
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary(appState.themeBrightness),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface(appState.themeBrightness),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.divider(appState.themeBrightness),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
        ),
      ),
      home: appState.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
