import '../../generated/culpeostudio/settings/v1/settings.pbgrpc.dart' as setpb;
import '../../generated/culpeostudio/skills/v1/skills.pbgrpc.dart' as pb;
import '../../core/api_client.dart';
import '../../core/hardware_profile_map.dart';

/// Studio-Einstellungen, Systeminfos und Skills.
class SettingsApi {
  SettingsApi(this._c);

  final ApiClient _c;

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _c.settingsClient.getSettings(
        setpb.GetSettingsRequest(),
      );
      return _settingsToMap(response.settings);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    String? modelDir,
    String? huggingfaceToken,
    String? openrouterToken,
    String? featherlessToken,
    Map<String, String>? shortcuts,
  }) async {
    try {
      // An omitted field is left untouched by the backend, so only assign
      // what the caller actually passed.
      final request = setpb.UpdateSettingsRequest();
      if (modelDir != null) request.modelDir = modelDir;
      if (huggingfaceToken != null) request.huggingfaceToken = huggingfaceToken;
      if (openrouterToken != null) request.openrouterToken = openrouterToken;
      if (featherlessToken != null) request.featherlessToken = featherlessToken;
      if (shortcuts != null) request.shortcuts.addAll(shortcuts);

      final response = await _c.settingsClient.updateSettings(request);
      return {
        ..._settingsToMap(response.settings),
        'message': response.message,
        if (response.warnings.isNotEmpty)
          'warnings': response.warnings.toList(),
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final response = await _c.settingsClient.getSystemInfo(
        setpb.GetSystemInfoRequest(),
      );
      return hardwareProfileToMap(response.profile);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> testProviderConnection(String provider) async {
    final requested = _providerFromName(provider);
    if (requested == setpb.Provider.PROVIDER_UNSPECIFIED) {
      return {'error': 'Ungültiger Provider', 'provider': provider};
    }
    try {
      final response = await _c.settingsClient.testProvider(
        setpb.TestProviderRequest(provider: requested),
      );
      return {
        'provider': _providerName(response.provider),
        'reachable': response.reachable,
        'message': response.message,
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  static const Map<String, setpb.Provider> _providersByName = {
    'huggingface': setpb.Provider.PROVIDER_HUGGINGFACE,
    'openrouter': setpb.Provider.PROVIDER_OPENROUTER,
    'featherless': setpb.Provider.PROVIDER_FEATHERLESS,
  };

  setpb.Provider _providerFromName(String provider) =>
      _providersByName[provider] ?? setpb.Provider.PROVIDER_UNSPECIFIED;

  String _providerName(setpb.Provider provider) {
    for (final entry in _providersByName.entries) {
      if (entry.value == provider) return entry.key;
    }
    return '';
  }

  Map<String, dynamic> _settingsToMap(setpb.Settings settings) {
    return {
      'model_dir': settings.modelDir,
      'model_dir_valid': settings.modelDirValid,
      'model_dir_error': settings.modelDirError,
      'huggingface_token_set': settings.huggingfaceTokenSet,
      'openrouter_token_set': settings.openrouterTokenSet,
      'featherless_token_set': settings.featherlessTokenSet,
      'shortcuts': Map<String, String>.from(settings.shortcuts),
      if (settings.hasEngineRamReserveBytes())
        'engine_ram_reserve_bytes': settings.engineRamReserveBytes.toInt(),
      if (settings.hasEngineGpuReserveBytes())
        'engine_gpu_reserve_bytes': settings.engineGpuReserveBytes.toInt(),
    };
  }

  Future<Map<String, dynamic>> listSkills() async {
    try {
      final response = await _c.skillsClient.listSkills(pb.ListSkillsRequest());
      return _skillListToMap(response.skills, response.count);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> importSkill(
    String sourcePath, {
    bool enabled = true,
  }) async {
    try {
      final response = await _c.skillsClient.importSkill(
        pb.ImportSkillRequest(sourcePath: sourcePath, enabled: enabled),
      );
      return _skillResponseToMap(response.skill, response.message);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateSkill(
    String name, {
    required bool enabled,
  }) async {
    try {
      final response = await _c.skillsClient.updateSkill(
        pb.UpdateSkillRequest(name: name, enabled: enabled),
      );
      return _skillResponseToMap(response.skill, response.message);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteSkill(String name) async {
    try {
      final response = await _c.skillsClient.deleteSkill(
        pb.DeleteSkillRequest(name: name),
      );
      return {
        'name': response.name,
        'status': response.status,
        'message': response.message,
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> rescanSkills() async {
    try {
      final response = await _c.skillsClient.rescanSkills(
        pb.RescanSkillsRequest(),
      );
      return _skillListToMap(response.skills, response.count);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Map<String, dynamic> _skillListToMap(List<pb.SkillRecord> skills, int count) {
    return {'skills': skills.map(_skillRecordToMap).toList(), 'count': count};
  }

  Map<String, dynamic> _skillResponseToMap(
    pb.SkillRecord skill,
    String message,
  ) {
    return {'skill': _skillRecordToMap(skill), 'message': message};
  }

  Map<String, dynamic> _skillRecordToMap(pb.SkillRecord skill) {
    final summary = skill.hasFileSummary()
        ? skill.fileSummary
        : pb.SkillFileSummary();
    return {
      'name': skill.name,
      'description': skill.description,
      'enabled': skill.enabled,
      'path': skill.path,
      'imported_at_unix': skill.importedAtUnix.toInt(),
      'updated_at_unix': skill.updatedAtUnix.toInt(),
      'license': skill.license,
      'compatibility': skill.compatibility,
      'metadata_json': skill.metadataJson,
      'allowed_tools': skill.allowedTools,
      'valid': skill.valid,
      'errors': skill.errors.toList(),
      'file_summary': {
        'file_count': summary.fileCount,
        'directory_count': summary.directoryCount,
        'has_scripts': summary.hasScripts,
        'has_references': summary.hasReferences,
        'has_assets': summary.hasAssets,
      },
    };
  }
}
