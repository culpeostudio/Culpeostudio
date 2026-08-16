import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/app_strings.dart';
import 'package:culpeo_studio/modules/login/login_api.dart';
import 'package:culpeo_studio/modules/onboarding/onboarding_dialog.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';

/// Stands in for the real API: a widget test runs under fake async, so a live
/// backend connection would never complete.
class _RecordingLoginApi extends LoginApi {
  _RecordingLoginApi(super.client);

  final List<Map<String, String>> updates = [];

  @override
  Future<Map<String, dynamic>> updateUserPreferences({
    required String language,
  }) async {
    updates.add({'language': language});
    return {'configured': true, 'language': language};
  }
}

class _OnboardingHost extends StatefulWidget {
  const _OnboardingHost(this.appState);

  final AppState appState;

  @override
  State<_OnboardingHost> createState() => _OnboardingHostState();
}

class _OnboardingHostState extends State<_OnboardingHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OnboardingDialog(appState: widget.appState),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}

void main() {
  tearDown(() => appLanguage = 'de');

  testWidgets('confirmation saves the language preference before closing onboarding', (
    tester,
  ) async {
    appLanguage = 'de';
    final api = ApiService.test()
      ..token = 'token'
      ..username = 'new-user';
    final service = _RecordingLoginApi(api.client);
    api.debugSetLoginApi(service);
    final appState = AppState.test(api);

    await tester.pumpWidget(MaterialApp(home: _OnboardingHost(appState)));
    await tester.pump();

    expect(find.byType(OnboardingDialog), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.tap(find.text("Los geht's"));
    await tester.pump();
    await tester.pump();

    expect(find.byType(OnboardingDialog), findsNothing);
    expect(appState.language, 'en');
    expect(service.updates, hasLength(1));
    expect(service.updates.single, {'language': 'en'});
  });
}
