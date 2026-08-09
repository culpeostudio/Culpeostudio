import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';

/// Chat subfolders sort a project's own chats further, one level deep. This
/// is a local, device-only feature - there is no backend endpoint for it,
/// unlike projects themselves - so it round-trips through SharedPreferences
/// (see AppState.loadChatSubfolders/_persistChatSubfolders), not `api.spark`.
void main() {
  AppState buildState() {
    final api = ApiService();
    api.baseUrl = 'http://127.0.0.1:1/api';
    final state = AppState.test(api);
    state.chatProjects.addAll([
      ChatProject(id: 'proj-1', name: 'Arbeit'),
      ChatProject(id: 'proj-2', name: 'Privat'),
    ]);
    state.chatSessions.addAll(['chat-1', 'chat-2']);
    state.sessionProjects['chat-1'] = 'proj-1';
    state.sessionProjects['chat-2'] = 'proj-1';
    return state;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new subfolder belongs to its project and starts empty', () async {
    final state = buildState();
    final folder = await state.createChatSubfolder('proj-1', 'Recherche');

    expect(state.subfoldersInProject('proj-1'), [folder]);
    expect(state.subfoldersInProject('proj-2'), isEmpty);
    expect(state.sessionsInSubfolder(folder.id), isEmpty);
  });

  test(
    'assigning a session sorts it into the subfolder and out of "direct"',
    () async {
      final state = buildState();
      final folder = await state.createChatSubfolder('proj-1', 'Recherche');

      expect(state.sessionsDirectlyInProject('proj-1'), ['chat-1', 'chat-2']);

      await state.assignSessionToSubfolder('chat-1', folder.id);

      expect(state.sessionsInSubfolder(folder.id), ['chat-1']);
      expect(state.sessionsDirectlyInProject('proj-1'), ['chat-2']);
      // Still a member of the project itself - the subfolder is inside it.
      expect(state.projectIdForSession('chat-1'), 'proj-1');
    },
  );

  test('renaming updates the same subfolder in place', () async {
    final state = buildState();
    final folder = await state.createChatSubfolder(
      'proj-1',
      'Recherche',
      color: '#6E8FE0',
    );

    await state.renameChatSubfolder(folder.id, 'Quellen', color: '#7BAE7F');

    expect(state.chatSubfolders.single.name, 'Quellen');
    expect(state.chatSubfolders.single.color, '#7BAE7F');
    expect(state.chatSubfolders.single.id, folder.id);
  });

  test(
    'deleting a subfolder keeps its chats, folded back into the project',
    () async {
      final state = buildState();
      final folder = await state.createChatSubfolder('proj-1', 'Recherche');
      await state.assignSessionToSubfolder('chat-1', folder.id);

      await state.deleteChatSubfolder(folder.id);

      expect(state.chatSubfolders, isEmpty);
      expect(state.subfolderIdForSession('chat-1'), isNull);
      expect(state.sessionsDirectlyInProject('proj-1'), contains('chat-1'));
    },
  );

  test('deleting the project cascades to its subfolders', () async {
    final state = buildState();
    final folder = await state.createChatSubfolder('proj-1', 'Recherche');
    await state.assignSessionToSubfolder('chat-1', folder.id);
    final otherFolder = await state.createChatSubfolder('proj-2', 'Bleibt');

    await state.deleteChatProject('proj-1');

    expect(state.chatSubfolders, [otherFolder]);
    expect(state.subfolderIdForSession('chat-1'), isNull);
  });

  test('moving a session to a different project drops its subfolder', () async {
    final state = buildState();
    final folder = await state.createChatSubfolder('proj-1', 'Recherche');
    await state.assignSessionToSubfolder('chat-1', folder.id);

    await state.assignSessionToProject('chat-1', 'proj-2');

    expect(state.subfolderIdForSession('chat-1'), isNull);
    expect(state.projectIdForSession('chat-1'), 'proj-2');
  });

  test('deleting a session drops its subfolder assignment too', () async {
    final state = buildState();
    final folder = await state.createChatSubfolder('proj-1', 'Recherche');
    await state.assignSessionToSubfolder('chat-1', folder.id);

    state.deleteSession('chat-1');

    // Nothing left to assert on chat-1's own state, but a stale entry here
    // would silently keep growing sessionSubfolders forever.
    expect(state.sessionSubfolders.containsKey('chat-1'), isFalse);
  });

  test('subfolders and their session assignments survive a restart', () async {
    final state = buildState();
    final folder = await state.createChatSubfolder(
      'proj-1',
      'Recherche',
      color: '#6E8FE0',
    );
    await state.assignSessionToSubfolder('chat-1', folder.id);

    final restarted = buildState();
    await restarted.loadChatSubfolders();

    expect(restarted.chatSubfolders.single.name, 'Recherche');
    expect(restarted.chatSubfolders.single.projectId, 'proj-1');
    expect(restarted.chatSubfolders.single.color, '#6E8FE0');
    expect(restarted.subfolderIdForSession('chat-1'), folder.id);
  });

  test(
    'logout clears subfolders - they are per-account, not device UI',
    () async {
      final state = buildState();
      final folder = await state.createChatSubfolder('proj-1', 'Recherche');
      await state.assignSessionToSubfolder('chat-1', folder.id);

      state.logout();

      expect(state.chatSubfolders, isEmpty);
      expect(state.sessionSubfolders, isEmpty);
    },
  );
}
