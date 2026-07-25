import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../state/app_state.dart';
import '../../widgets/app_background.dart';
import '../../widgets/top_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _setupFormKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _setupCodeController = TextEditingController();
  final AppState _appState = AppState();

  bool _bootstrapping = true;
  bool _rememberSession = false;
  bool _obscurePassword = true;
  String _sessionDuration = '24h';
  String _authenticatorApp = 'google';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAuth());
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _setupCodeController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapAuth() async {
    final restored = await _appState.restoreRememberedSession();
    if (!restored) {
      final loaded = await _appState.loadAuthStatus();
      if (loaded && _appState.totpConfigured == false) {
        await _appState.startAuthenticatorSetup();
      }
    }
    if (mounted) {
      setState(() => _bootstrapping = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final success = await _appState.login(
      _userController.text.trim(),
      _passController.text.trim(),
      rememberSession: _rememberSession,
      sessionDuration: _rememberSession ? _sessionDuration : '24h',
    );
    if (!success && mounted) {
      _showSnack(
        _appState.authError ?? 'Anmeldedaten ungueltig',
        isError: true,
      );
    }
  }

  Future<void> _handleConfirmSetup() async {
    if (!_setupFormKey.currentState!.validate()) return;
    final success = await _appState.confirmAuthenticatorSetup(
      _setupCodeController.text.trim(),
      _authenticatorApp,
    );
    if (!success && mounted) {
      _showSnack(_appState.authError ?? 'Code ist ungueltig', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    showTopNotification(
      context,
      message,
      color: isError ? Colors.redAccent : const Color(0xFF2E7D32),
    );
  }

  Future<void> _showAccountDialog({required bool resetPassword}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _AccountDialog(
          resetPassword: resetPassword,
          appState: _appState,
          showSnack: _showSnack,
          mainUserController: _userController,
        );
      },
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }
    return null;
  }

  String? _codeValidator(String? value) {
    final clean = (value ?? '').replaceAll(' ', '').trim();
    if (clean.length != 6 || int.tryParse(clean) == null) {
      return '6-stelligen Code eingeben';
    }
    return null;
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF030305).withValues(alpha: 0.55),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.28),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.38),
        size: 18,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFC9A24A), width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Image.asset('assets/logo.png', width: 62, height: 62),
        const SizedBox(height: 18),
        const Text(
          'MYPHILO ENGINE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'STUDIO PLATFORM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.35),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _panel(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 430,
          constraints: const BoxConstraints(minHeight: 570),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFF07070A).withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _loadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        const SizedBox(height: 34),
        const CircularProgressIndicator(color: Color(0xFFC9A24A)),
      ],
    );
  }

  Widget _setupContent() {
    final otpauthUrl = _appState.setupOtpauthUrl;
    final secret = _appState.setupSecret;
    return Form(
      key: _setupFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 28),
          const Text(
            'Authenticator einrichten',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Google Authenticator'),
                selected: _authenticatorApp == 'google',
                onSelected: (_) => setState(() => _authenticatorApp = 'google'),
              ),
              ChoiceChip(
                label: const Text('2FAS Authenticator'),
                selected: _authenticatorApp == '2fas',
                onSelected: (_) => setState(() => _authenticatorApp = '2fas'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _authenticatorApp == '2fas'
                ? '2FAS öffnen, „+“ wählen und den QR-Code scannen.'
                : 'Google Authenticator öffnen, „+“ wählen und den QR-Code scannen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          if (otpauthUrl != null && secret != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  data: otpauthUrl,
                  version: QrVersions.auto,
                  size: 184,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              secret,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _setupCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration(
                'Code aus der App',
                Icons.verified_user_outlined,
              ).copyWith(counterText: ''),
              validator: _codeValidator,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _appState.isLoading ? null : _handleConfirmSetup,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Einrichtung bestätigen'),
            ),
          ] else
            Text(
              _appState.authError ?? 'Setup konnte nicht geladen werden.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Widget _loginContent() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 28),
          Text(
            'Willkommen zurück',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Melde dich an, um dein Studio zu öffnen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'BENUTZERNAME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC9A24A),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Benutzername eingeben',
              Icons.person_outline,
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 24),
          const Text(
            'PASSWORT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC9A24A),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Passwort eingeben',
              Icons.lock_outline,
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Passwort anzeigen'
                    : 'Passwort verbergen',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.42),
                  size: 19,
                ),
              ),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _appState.isLoading
                ? null
                : () => setState(() => _rememberSession = !_rememberSession),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _rememberSession,
                    onChanged: _appState.isLoading
                        ? null
                        : (value) =>
                              setState(() => _rememberSession = value ?? false),
                    activeColor: const Color(0xFFC9A24A),
                    checkColor: const Color(0xFF030305),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Angemeldet bleiben',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_rememberSession) ...[
            const SizedBox(height: 8),
            Text(
              'Sitzungsdauer',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.46),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _sessionChip('8h', '8 Std.'),
                _sessionChip('24h', '24 Std.'),
                _sessionChip('48h', '48 Std.'),
                _sessionChip('permanent', 'Dauerhaft'),
              ],
            ),
          ],
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _appState.isLoading ? null : _handleLogin,
            icon: _appState.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login),
            label: const Text('Anmelden'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC9A24A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: _appState.isLoading
                    ? null
                    : () => _showAccountDialog(resetPassword: false),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Account erstellen'),
              ),
              TextButton.icon(
                onPressed: _appState.isLoading
                    ? null
                    : () => _showAccountDialog(resetPassword: true),
                icon: const Icon(Icons.lock_reset, size: 18),
                label: const Text('Passwort vergessen'),
              ),
            ],
          ),
          if (_appState.authError != null) ...[
            const SizedBox(height: 14),
            Text(
              _appState.authError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sessionChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _sessionDuration == value,
      onSelected: (_) => setState(() => _sessionDuration = value),
      selectedColor: const Color(0xFFC9A24A).withValues(alpha: 0.24),
      labelStyle: TextStyle(
        color: _sessionDuration == value
            ? const Color(0xFFFFD777)
            : Colors.white.withValues(alpha: 0.64),
        fontSize: 12,
      ),
      side: BorderSide(
        color: _sessionDuration == value
            ? const Color(0xFFC9A24A).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 40,
                bottom: 85,
              ),
              child: AnimatedBuilder(
                animation: _appState,
                builder: (context, _) {
                  final content = _bootstrapping
                      ? _loadingContent()
                      : _appState.totpConfigured == false
                      ? _setupContent()
                      : _loginContent();
                  return _panel(content);
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '© 2026 fillystudio. Alle Rechte vorbehalten.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Powered by PhiloEngine • Design & Development by fillystudio',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.18),
                    fontSize: 9,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDialog extends StatefulWidget {
  final bool resetPassword;
  final AppState appState;
  final Function(String message, {bool isError}) showSnack;
  final TextEditingController mainUserController;

  const _AccountDialog({
    required this.resetPassword,
    required this.appState,
    required this.showSnack,
    required this.mainUserController,
  });

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  late final TextEditingController _codeController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }
    return null;
  }

  String? _codeValidator(String? value) {
    final clean = (value ?? '').replaceAll(' ', '').trim();
    if (clean.length != 6 || int.tryParse(clean) == null) {
      return '6-stelligen Code eingeben';
    }
    return null;
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF030305).withValues(alpha: 0.55),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.28),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.38),
        size: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFC9A24A), width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final success = widget.resetPassword
        ? await widget.appState.resetPassword(
            _userController.text.trim(),
            _passwordController.text.trim(),
            _codeController.text.trim(),
          )
        : await widget.appState.createAccount(
            _userController.text.trim(),
            _passwordController.text.trim(),
            _codeController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      Navigator.of(context).pop();
      if (!widget.resetPassword) {
        widget.mainUserController.text = _userController.text.trim();
      }
      widget.showSnack(
        widget.resetPassword
            ? 'Passwort wurde aktualisiert.'
            : 'Account wurde erstellt.',
      );
      return;
    }

    widget.showSnack(
      widget.appState.authError ?? 'Aktion fehlgeschlagen.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B0D12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      title: Text(
        widget.resetPassword ? 'Passwort vergessen' : 'Account erstellen',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _userController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Benutzername',
                    Icons.person_outline,
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    widget.resetPassword ? 'Neues Passwort' : 'Passwort',
                    Icons.lock_outline,
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Passwort bestaetigen',
                    Icons.lock_reset_outlined,
                  ),
                  validator: (value) {
                    final error = _requiredValidator(value);
                    if (error != null) {
                      return error;
                    }
                    if (value != _passwordController.text) {
                      return 'Passwoerter stimmen nicht ueberein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Code aus ${widget.appState.authenticatorAppLabel}',
                    Icons.verified_user_outlined,
                  ).copyWith(counterText: ''),
                  validator: _codeValidator,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  widget.resetPassword
                      ? Icons.lock_reset
                      : Icons.person_add_alt_1,
                ),
          label: Text(widget.resetPassword ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }
}
