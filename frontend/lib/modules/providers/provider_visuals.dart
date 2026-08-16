import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../settings/settings_widgets.dart';

/// Shared brand marks, dialog chrome and link handling for the provider
/// module.  Connection presets and the built-in Marketplace vendors both draw
/// from this table so one vendor keeps one icon and one colour wherever it is
/// shown.

class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    super.key,
    required this.icon,
    required this.color,
    this.size = 31,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Icon(icon, color: color, size: size * 0.56),
    );
  }
}

class ProviderStatusDot extends StatelessWidget {
  const ProviderStatusDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 5),
        ],
      ),
    );
  }
}

Widget providerDialogLabel(String label) => Text(
  label,
  style: const TextStyle(
    color: SettingsPalette.textFaint,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.85,
  ),
);

InputDecoration providerDialogInputDecoration({
  String? hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: SettingsPalette.textHint),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFF101015),
    counterStyle: const TextStyle(color: SettingsPalette.textFaint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: CulpeoColors.actionHover, width: 1.2),
    ),
  );
}

IconData providerIconFor(String id) => switch (id) {
  'openai' => Icons.auto_awesome_rounded,
  'anthropic' => Icons.psychology_alt_outlined,
  'google_gemini' => Icons.diamond_outlined,
  'qwen_model_studio' || 'qwen_coding_plan' => Icons.code_rounded,
  'mistral' => Icons.air_rounded,
  'groq' => Icons.speed_rounded,
  'together' => Icons.groups_rounded,
  'deepseek' => Icons.travel_explore_rounded,
  'openrouter' => Icons.route_rounded,
  'featherless' => Icons.cloud_queue_rounded,
  'huggingface' => Icons.sentiment_satisfied_alt_rounded,
  'fireworks' => Icons.local_fire_department_outlined,
  'aws_bedrock' => Icons.cloud_circle_outlined,
  'azure_openai' => Icons.window_outlined,
  _ => Icons.hub_outlined,
};

Color providerColorFor(String id) => switch (id) {
  'openai' => const Color(0xFF74AA9C),
  'anthropic' => const Color(0xFFD4A574),
  'google_gemini' => const Color(0xFF8AB4F8),
  'qwen_model_studio' || 'qwen_coding_plan' => const Color(0xFF8BAAF7),
  'mistral' => const Color(0xFFF2A65A),
  'groq' => const Color(0xFFF765A3),
  'together' => const Color(0xFF8C7CFF),
  'deepseek' => const Color(0xFF6EA8FE),
  'openrouter' => const Color(0xFF4DD0E1),
  'featherless' => const Color(0xFFAB47BC),
  'huggingface' => const Color(0xFFFFD21E),
  'fireworks' => const Color(0xFFFF8A65),
  'aws_bedrock' => const Color(0xFFFF9900),
  'azure_openai' => const Color(0xFF0078D4),
  _ => CulpeoColors.metric,
};

/// Where to create a fresh key for each provider, distinct from a preset's
/// documentation URL: the docs page is usually a models reference, not the
/// account settings page that actually issues a key.
String? providerApiKeyUrlFor(String id) => switch (id) {
  'openai' => 'https://platform.openai.com/api-keys',
  'anthropic' => 'https://console.anthropic.com/settings/keys',
  'google_gemini' => 'https://aistudio.google.com/apikey',
  'qwen_model_studio' || 'qwen_coding_plan' =>
    'https://bailian.console.alibabacloud.com/?tab=model#/api-key',
  'mistral' => 'https://console.mistral.ai/api-keys',
  'groq' => 'https://console.groq.com/keys',
  'together' => 'https://api.together.ai/settings/api-keys',
  'deepseek' => 'https://platform.deepseek.com/api_keys',
  'perplexity' => 'https://www.perplexity.ai/account/api/keys',
  'openrouter' => 'https://openrouter.ai/keys',
  'featherless' => 'https://featherless.ai/account/api-keys',
  'huggingface' => 'https://huggingface.co/settings/tokens',
  'fireworks' => 'https://fireworks.ai/account/api-keys',
  _ => null,
};

/// Opens [rawUrl] in the system browser.  Returns an error message the caller
/// can surface, or null when the link opened.
Future<String?> openProviderLink(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) return 'Die Adresse ist ungültig.';
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  return opened ? null : 'Der Link konnte nicht geöffnet werden.';
}

void showProviderMessage(
  BuildContext context,
  String message,
  Color color,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: CulpeoColors.panel,
        content: Text(message, style: TextStyle(color: color)),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
