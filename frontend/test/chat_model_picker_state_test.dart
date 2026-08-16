import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';

/// `ScoutTab` rebuilds this state after every setState and skips publishing
/// to [AppState] when the result is `==` to what it last published - the
/// whole point being that a composer keystroke, which touches none of these
/// fields, must compare equal even though it creates a fresh callback
/// closure each time. These tests pin that contract directly, since a
/// regression here would silently turn back into "the sidebar repaints on
/// every keystroke".
void main() {
  ChatModelPickerEntry entry({String key = 'cloud:a'}) {
    return ChatModelPickerEntry(
      stableKey: key,
      label: 'Modell',
      subtitle: 'openrouter • a',
      isLocal: false,
      selectable: true,
      ready: true,
      placementLabel: '',
    );
  }

  ChatModelPickerState state({
    List<ChatModelPickerEntry>? entries,
    String? selectedKey = 'cloud:a',
  }) {
    return ChatModelPickerState(
      entries: entries ?? [entry()],
      selectedKey: selectedKey,
      loading: false,
      error: null,
      locked: false,
      lockedReason: null,
      warmupActive: false,
      warmupProgress: 0,
      warmupMessage: '',
      // A fresh closure literal every call, exactly like the real
      // `onOpenEngine: () => _appState.setScreen('engine')` in ScoutTab.
      onSelect: (_) {},
      onRefresh: () {},
      onOpenEngine: () {},
      onManageCloudModels: () {},
      onCancelWarmup: () {},
    );
  }

  test('two entries with the same fields are equal', () {
    expect(entry(), entry());
    expect(entry().hashCode, entry().hashCode);
  });

  test('an entry differing in one field is not equal', () {
    expect(entry(), isNot(equals(entry(key: 'cloud:b'))));
  });

  test(
    'two states built from the same data are equal despite fresh callbacks',
    () {
      expect(state(), state());
      expect(state().hashCode, state().hashCode);
    },
  );

  test('a state is not equal once its entries differ', () {
    expect(state(), isNot(equals(state(entries: [entry(key: 'cloud:b')]))));
  });

  test('a state is not equal once its selection differs', () {
    expect(state(), isNot(equals(state(selectedKey: 'cloud:b'))));
  });

  test('a shorter or longer entry list is never equal', () {
    expect(
      state(
        entries: [
          entry(),
          entry(key: 'cloud:b'),
        ],
      ),
      isNot(equals(state(entries: [entry()]))),
    );
  });

  test('AppState.publishChatModelPicker always notifies unconditionally', () {
    final api = ApiService();
    api.baseUrl = 'http://127.0.0.1:1/api';
    final appState = AppState.test(api);

    var notifications = 0;
    appState.addListener(() => notifications++);

    appState.publishChatModelPicker(state());
    expect(notifications, 1);

    // A second, data-equal snapshot still notifies here - publish() itself
    // always notifies; the skip lives in ScoutTab's compare-before-publish
    // guard, which is exercised end to end in
    // test/sidebar_model_publish_test.dart. This just confirms publish()
    // is unconditional so that guard is doing real work, not redundant.
    appState.publishChatModelPicker(state());
    expect(notifications, 2);
  });

  test('model-target selection requests are observable one-shot events', () {
    final api = ApiService();
    api.baseUrl = 'http://127.0.0.1:1/api';
    final appState = AppState.test(api);

    var notifications = 0;
    appState.addListener(() => notifications++);

    expect(appState.chatModelTargetSelectionRequest, 0);
    appState.requestChatModelTargetSelection();
    expect(appState.chatModelTargetSelectionRequest, 1);
    expect(notifications, 1);

    appState.requestChatModelTargetSelection();
    expect(appState.chatModelTargetSelectionRequest, 2);
    expect(notifications, 2);
  });
}
