import 'package:grpc/grpc.dart';
import 'package:culpeo_studio/generated/culpeostudio/scout/v1/scout.pbgrpc.dart'
    as scoutpb;

/// Every method of the chat service, refusing by default. A test extends this
/// and overrides only the calls it drives, instead of restating the whole
/// service each time.
class ScoutServiceStub extends scoutpb.ScoutServiceBase {
  Never _unused(String method) => throw GrpcError.unimplemented(
    '$method wird in diesem Test nicht genutzt',
  );

  @override
  Future<scoutpb.CreateSessionResponse> createSession(
    ServiceCall call,
    scoutpb.CreateSessionRequest request,
  ) async => _unused('CreateSession');

  @override
  Future<scoutpb.ListSessionsResponse> listSessions(
    ServiceCall call,
    scoutpb.ListSessionsRequest request,
  ) async => _unused('ListSessions');

  @override
  Future<scoutpb.GetHistoryResponse> getHistory(
    ServiceCall call,
    scoutpb.GetHistoryRequest request,
  ) async => _unused('GetHistory');

  @override
  Future<scoutpb.RenameSessionResponse> renameSession(
    ServiceCall call,
    scoutpb.RenameSessionRequest request,
  ) async => _unused('RenameSession');

  @override
  Future<scoutpb.DeleteSessionResponse> deleteSession(
    ServiceCall call,
    scoutpb.DeleteSessionRequest request,
  ) async => _unused('DeleteSession');

  @override
  Future<scoutpb.SetSessionProjectResponse> setSessionProject(
    ServiceCall call,
    scoutpb.SetSessionProjectRequest request,
  ) async => _unused('SetSessionProject');

  @override
  Future<scoutpb.SetSessionModelResponse> setSessionModel(
    ServiceCall call,
    scoutpb.SetSessionModelRequest request,
  ) async => _unused('SetSessionModel');

  @override
  Future<scoutpb.GetSessionTreeResponse> getSessionTree(
    ServiceCall call,
    scoutpb.GetSessionTreeRequest request,
  ) async => _unused('GetSessionTree');

  @override
  Future<scoutpb.SendMessageResponse> sendMessage(
    ServiceCall call,
    scoutpb.SendMessageRequest request,
  ) async => _unused('SendMessage');

  @override
  Stream<scoutpb.StreamMessageResponse> streamMessage(
    ServiceCall call,
    scoutpb.StreamMessageRequest request,
  ) async* {
    _unused('StreamMessage');
  }

  @override
  Future<scoutpb.ListBotsResponse> listBots(
    ServiceCall call,
    scoutpb.ListBotsRequest request,
  ) async => _unused('ListBots');

  @override
  Future<scoutpb.SaveBotResponse> saveBot(
    ServiceCall call,
    scoutpb.SaveBotRequest request,
  ) async => _unused('SaveBot');

  @override
  Future<scoutpb.DeleteBotResponse> deleteBot(
    ServiceCall call,
    scoutpb.DeleteBotRequest request,
  ) async => _unused('DeleteBot');
}
