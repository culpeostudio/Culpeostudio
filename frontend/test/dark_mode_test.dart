import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/main.dart';
import 'package:myphilostudio/theme/app_theme.dart';
import 'package:myphilostudio/theme/dark_theme.dart';

void main() {
  testWidgets('forces the Obsidian theme when the platform prefers light', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(binding.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const MyApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.dark);
    expect(app.theme?.colorScheme.brightness, Brightness.dark);
    expect(AppColors.bg(Brightness.light), DarkColors.bg);
    expect(AppColors.surface(Brightness.light), DarkColors.surface);
  });
}
