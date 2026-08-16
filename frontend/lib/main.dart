import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:http/http.dart' as http;
import './core/app_info.dart';
import './core/app_state.dart';
import './modules/login/login_screen.dart';
import './modules/dashboard/dashboard_screen.dart';
import './modules/splash/splash_screen.dart';
import './core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  await windowManager.setPreventClose(true);
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  final appState = AppState();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _initSystemTray();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initSystemTray() async {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/logo.ico' : 'assets/logo.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Culpeo Studio',
        ),
        MenuItem(
          key: 'open_last_chat',
          label: 'Letzten Chat öffnen',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'stop_engine',
          label: 'KI-Engine stoppen',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'open_last_chat') {
      windowManager.show();
      windowManager.focus();
      appState.setScreen('chat');
    } else if (menuItem.key == 'stop_engine') {
      try {
        final instances = await appState.api.getEngineInstances();
        for (final instance in instances) {
          if (instance.state == 'running') {
            await appState.api.updateEngineInstance(instance.id, {'action': 'stop'});
          }
        }
      } catch (e) {
        debugPrint('Failed to stop engine: $e');
      }
    } else if (menuItem.key == 'exit_app') {
      try {
        final url = Uri.parse('${appState.api.client.baseUrl}/shutdown');
        final headers = <String, String>{};
        if (appState.api.client.token != null) {
          headers['Authorization'] = 'Bearer ${appState.api.client.token}';
        }
        await http.post(url, headers: headers);
      } catch (e) {
        debugPrint('Failed to send shutdown request to backend: $e');
      }
      windowManager.destroy();
    }
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => _buildApp(appState),
    );
  }

  Widget _buildApp(AppState appState) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      locale: Locale(appState.language),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: AppColors.surface,
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(height: 1.4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
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
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.hoverGlow,
              width: 1.5,
            ),
          ),
        ),
      ),
      home: SplashGate(
        child: appState.isLoggedIn
            ? const DashboardScreen()
            : const LoginScreen(),
      ),
    );
  }
}
