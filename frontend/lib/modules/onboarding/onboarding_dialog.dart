import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/user_preferences_strings.dart';
import '../../core/app_state.dart';
import '../../core/app_theme.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key, this.appState});

  final AppState? appState;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  late final AppState _appState;
  late String _language;
  late String _frontendVersion;
  bool _isSaving = false;
  String? _saveError;
  bool _recoveringInitialLoad = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState ?? AppState();
    _language = _appState.language;
    _frontendVersion = _appState.frontendVersion;
    _saveError = _appState.userPreferencesError;
    _recoveringInitialLoad = _saveError != null;
  }

  void _selectLanguage(String lang) {
    setState(() => _language = lang);
  }

  Future<void> _confirm() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    if (_recoveringInitialLoad) {
      final loaded = await _appState.retryUserPreferencesLoad();
      if (!mounted) return;
      if (loaded && !_appState.needsOnboarding) {
        _closeAfterSuccessfulSave();
        return;
      }
      setState(() {
        _isSaving = false;
        _saveError = _appState.userPreferencesError;
        _recoveringInitialLoad = !loaded;
      });
      return;
    }

    final saved = await _appState.saveUserPreferences(
      language: _language,
      frontendVersion: _frontendVersion,
    );
    if (!mounted) return;

    if (saved) {
      _closeAfterSuccessfulSave();
      return;
    }

    setState(() {
      _isSaving = false;
      _saveError = _appState.userPreferencesError;
    });
  }

  void _closeAfterSuccessfulSave() {
    setState(() => _canPop = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Widget _optionGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 360;
        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    return PopScope(
      canPop: _canPop,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('onboarding.title'),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('onboarding.subtitle'),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(tr('onboarding.languageTitle')),
                const SizedBox(height: 8),
                _optionGrid([
                  _OptionCard(
                    title: tr('onboarding.languageGerman'),
                    selected: _language == 'de',
                    enabled: !_isSaving,
                    onTap: () => _selectLanguage('de'),
                  ),
                  _OptionCard(
                    title: tr('onboarding.languageEnglish'),
                    selected: _language == 'en',
                    enabled: !_isSaving,
                    onTap: () => _selectLanguage('en'),
                  ),
                ]),
                const SizedBox(height: 24),
                _SectionTitle(tr('onboarding.versionTitle')),
                const SizedBox(height: 8),
                _optionGrid([
                  _OptionCard(
                    title: tr('onboarding.versionClassic'),
                    description: tr('onboarding.versionClassicDesc'),
                    selected: _frontendVersion == 'classic',
                    enabled: !_isSaving,
                    onTap: () => setState(() => _frontendVersion = 'classic'),
                  ),
                  _OptionCard(
                    title: tr('onboarding.versionLite'),
                    description: tr('onboarding.versionLiteDesc'),
                    selected: _frontendVersion == 'lite',
                    enabled: !_isSaving,
                    onTap: () => setState(() => _frontendVersion = 'lite'),
                  ),
                ]),
                if (_saveError != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.42),
                      ),
                    ),
                    child: Text(
                      _recoveringInitialLoad
                          ? userPreferencesText('loadFailed')
                          : userPreferencesText('saveFailed'),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(userPreferencesText('saving')),
                            ],
                          )
                        : Text(
                            _saveError == null
                                ? tr('onboarding.start')
                                : userPreferencesText('retry'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.description,
  });

  final String title;
  final String? description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
