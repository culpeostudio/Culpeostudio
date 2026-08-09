import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:culpeo_studio/core/api_client.dart';
import 'package:culpeo_studio/core/api_service.dart';
import 'package:culpeo_studio/core/app_state.dart';
import 'package:culpeo_studio/generated/culpeostudio/scout/v1/scout.pbgrpc.dart'
    as scoutpb;
import 'package:culpeo_studio/generated/culpeostudio/spark/v1/spark.pbgrpc.dart'
    as sparkpb;

import 'scout_service_stub.dart';

/// Both modules are served over gRPC now, so the two fakes share one server
/// and one project list.
class FakeSparkService extends sparkpb.SparkServiceBase {
  FakeSparkService(this.projects, this.sessions);

  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> sessions;
  final List<String> calls = [];
  final List<sparkpb.RenameProjectRequest> renames = [];
  final List<String> deleted = [];
  int _idCounter = 0;

  sparkpb.Project _toProto(Map<String, dynamic> project) => sparkpb.Project(
    id: project['id'] as String,
    name: project['name'] as String? ?? '',
    color: project['color'] as String? ?? '',
  );

  @override
  Future<sparkpb.ListProjectsResponse> listProjects(
    ServiceCall call,
    sparkpb.ListProjectsRequest request,
  ) async {
    calls.add('list');
    return sparkpb.ListProjectsResponse(projects: projects.map(_toProto));
  }

  @override
  Future<sparkpb.CreateProjectResponse> createProject(
    ServiceCall call,
    sparkpb.CreateProjectRequest request,
  ) async {
    calls.add('create:${request.name}');
    _idCounter++;
    final project = <String, dynamic>{
      'id': 'proj-$_idCounter',
      'name': request.name,
      'color': request.color,
    };
    projects.add(project);
    return sparkpb.CreateProjectResponse(project: _toProto(project));
  }

  @override
  Future<sparkpb.RenameProjectResponse> renameProject(
    ServiceCall call,
    sparkpb.RenameProjectRequest request,
  ) async {
    calls.add('rename');
    renames.add(request);
    final project = projects.firstWhere((p) => p['id'] == request.id);
    project['name'] = request.name;
    if (request.color.isNotEmpty) project['color'] = request.color;
    return sparkpb.RenameProjectResponse(project: _toProto(project));
  }

  @override
  Future<sparkpb.DeleteProjectResponse> deleteProject(
    ServiceCall call,
    sparkpb.DeleteProjectRequest request,
  ) async {
    calls.add('delete');
    deleted.add(request.id);
    projects.removeWhere((p) => p['id'] == request.id);
    for (final session in sessions) {
      if (session['project_id'] == request.id) session.remove('project_id');
    }
    return sparkpb.DeleteProjectResponse();
  }

  @override
  Future<sparkpb.RespondToPermissionResponse> respondToPermission(
    ServiceCall call,
    sparkpb.RespondToPermissionRequest request,
  ) async => sparkpb.RespondToPermissionResponse();
}

class FakeScoutService extends ScoutServiceStub {
  final List<Map<String, dynamic>> projects = [];
  final List<Map<String, dynamic>> sessions = [];
  final List<scoutpb.CreateSessionRequest> created = [];
  final List<scoutpb.SetSessionProjectRequest> assigned = [];
  int _idCounter = 0;

  scoutpb.SessionSummary _toSummary(Map<String, dynamic> session) {
    return scoutpb.SessionSummary(
      sessionId: session['session_id'] as String,
      title: session['title'] as String? ?? '',
      projectId: session['project_id'] as String? ?? '',
      messageCount: session['message_count'] as int? ?? 0,
      updatedAt: Timestamp.fromDateTime(
        DateTime.tryParse(session['updated_at'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }

  @override
  Future<scoutpb.CreateSessionResponse> createSession(
    ServiceCall call,
    scoutpb.CreateSessionRequest request,
  ) async {
    created.add(request);
    _idCounter++;
    final session = <String, dynamic>{
      'session_id': 'chat-$_idCounter',
      'title': 'Chat $_idCounter',
      'project_id': request.projectId,
      'message_count': 1,
      'updated_at': DateTime.now().toIso8601String(),
    };
    sessions.add(session);
    return scoutpb.CreateSessionResponse(
      sessionId: session['session_id'] as String,
    );
  }

  @override
  Future<scoutpb.ListSessionsResponse> listSessions(
    ServiceCall call,
    scoutpb.ListSessionsRequest request,
  ) async {
    return scoutpb.ListSessionsResponse(
      sessions: sessions.reversed.map(_toSummary),
    );
  }

  @override
  Future<scoutpb.SetSessionProjectResponse> setSessionProject(
    ServiceCall call,
    scoutpb.SetSessionProjectRequest request,
  ) async {
    assigned.add(request);
    final session = sessions.firstWhere(
      (s) => s['session_id'] == request.sessionId,
    );
    session['project_id'] = request.projectId;
    return scoutpb.SetSessionProjectResponse(session: _toSummary(session));
  }

  @override
  Future<scoutpb.DeleteSessionResponse> deleteSession(
    ServiceCall call,
    scoutpb.DeleteSessionRequest request,
  ) async {
    sessions.removeWhere((s) => s['session_id'] == request.sessionId);
    return scoutpb.DeleteSessionResponse();
  }

  @override
  Future<scoutpb.RenameSessionResponse> renameSession(
    ServiceCall call,
    scoutpb.RenameSessionRequest request,
  ) async {
    final session = sessions.firstWhere(
      (s) => s['session_id'] == request.sessionId,
    );
    session['title'] = request.title;
    return scoutpb.RenameSessionResponse(session: _toSummary(session));
  }
}

void main() {
  late FakeScoutService server;
  late FakeSparkService spark;
  late Server backend;
  late ApiService api;
  late AppState appState;

  setUp(() async {
    server = FakeScoutService();
    spark = FakeSparkService(server.projects, server.sessions);
    backend = Server.create(services: [spark, server]);
    await backend.serve(address: '127.0.0.1', port: 0);

    // The suite shortens the deadline so unanswered calls do not linger; here
    // a backend answers, so give it room.
    ApiClient.callDeadline = requestTimeout;

    api = ApiService();
    api.token = 'test-token';
    api.client.grpcPort = backend.port!;
    appState = AppState.test(api);
  });

  tearDown(() async {
    ApiClient.callDeadline = const Duration(milliseconds: 1);
    await backend.shutdown();
  });

  /// Some calls are fire-and-forget, so wait for the recording instead of
  /// expecting it right away.
  Future<T> waitForCall<T>(T? Function() match) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      final found = match();
      if (found != null) return found;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Erwarteter Aufruf wurde nicht empfangen');
  }

  /// rename und delete laufen fire-and-forget, also auf die gRPC-Aufzeichnung
  /// warten statt sie sofort zu erwarten.
  Future<void> waitForSparkCall(bool Function() done) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (done()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Erwarteter Spark-Aufruf wurde nicht empfangen');
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

    expect(spark.calls, ['create:Arbeit']);
    expect(spark.projects.single['color'], '#C9A24A');
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

      expect(server.created.single.projectId, project.id);
    },
  );

  test('assignSessionToProject verschiebt und loest Zuordnung', () async {
    final project = await appState.createChatProject('Projekt B');
    final sessionId = (await appState.createNewChatSession('local:x'))!;
    expect(appState.projectIdForSession(sessionId), isNull);

    await appState.assignSessionToProject(sessionId, project!.id);
    expect(appState.projectIdForSession(sessionId), project.id);

    var assignRequest = await waitForCall(
      () => server.assigned
          .where((r) => r.sessionId == sessionId)
          .cast<scoutpb.SetSessionProjectRequest?>()
          .lastOrNull,
    );
    expect(assignRequest.projectId, project.id);

    await appState.assignSessionToProject(sessionId, null);
    expect(appState.projectIdForSession(sessionId), isNull);
    // Detaching sends the same call with an empty project, which is what the
    // backend reads as "no project".
    assignRequest = await waitForCall(
      () => server.assigned
          .where((r) => r.sessionId == sessionId && r.projectId.isEmpty)
          .cast<scoutpb.SetSessionProjectRequest?>()
          .lastOrNull,
    );
    expect(assignRequest.projectId, '');
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

      await waitForSparkCall(() => spark.deleted.contains(project.id));
    },
  );

  test('renameChatProject aktualisiert Namen und Farbe', () async {
    final project = await appState.createChatProject('Alt');
    await appState.renameChatProject(project!.id, 'Neu', color: '#00FF00');

    expect(appState.chatProjects.single.name, 'Neu');
    expect(appState.chatProjects.single.color, '#00FF00');
    await waitForSparkCall(() => spark.renames.isNotEmpty);
    expect(spark.renames, hasLength(1));
    expect(spark.renames.single.id, project.id);
    expect(spark.renames.single.name, 'Neu');
    expect(spark.renames.single.color, '#00FF00');
    expect(spark.renames.single.path, '');
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
      await waitForSparkCall(() => spark.renames.isNotEmpty);
      expect(spark.renames.last.path, '/tmp/projekt');

      await appState.renameChatProject(project.id, 'Mit Pfad');
      expect(appState.chatProjects.single.path, isNull);
      await waitForSparkCall(() => spark.renames.length > 1);
      expect(spark.renames.last.path, '');
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
