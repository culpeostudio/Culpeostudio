import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myphilostudio/l10n/app_strings.dart';
import 'package:myphilostudio/screens/onboarding/onboarding_dialog.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/state/app_state.dart';

class _ResponseClient extends http.BaseClient {
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'configured': true,
            'language': 'en',
            'frontend_version': 'lite',
          }),
        ),
      ),
      200,
      headers: const {'content-type': 'application/json'},
    );
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

  testWidgets('confirmation saves both preferences before closing onboarding', (
    tester,
  ) async {
    appLanguage = 'de';
    final client = _ResponseClient();
    final api = ApiService.test()
      ..token = 'token'
      ..username = 'new-user'
      ..debugSetHttpClient(client);
    final appState = AppState.test(api);

    await tester.pumpWidget(MaterialApp(home: _OnboardingHost(appState)));
    await tester.pump();

    expect(find.byType(OnboardingDialog), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.tap(find.text('Lite'));
    await tester.tap(find.text("Los geht's"));
    await tester.pump();
    await tester.pump();

    expect(find.byType(OnboardingDialog), findsNothing);
    expect(appState.language, 'en');
    expect(appState.frontendVersion, 'lite');
    expect(client.requests, hasLength(1));
    final request = client.requests.single as http.Request;
    expect(request.method, 'PUT');
    expect(request.url.path, '/api/user/preferences');
    expect(jsonDecode(request.body), {
      'language': 'en',
      'frontend_version': 'lite',
    });
  });
}
