import '../../generated/culpeostudio/spark/v1/spark.pbgrpc.dart' as sparkpb;
import '../../core/api_client.dart';

/// Der Agent Spark: Projekte und die Freigabe von Zugriffen.
class SparkApi {
  SparkApi(this._c);

  final ApiClient _c;

  Future<Map<String, dynamic>> listProjects() async {
    try {
      final response = await _c.sparkClient.listProjects(
        sparkpb.ListProjectsRequest(),
      );
      return {'projects': response.projects.map(_projectToMap).toList()};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> createProject(
    String name, {
    String? color,
    String? path,
    String? icon,
  }) async {
    try {
      final request = sparkpb.CreateProjectRequest(name: name);
      if (color != null && color.trim().isNotEmpty) {
        request.color = color.trim();
      }
      if (path != null && path.trim().isNotEmpty) {
        request.path = path.trim();
      }
      if (icon != null && icon.trim().isNotEmpty) {
        request.icon = icon.trim();
      }

      final response = await _c.sparkClient.createProject(request);
      return {'status': 'created', 'project': _projectToMap(response.project)};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> renameProject(
    String projectId,
    String name, {
    String? color,
    String? path,
    String? icon,
  }) async {
    try {
      final request = sparkpb.RenameProjectRequest(id: projectId, name: name);
      if (color != null && color.trim().isNotEmpty) {
        request.color = color.trim();
      }
      request.path = path?.trim() ?? '';
      // Only assign when the caller passed one: leaving the field out keeps
      // the current icon, an empty string clears it.
      if (icon != null) {
        request.icon = icon.trim();
      }

      final response = await _c.sparkClient.renameProject(request);
      return {'status': 'renamed', 'project': _projectToMap(response.project)};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteProject(String projectId) async {
    try {
      await _c.sparkClient.deleteProject(
        sparkpb.DeleteProjectRequest(id: projectId),
      );
      return {'status': 'deleted'};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<bool> respondPermission({
    required String sessionId,
    required String requestId,
    required String decision,
  }) async {
    try {
      await _c.sparkClient.respondToPermission(
        sparkpb.RespondToPermissionRequest(
          sessionId: sessionId,
          requestId: requestId,
          decision: decision,
        ),
      );
      return true;
    } catch (_) {
      // An unknown or already-answered request is not an error worth
      // surfacing; the caller only wants to know whether it landed.
      return false;
    }
  }

  Map<String, dynamic> _projectToMap(sparkpb.Project project) {
    return {
      'id': project.id,
      'user_id': project.userId,
      'name': project.name,
      if (project.color.isNotEmpty) 'color': project.color,
      if (project.path.isNotEmpty) 'path': project.path,
      if (project.icon.isNotEmpty) 'icon': project.icon,
      'created_at': project.createdAt.toDateTime().toIso8601String(),
      'updated_at': project.updatedAt.toDateTime().toIso8601String(),
    };
  }
}
