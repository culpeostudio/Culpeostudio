import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../app_theme.dart';

class CustomTitleBar extends StatelessWidget {
  final Widget? title;

  const CustomTitleBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: WindowCaption(
        brightness: Brightness.dark,
        title: title ?? Image.asset(
          'assets/wordmark_light.png',
          height: 16,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stack) => const Text(
            'CULPEO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: AppColors.bg,
      ),
    );
  }
}
