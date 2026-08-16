import 'dart:async';

import 'package:grpc/grpc.dart';

import '../../generated/culpeostudio/scout/v1/scout.pbgrpc.dart' as scpb;
import '../../core/api_client.dart';
import '../../core/remaining_ui_strings.dart';

/// Chat mit Scout: Sitzungen, Verlauf, Streaming und Bots.
///
/// The screens read plain maps, so every response is flattened back into the
/// shape the JSON API produced.
class ScoutApi {
  ScoutApi(this._c);

  final ApiClient _c;

  Future<Map<String, dynamic>> createSession({
    String? modelRef,
    String? provider,
    String? modelId,
    String? instanceId,
    String? thinkingLevel,
    String? responseStyle,
    String? botId,
    String? projectId,
    String? connectionId,
  }) async {
    try {
      final response = await _c.scoutClient.createSession(
        scpb.CreateSessionRequest(
          modelRef: modelRef?.trim() ?? '',
          provider: provider?.trim() ?? '',
          modelId: modelId?.trim() ?? '',
          instanceId: instanceId?.trim() ?? '',
          botId: botId?.trim() ?? '',
          thinkingLevel: thinkingLevel?.trim() ?? '',
          responseStyle: responseStyle?.trim() ?? '',
          projectId: projectId?.trim() ?? '',
          connectionId: connectionId?.trim() ?? '',
        ),
      );
      return {
        'session_id': response.sessionId,
        'model_ref': response.modelRef,
        'provider': response.provider,
        'model_id': response.modelId,
        'display_name': response.displayName,
        'thinking': response.thinking,
        'style': response.style,
        if (response.connectionId.isNotEmpty)
          'connection_id': response.connectionId,
        if (response.lockedBotId.isNotEmpty) 'bot_id': response.botId,
        if (response.lockedBotId.isNotEmpty) 'bot_name': response.botName,
        if (response.lockedBotId.isNotEmpty)
          'locked_bot_id': response.lockedBotId,
        if (response.instanceId.isNotEmpty) 'instance_id': response.instanceId,
        if (response.instanceId.isNotEmpty)
          'context_limit': response.contextLimit,
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> setSessionModel(
    String sessionId, {
    required String provider,
    required String modelId,
    String? modelRef,
    String? displayName,
    String? connectionId,
  }) async {
    try {
      final response = await _c.scoutClient.setSessionModel(
        scpb.SetSessionModelRequest(
          sessionId: sessionId,
          provider: provider,
          modelId: modelId,
          modelRef: modelRef ?? '',
          displayName: displayName ?? '',
          connectionId: connectionId?.trim() ?? '',
        ),
      );
      return {'status': 'ok', 'session': _summaryToMap(response.session)};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    String sessionId,
    String message, {
    String? thinkingLevel,
    String? responseStyle,
    int? editMessageIndex,
    String? reasoningEffort,
    String? outputLevel,
  }) async {
    try {
      final response = await _c.scoutClient.sendMessage(
        scpb.SendMessageRequest(
          sessionId: sessionId,
          message: message,
          options: _options(
            thinkingLevel: thinkingLevel,
            responseStyle: responseStyle,
            editMessageIndex: editMessageIndex,
            reasoningEffort: reasoningEffort,
            outputLevel: outputLevel,
          ),
        ),
      );
      return {
        'session_id': response.sessionId,
        'reply': response.reply,
        'bot_id': response.botId,
        'bot_name': response.botName,
        'thinking_level': response.thinkingLevel,
        'response_style': response.responseStyle,
        'status': 'ok',
        if (response.hasCreatedBot())
          'created_bot': _botToMap(response.createdBot),
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getHistory(String sessionId) async {
    try {
      final response = await _c.scoutClient.getHistory(
        scpb.GetHistoryRequest(sessionId: sessionId),
      );
      return {
        'session_id': response.sessionId,
        'provider': response.provider,
        'model_id': response.modelId,
        'model_ref': response.modelRef,
        'display_name': response.displayName,
        if (response.connectionId.isNotEmpty)
          'connection_id': response.connectionId,
        'context_limit': response.contextLimit,
        if (response.hasContextUsage())
          'context_usage': _contextUsageToMap(response.contextUsage),
        'locked_bot_id': response.lockedBotId,
        'active_bot_id': response.activeBotId,
        'messages': response.messages
            .map(
              (message) => {
                'role': message.role,
                'content': message.content,
                'bot_id': message.botId,
                'bot_name': message.botName,
              },
            )
            .toList(),
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  /// The streamed reply. The events arrive typed and are flattened back into
  /// the {type, data} pairs the chat screen dispatches on, so what used to be
  /// hand-written Server-Sent Events is now a server-streaming call.
  Stream<ScoutStreamEvent> streamMessage(
    String sessionId,
    String message, {
    String? thinkingLevel,
    String? responseStyle,
    int? editMessageIndex,
    String? mode,
    List<String>? allowedRoots,
    bool? approvePlan,
    bool? planning,
    String? reasoningEffort,
    String? outputLevel,
  }) async* {
    final request = scpb.StreamMessageRequest(
      sessionId: sessionId,
      message: message,
      options: _options(
        thinkingLevel: thinkingLevel,
        responseStyle: responseStyle,
        editMessageIndex: editMessageIndex,
        mode: mode,
        allowedRoots: allowedRoots,
        approvePlan: approvePlan,
        planning: planning,
        reasoningEffort: reasoningEffort,
        outputLevel: outputLevel,
      ),
    );

    try {
      // The deadline-free client, not scoutClient: per-call options cannot
      // clear a client's timeout, they only override a set one.
      await for (final event in _c.scoutStreamClient.streamMessage(request)) {
        final converted = _eventToStreamEvent(event);
        if (converted != null) yield converted;
      }
    } catch (e) {
      // A streaming call cannot be watched from an interceptor without
      // consuming it, so an expired session is reported from here.
      _c.reportGrpcError(e);
      yield ScoutStreamEvent(
        type: 'error',
        data: {
          'message': e is GrpcError
              ? _c.grpcErrorMessage(e)
              : remainingUiText('api.streamFailed'),
          if (e is GrpcError) 'code': e.codeName,
        },
      );
    }
  }

  Future<Map<String, dynamic>> getBots() async {
    try {
      final response = await _c.scoutClient.listBots(scpb.ListBotsRequest());
      return {'bots': response.bots.map(_botToMap).toList()};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> listReasoningProfiles() async {
    try {
      final response = await _c.scoutClient.listReasoningProfiles(
        scpb.ListReasoningProfilesRequest(),
      );
      return {
        'profiles': response.profiles
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'mandatory': p.mandatory,
                'default_enabled': p.defaultEnabled,
                'supported_efforts': p.supportedEfforts.toList(),
                'default_effort': p.defaultEffort,
                'context_length': p.contextLength,
              },
            )
            .toList(),
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> saveBot(Map<String, dynamic> bot) async {
    try {
      final response = await _c.scoutClient.saveBot(
        scpb.SaveBotRequest(bot: _botFromMap(bot)),
      );
      return {'status': 'ok', 'bot': _botToMap(response.bot)};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteBot(String id) async {
    try {
      await _c.scoutClient.deleteBot(scpb.DeleteBotRequest(id: id));
      return {'status': 'ok'};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> listSessions() async {
    try {
      final response = await _c.scoutClient.listSessions(
        scpb.ListSessionsRequest(),
      );
      return {'sessions': response.sessions.map(_summaryToMap).toList()};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteSession(String sessionId) async {
    try {
      await _c.scoutClient.deleteSession(
        scpb.DeleteSessionRequest(sessionId: sessionId),
      );
      return {'status': 'deleted'};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> renameSession(
    String sessionId,
    String title,
  ) async {
    try {
      final response = await _c.scoutClient.renameSession(
        scpb.RenameSessionRequest(sessionId: sessionId, title: title),
      );
      return {'status': 'ok', 'session': _summaryToMap(response.session)};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> setSessionProject(
    String sessionId,
    String? projectId,
  ) async {
    try {
      final response = await _c.scoutClient.setSessionProject(
        scpb.SetSessionProjectRequest(
          sessionId: sessionId,
          projectId: projectId ?? '',
        ),
      );
      return {'status': 'ok', 'session': _summaryToMap(response.session)};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getSessionTree(String sessionId) async {
    try {
      final response = await _c.scoutClient.getSessionTree(
        scpb.GetSessionTreeRequest(sessionId: sessionId),
      );
      return {
        'root': response.root,
        'tree': response.hasTree() ? _fileNodeToMap(response.tree) : null,
        'truncated': response.truncated,
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  /// Only sends the knobs the caller actually set, so an omitted one still
  /// lands on the backend's default - notably edit_message_index, where index
  /// zero has to stay distinguishable from "not editing".
  scpb.ChatOptions _options({
    String? thinkingLevel,
    String? responseStyle,
    int? editMessageIndex,
    String? mode,
    List<String>? allowedRoots,
    bool? approvePlan,
    bool? planning,
    String? reasoningEffort,
    String? outputLevel,
  }) {
    final options = scpb.ChatOptions();
    if (thinkingLevel != null && thinkingLevel.trim().isNotEmpty) {
      options.thinkingLevel = thinkingLevel.trim();
    }
    if (responseStyle != null && responseStyle.trim().isNotEmpty) {
      options.responseStyle = responseStyle.trim();
    }
    if (editMessageIndex != null) options.editMessageIndex = editMessageIndex;
    if (mode != null && mode.trim().isNotEmpty) options.mode = mode.trim();
    if (allowedRoots != null) options.allowedRoots.addAll(allowedRoots);
    if (approvePlan != null) options.approvePlan = approvePlan;
    if (planning != null) options.planning = planning;
    if (reasoningEffort != null && reasoningEffort.trim().isNotEmpty) {
      options.reasoningEffort = reasoningEffort.trim();
    }
    if (outputLevel != null && outputLevel.trim().isNotEmpty) {
      options.outputLevel = outputLevel.trim();
    }
    return options;
  }

  ScoutStreamEvent? _eventToStreamEvent(scpb.StreamMessageResponse event) {
    switch (event.whichEvent()) {
      case scpb.StreamMessageResponse_Event.textDelta:
        return ScoutStreamEvent(
          type: 'text_delta',
          data: {'chunk': event.textDelta.chunk},
        );
      case scpb.StreamMessageResponse_Event.reasoningDelta:
        return ScoutStreamEvent(
          type: 'reasoning_delta',
          data: {'chunk': event.reasoningDelta.chunk},
        );
      case scpb.StreamMessageResponse_Event.botSelected:
        return ScoutStreamEvent(
          type: 'bot_selected',
          data: {'id': event.botSelected.id, 'name': event.botSelected.name},
        );
      case scpb.StreamMessageResponse_Event.botCreated:
        return ScoutStreamEvent(
          type: 'bot_created',
          data: {'bot': _botToMap(event.botCreated.bot)},
        );
      case scpb.StreamMessageResponse_Event.status:
        return ScoutStreamEvent(
          type: 'status',
          data: {'action': event.status.action},
        );
      case scpb.StreamMessageResponse_Event.modelWarmup:
        return ScoutStreamEvent(
          type: 'model_warmup',
          data: _warmupToMap(event.modelWarmup),
        );
      case scpb.StreamMessageResponse_Event.contextUsage:
        return ScoutStreamEvent(
          type: 'context_usage',
          data: _contextUsageToMap(event.contextUsage),
        );
      case scpb.StreamMessageResponse_Event.done:
        return ScoutStreamEvent(
          type: 'done',
          data: {
            'session_id': event.done.sessionId,
            'thinking_level': event.done.thinkingLevel,
            'response_style': event.done.responseStyle,
          },
        );
      case scpb.StreamMessageResponse_Event.error:
        return ScoutStreamEvent(
          type: 'error',
          data: {
            'message': event.error.message,
            'code': event.error.code,
            if (event.error.retryAfter != 0)
              'retry_after': event.error.retryAfter,
          },
        );
      case scpb.StreamMessageResponse_Event.agent:
        // What the agent loop reports keeps its own type and payload, which
        // the screen stores next to the message as an opaque record.
        return ScoutStreamEvent(
          type: event.agent.type,
          data: event.agent.hasData()
              ? Map<String, dynamic>.from(
                  event.agent.data.toProto3Json() as Map,
                )
              : <String, dynamic>{},
        );
      case scpb.StreamMessageResponse_Event.notSet:
        return null;
    }
  }

  Map<String, dynamic> _contextUsageToMap(scpb.ContextUsage usage) {
    return {
      'limit_tokens': usage.limitTokens,
      'used_tokens': usage.usedTokens,
      'source': usage.source,
      'model_limit_tokens': usage.modelLimitTokens,
      'compactions': usage.compactions,
      'compacted': usage.compacted,
    };
  }

  Map<String, dynamic> _warmupToMap(scpb.ModelWarmup warmup) {
    return {
      if (warmup.operationId.isNotEmpty) 'operation_id': warmup.operationId,
      'instance_id': warmup.instanceId,
      'status': warmup.status,
      'phase': warmup.phase,
      'progress': warmup.progress,
      if (warmup.queuePosition != 0) 'queue_position': warmup.queuePosition,
      if (warmup.placement.isNotEmpty) 'placement': warmup.placement,
      if (warmup.message.isNotEmpty) 'message': warmup.message,
    };
  }

  Map<String, dynamic> _summaryToMap(scpb.SessionSummary summary) {
    return {
      'session_id': summary.sessionId,
      'title': summary.title,
      'preview': summary.preview,
      'provider': summary.provider,
      'model_id': summary.modelId,
      'display_name': summary.displayName,
      if (summary.connectionId.isNotEmpty)
        'connection_id': summary.connectionId,
      if (summary.lockedBotId.isNotEmpty) 'locked_bot_id': summary.lockedBotId,
      if (summary.projectId.isNotEmpty) 'project_id': summary.projectId,
      'message_count': summary.messageCount,
      if (summary.hasUpdatedAt())
        'updated_at': summary.updatedAt.toDateTime().toIso8601String(),
    };
  }

  Map<String, dynamic> _botToMap(scpb.Bot bot) {
    return {
      'id': bot.id,
      'name': bot.name,
      'system_prompt': bot.systemPrompt,
      'keywords': bot.keywords.toList(),
      'response_style': bot.responseStyle,
      'agentic_enabled': bot.agenticEnabled,
      'allowed_roots': bot.allowedRoots.toList(),
      'is_default': bot.isDefault,
      if (bot.hasModelBinding())
        'model_binding': {
          'kind': bot.modelBinding.kind,
          'model_ref': bot.modelBinding.modelRef,
          'provider': bot.modelBinding.provider,
          'model_id': bot.modelBinding.modelId,
          'instance_id': bot.modelBinding.instanceId,
          if (bot.modelBinding.connectionId.isNotEmpty)
            'connection_id': bot.modelBinding.connectionId,
          'display_name': bot.modelBinding.displayName,
        },
    };
  }

  scpb.Bot _botFromMap(Map<String, dynamic> bot) {
    final message = scpb.Bot(
      id: bot['id']?.toString() ?? '',
      name: bot['name']?.toString() ?? '',
      systemPrompt: bot['system_prompt']?.toString() ?? '',
      keywords: _stringList(bot['keywords']),
      responseStyle: bot['response_style']?.toString() ?? '',
      agenticEnabled: bot['agentic_enabled'] == true,
      allowedRoots: _stringList(bot['allowed_roots']),
      isDefault: bot['is_default'] == true,
    );

    final binding = bot['model_binding'];
    if (binding is Map) {
      message.modelBinding = scpb.ModelBinding(
        kind: binding['kind']?.toString() ?? '',
        modelRef: binding['model_ref']?.toString() ?? '',
        provider: binding['provider']?.toString() ?? '',
        modelId: binding['model_id']?.toString() ?? '',
        instanceId: binding['instance_id']?.toString() ?? '',
        displayName: binding['display_name']?.toString() ?? '',
        connectionId: binding['connection_id']?.toString() ?? '',
      );
    }
    return message;
  }

  Map<String, dynamic> _fileNodeToMap(scpb.FileNode node) {
    return {
      'name': node.name,
      'path': node.path,
      'is_dir': node.isDir,
      if (node.children.isNotEmpty)
        'children': node.children.map(_fileNodeToMap).toList(),
    };
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
