import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myphilostudio/services/api_service.dart';
import 'package:myphilostudio/state/app_state.dart';

class FakePhiloBotServer {
  HttpServer? _server;
  final List<Map<String, dynamic>> requests = [];
  final List<Map<String, dynamic>> projects = [];
  final List<Map<String, dynamic>> sessions = [];
  int _idCounter = 0;

  Future<int> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handle);
    return _server!.port;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;
    final bodyText = await utf8.decoder.bind(request).join();
    final body = bodyText.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(bodyText) as Map);
    requests.add({'method': method, 'path': path, 'body': body});

    Object response;
    if (method == 'POST' && path == '/api/philobot/project') {
      _idCounter++;
      final project = {
        'id': 'proj-$_idCounter',
        'name': body['name'],
        'color': body['color'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      projects.add(project);
      response = {'status': 'created', 'project': project};
    } else if (method == 'GET' && path == '/api/philobot/projects') {
      response = {'projects': projects};
    } else if (method == 'POST' &&
        path.startsWith('/api/philobot/project/') &&
        path.endsWith('/rename')) {
      final id = path.split('/')[4];
      final project = projects.firstWhere((p) => p['id'] == id);
      project['name'] = body['name'];
      if (body['color'] != null) project['color'] = body['color'];
      response = {'status': 'ok', 'project': project};
    } else if (method == 'DELETE' &&
        path.startsWith('/api/philobot/project/')) {
      final id = path.split('/')[4];
      projects.removeWhere((p) => p['id'] == id);
      for (final session in sessions) {
        if (session['project_id'] == id) session.remove('project_id');
      }
      response = {'status': 'deleted'};
    } else if (method == 'POST' && path == '/api/philobot/session') {
      _idCounter++;
      final session = {
        'session_id': 'chat-$_idCounter',
        'title': 'Chat $_idCounter',
        'project_id': body['project_id'],
        'message_count': 1,
        'updated_at': DateTime.now().toIso8601String(),
      };
      sessions.add(session);
      response = {'session_id': session['session_id'], 'status': 'created'};
    } else if (method == 'GET' && path == '/api/philobot/sessions') {
      response = {'sessions': sessions.reversed.toList()};
    } else if (method == 'POST' &&
        path.startsWith('/api/philobot/session/') &&
        path.endsWith('/project')) {
      final id = path.split('/')[4];
      final session = sessions.firstWhere((s) => s['session_id'] == id);
      if (body['project_id'] == null || body['project_id'] == '') {
        session.remove('project_id');
      } else {
        session['project_id'] = body['project_id'];
      }
      response = {'status': 'ok', 'session': session};
    } else if (method == 'DELETE' &&
        path.startsWith('/api/philobot/session/')) {
      final id = path.split('/')[4];
      sessions.removeWhere((s) => s['session_id'] == id);
      response = {'status': 'deleted'};
    } else if (method == 'POST' &&
        path.startsWith('/api/philobot/session/') &&
        path.endsWith('/rename')) {
      response = {'status': 'ok'};
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('not found');
      await request.response.close();
      return;
    }

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
    await request.response.close();
  }
}

void main() {
  late FakePhiloBotServer server;
  late ApiService api;
  late AppState appState;

  setUp(() async {
    server = FakePhiloBotServer();
    final port = await server.start();
    api = ApiService();
    api.baseUrl = 'http://127.0.0.1:$port/api';
    api.token = 'test-token';
    appState = AppState.test(api);
  });

  tearDown(() async {
    await server.stop();
  });

  Future<Map<String, dynamic>> waitForRequest(
    bool Function(Map<String, dynamic>) match,
  ) async {
    for (var i = 0; i < 100; i++) {
      final matches = server.requests.where(match);
      if (matches.isNotEmpty) return matches.last;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Erwarteter Request wurde nicht empfangen');
  }

  test('createChatProject legt Projekt an und speichert es lokal', () async {
    final project = await appState.createChatProject(
      'Arbeit',
      color: '#C9A24A',
    );

    expect(project, isNotNull);
    expect(project!.name, 'Arbeit');
    expect(project.color, '#C9A24A');
    expect(appState.chatProjects, hasLength(1));
    expect(appState.chatProjects.first.id, project.id);

    final request = server.requests.first;
    expect(request['method'], 'POST');
    expect(request['path'], '/api/philobot/project');
    expect(request['body'], {'name': 'Arbeit', 'color': '#C9A24A'});
  });

  test(
    'createNewChatSession mit Projekt sendet project_id und merkt Zuordnung',
    () async {
      final project = await appState.createChatProject('Projekt A');
      final sessionId = await appState.createNewChatSession(
        'local:instanz',
        projectId: project!.id,
      );

      expect(sessionId, isNotNull);
      expect(appState.projectIdForSession(sessionId!), project.id);

      final createRequest = server.requests.firstWhere(
        (r) => r['path'] == '/api/philobot/session',
      );
      expect(createRequest['body']['project_id'], project.id);
    },
  );

  test('assignSessionToProject verschiebt und loest Zuordnung', () async {
    final project = await appState.createChatProject('Projekt B');
    final sessionId = (await appState.createNewChatSession('local:x'))!;
    expect(appState.projectIdForSession(sessionId), isNull);

    await appState.assignSessionToProject(sessionId, project!.id);
    expect(appState.projectIdForSession(sessionId), project.id);

    var assignRequest = await waitForRequest(
      (r) => r['path'] == '/api/philobot/session/$sessionId/project',
    );
    expect(assignRequest['body'], {'project_id': project.id});

    await appState.assignSessionToProject(sessionId, null);
    expect(appState.projectIdForSession(sessionId), isNull);
    assignRequest = await waitForRequest(
      (r) =>
          r['path'] == '/api/philobot/session/$sessionId/project' &&
          r['body']['project_id'] == '',
    );
    expect(assignRequest['body'], {'project_id': ''});
  });

  test('restoreChatSessions laedt Projekte und Zuordnungen', () async {
    server.projects.add({
      'id': 'proj-9',
      'name': 'Alt',
      'color': '#4287f5',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    server.sessions.addAll([
      {
        'session_id': 'chat-a',
        'title': 'Zugeordnet',
        'project_id': 'proj-9',
        'message_count': 2,
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'session_id': 'chat-b',
        'title': 'Frei',
        'message_count': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
    ]);

    await appState.restoreChatSessions();

    expect(appState.chatProjects, hasLength(1));
    expect(appState.chatProjects.single.id, 'proj-9');
    expect(appState.chatProjects.single.name, 'Alt');
    expect(appState.projectIdForSession('chat-a'), 'proj-9');
    expect(appState.projectIdForSession('chat-b'), isNull);
    expect(appState.sessionsInProject('proj-9'), ['chat-a']);
  });

  test(
    'deleteChatProject entfernt Ordner und entknuepft lokale Chats',
    () async {
      final project = await appState.createChatProject('Weg damit');
      final sessionId = (await appState.createNewChatSession(
        'local:x',
        projectId: project!.id,
      ))!;
      expect(appState.projectIdForSession(sessionId), project.id);

      await appState.deleteChatProject(project.id);

      expect(appState.chatProjects, isEmpty);
      expect(appState.projectIdForSession(sessionId), isNull);
      expect(appState.chatSessions, contains(sessionId));

      final deleteRequest = await waitForRequest(
        (r) => r['method'] == 'DELETE' && r['path'].contains('/project/'),
      );
      expect(deleteRequest['path'], '/api/philobot/project/${project.id}');
    },
  );

  test('renameChatProject aktualisiert Namen und Farbe', () async {
    final project = await appState.createChatProject('Alt');
    await appState.renameChatProject(project!.id, 'Neu', color: '#00FF00');

    expect(appState.chatProjects.single.name, 'Neu');
    expect(appState.chatProjects.single.color, '#00FF00');
    final request = await waitForRequest((r) => r['path'].contains('/rename'));
    expect(request['path'], '/api/philobot/project/${project.id}/rename');
    expect(request['body'], {'name': 'Neu', 'color': '#00FF00', 'path': ''});
  });

  test(
    'renameChatProject kann einen Projektpfad setzen und wieder loeschen',
    () async {
      final project = await appState.createChatProject('Mit Pfad');
      await appState.renameChatProject(
        project!.id,
        'Mit Pfad',
        path: '/tmp/projekt',
      );
      expect(appState.chatProjects.single.path, '/tmp/projekt');
      var request = await waitForRequest((r) => r['path'].contains('/rename'));
      expect(request['body']['path'], '/tmp/projekt');

      await appState.renameChatProject(project.id, 'Mit Pfad');
      expect(appState.chatProjects.single.path, isNull);
      request = await waitForRequest(
        (r) =>
            r['path'].contains('/rename') && (r['body'] as Map)['path'] == '',
      );
      expect(request['body']['path'], '');
    },
  );

  test('deleteSession raeumt die Projekt-Zuordnung mit ab', () async {
    final project = await appState.createChatProject('P');
    final sessionId = (await appState.createNewChatSession(
      'local:x',
      projectId: project!.id,
    ))!;

    appState.deleteSession(sessionId);

    expect(appState.projectIdForSession(sessionId), isNull);
    expect(appState.sessionsInProject(project.id), isEmpty);
  });
}
