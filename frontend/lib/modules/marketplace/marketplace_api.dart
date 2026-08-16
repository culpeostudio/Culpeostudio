import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as tspb;

import '../../generated/culpeostudio/marketplace/v1/marketplace.pbgrpc.dart'
    as mppb;
import '../../core/api_client.dart';
import '../../core/hardware_profile_map.dart';

/// Modellsuche, Downloads und aktive API-Modelle.
///
/// The screens read plain maps, so every response is flattened back into the
/// shape the JSON API produced - including which keys stayed absent when a
/// value was zero, because the widgets fall through to their own defaults with
/// `??` and proto3 would hand them an empty string or a zero instead.
class MarketplaceApi {
  MarketplaceApi(this._c);

  final ApiClient _c;

  Future<Map<String, dynamic>> search({
    String? provider,
    String? query,
    String? format,
    String? quantization,
    String? category,
    String? sort,
    bool? gpuFit,
    bool? localOnly,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _c.marketplaceClient.searchModels(
        mppb.SearchModelsRequest(
          provider: _providerFromName(provider),
          query: query ?? '',
          format: format ?? '',
          quantization: quantization ?? '',
          category: _categoryFromName(category),
          sort: _sortFromName(sort),
          gpuFit: gpuFit ?? false,
          localOnly: localOnly ?? false,
          page: page ?? 0,
          pageSize: limit ?? 0,
        ),
      );
      return {
        'models': response.models.map(_summaryToMap).toList(),
        'total': response.total,
        'returned': response.returned,
        'partial': response.partial,
        'errors': response.errors.toList(),
        'page': response.page,
        'page_size': response.pageSize,
        'has_more': response.hasMore,
        'hardware': hardwareProfileToMap(response.hardware),
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getModelDetail(
    String id,
    String provider,
  ) async {
    try {
      final response = await _c.marketplaceClient.getModelDetail(
        mppb.GetModelDetailRequest(
          provider: _providerFromName(provider),
          id: id,
        ),
      );
      return _detailToMap(response.detail);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getHardwareProfile() async {
    try {
      final response = await _c.marketplaceClient.getHardwareProfile(
        mppb.GetHardwareProfileRequest(),
      );
      return hardwareProfileToMap(response.profile);
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> downloadModel(
    String provider,
    String modelId,
    String assetId,
    String targetDir, {
    List<String> assetIds = const [],
    int sizeBytes = 0,
    String nodeId = '',
  }) async {
    try {
      final response = await _c.marketplaceClient.startDownload(
        mppb.StartDownloadRequest(
          provider: _providerFromName(provider),
          modelId: modelId,
          assetId: assetId,
          assetIds: assetIds,
          targetDir: targetDir,
          sizeBytes: sizeBytes > 0 ? Int64(sizeBytes) : null,
          // Empty means this machine. A node id sends the job there, and the
          // node downloads from the model host itself.
          nodeId: nodeId,
        ),
      );
      return {
        'job_id': response.jobId,
        'status': _statusName(response.status),
        'existing': response.existing,
        'target_dir': response.targetDir,
      };
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> listDownloadJobs() async {
    try {
      final response = await _c.marketplaceClient.listDownloadJobs(
        mppb.ListDownloadJobsRequest(),
      );
      return {'jobs': response.jobs.map(_jobToMap).toList()};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteDownloadJob(String id) async {
    try {
      await _c.marketplaceClient.deleteDownloadJob(
        mppb.DeleteDownloadJobRequest(id: id),
      );
      return {'success': true};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> startAPIModelForChat(
    String provider,
    String modelId,
    String displayName,
  ) async {
    try {
      final response = await _c.marketplaceClient.startApiModel(
        mppb.StartApiModelRequest(
          provider: _providerFromName(provider),
          modelId: modelId,
          displayName: displayName,
        ),
      );
      return {'status': 'started', 'model': _activeModelToMap(response.model)};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> listActiveAPIModels() async {
    try {
      final response = await _c.marketplaceClient.listActiveApiModels(
        mppb.ListActiveApiModelsRequest(),
      );
      return {'models': response.models.map(_activeModelToMap).toList()};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteActiveAPIModel(String modelRef) async {
    try {
      await _c.marketplaceClient.deleteActiveApiModel(
        mppb.DeleteActiveApiModelRequest(modelRef: modelRef),
      );
      return {'success': true};
    } catch (e) {
      return {'error': _c.grpcErrorMessage(e)};
    }
  }

  static const Map<String, mppb.Provider> _providersByName = {
    'all': mppb.Provider.PROVIDER_ALL,
    'huggingface': mppb.Provider.PROVIDER_HUGGINGFACE,
    'openrouter': mppb.Provider.PROVIDER_OPENROUTER,
    'featherless': mppb.Provider.PROVIDER_FEATHERLESS,
  };

  /// An unset provider means "all", which is what the omitted query parameter
  /// used to mean. A name outside the enum is left unspecified so the backend
  /// answers with the same complaint it always did.
  mppb.Provider _providerFromName(String? provider) {
    final name = provider?.trim().toLowerCase() ?? '';
    if (name.isEmpty) return mppb.Provider.PROVIDER_ALL;
    return _providersByName[name] ?? mppb.Provider.PROVIDER_UNSPECIFIED;
  }

  String _providerName(mppb.Provider provider) {
    for (final entry in _providersByName.entries) {
      if (entry.value == provider) return entry.key;
    }
    return '';
  }

  static const Map<String, mppb.Category> _categoriesByName = {
    'chat': mppb.Category.CATEGORY_CHAT,
    'code': mppb.Category.CATEGORY_CODE,
    'reasoning': mppb.Category.CATEGORY_REASONING,
    'vision': mppb.Category.CATEGORY_VISION,
    'embedding': mppb.Category.CATEGORY_EMBEDDING,
  };

  mppb.Category _categoryFromName(String? category) {
    final name = category?.trim().toLowerCase() ?? '';
    return _categoriesByName[name] ?? mppb.Category.CATEGORY_UNSPECIFIED;
  }

  /// `intelligence_score` is what the sort dropdown carries; the rest match the
  /// enum names once lowercased.
  static const Map<String, mppb.SortMode> _sortModesByName = {
    'popularity': mppb.SortMode.SORT_MODE_POPULARITY,
    'intelligence': mppb.SortMode.SORT_MODE_INTELLIGENCE,
    'intelligence_score': mppb.SortMode.SORT_MODE_INTELLIGENCE,
    'context': mppb.SortMode.SORT_MODE_CONTEXT,
    'newest': mppb.SortMode.SORT_MODE_NEWEST,
    'price_low_high': mppb.SortMode.SORT_MODE_PRICE_LOW_HIGH,
    'price_high_low': mppb.SortMode.SORT_MODE_PRICE_HIGH_LOW,
  };

  mppb.SortMode _sortFromName(String? sort) {
    final name = sort?.trim().toLowerCase() ?? '';
    return _sortModesByName[name] ?? mppb.SortMode.SORT_MODE_UNSPECIFIED;
  }

  static const Map<mppb.DownloadStatus, String> _statusNames = {
    mppb.DownloadStatus.DOWNLOAD_STATUS_QUEUED: 'queued',
    mppb.DownloadStatus.DOWNLOAD_STATUS_RUNNING: 'running',
    mppb.DownloadStatus.DOWNLOAD_STATUS_DONE: 'done',
    mppb.DownloadStatus.DOWNLOAD_STATUS_FAILED: 'failed',
  };

  String _statusName(mppb.DownloadStatus status) => _statusNames[status] ?? '';

  Map<String, dynamic> _summaryToMap(mppb.ModelSummary model) {
    return {
      'id': model.id,
      'provider': _providerName(model.provider),
      'model_id': model.modelId,
      'display_name': model.displayName,
      'name': model.name,
      if (model.description.isNotEmpty) 'description': model.description,
      if (model.format.isNotEmpty) 'format': model.format,
      if (model.formats.isNotEmpty) 'formats': model.formats.toList(),
      if (model.quantizations.isNotEmpty)
        'quantizations': model.quantizations.toList(),
      if (model.author.isNotEmpty) 'author': model.author,
      if (model.downloads != 0) 'downloads': model.downloads.toInt(),
      if (model.sizeBytes != 0) 'size_bytes': model.sizeBytes.toInt(),
      if (model.parameterBadge.isNotEmpty)
        'parameter_badge': model.parameterBadge,
      if (model.parameterCountB != 0)
        'parameter_count_b': model.parameterCountB,
      if (model.providerBadge.isNotEmpty) 'provider_badge': model.providerBadge,
      if (model.category.isNotEmpty) 'category': model.category,
      if (model.capabilityTags.isNotEmpty)
        'capability_tags': model.capabilityTags.toList(),
      if (model.pricePer1m.isNotEmpty) 'price_per_1m': model.pricePer1m,
      if (model.pricePer1mInput != 0)
        'price_per_1m_input': model.pricePer1mInput,
      if (model.pricePer1mOutput != 0)
        'price_per_1m_output': model.pricePer1mOutput,
      if (model.contextLength != 0) 'context_length': model.contextLength,
      if (model.intelligenceScore != 0)
        'intelligence_score': model.intelligenceScore,
      if (model.estimatedVramGb != 0)
        'estimated_vram_gb': model.estimatedVramGb,
      if (model.vramEstimated) 'vram_estimated': model.vramEstimated,
      'fits_detected_gpu': model.fitsDetectedGpu,
      if (model.runtimeFit.isNotEmpty) 'runtime_fit': model.runtimeFit,
      if (model.runtimeWarnings.isNotEmpty)
        'runtime_warnings': model.runtimeWarnings.toList(),
      if (model.runtimeRamOffloadGb != 0)
        'runtime_ram_offload_gb': model.runtimeRamOffloadGb,
      if (model.recommendationScore != 0)
        'recommendation_score': model.recommendationScore,
      'local_model': model.localModel,
      if (model.newScore != 0) 'new_score': model.newScore.toInt(),
      if (model.downloadOptions.isNotEmpty)
        'download_options': model.downloadOptions.map(_optionToMap).toList(),
    };
  }

  Map<String, dynamic> _optionToMap(mppb.DownloadOption option) {
    return {
      'label': option.label,
      if (option.assetId.isNotEmpty) 'asset_id': option.assetId,
      if (option.assetIds.isNotEmpty) 'asset_ids': option.assetIds.toList(),
      if (option.format.isNotEmpty) 'format': option.format,
      if (option.sizeBytes != 0) 'size_bytes': option.sizeBytes.toInt(),
      if (option.url.isNotEmpty) 'url': option.url,
    };
  }

  /// The detail dialog reads the model's fields straight off the map, so the
  /// nested summary is flattened back the way the embedded Go struct was.
  Map<String, dynamic> _detailToMap(mppb.ModelDetail detail) {
    return {
      ..._summaryToMap(detail.summary),
      if (detail.tags.isNotEmpty) 'tags': detail.tags.toList(),
      if (detail.metadata.isNotEmpty)
        'metadata': Map<String, String>.from(detail.metadata),
    };
  }

  Map<String, dynamic> _jobToMap(mppb.DownloadJob job) {
    return {
      'id': job.id,
      'provider': _providerName(job.provider),
      'model_id': job.modelId,
      if (job.assetId.isNotEmpty) 'asset_id': job.assetId,
      if (job.assetIds.isNotEmpty) 'asset_ids': job.assetIds.toList(),
      if (job.revision.isNotEmpty) 'revision': job.revision,
      if (job.commitSha.isNotEmpty) 'commit_sha': job.commitSha,
      'target_dir': job.targetDir,
      'status': _statusName(job.status),
      'progress': job.progress,
      if (job.error.isNotEmpty) 'error': job.error,
      if (job.outputPath.isNotEmpty) 'output_path': job.outputPath,
      if (job.hasCreatedAt()) 'created_at': _timestampToIso(job.createdAt),
      if (job.hasUpdatedAt()) 'updated_at': _timestampToIso(job.updatedAt),
      if (job.hasStartedAt()) 'started_at': _timestampToIso(job.startedAt),
      if (job.hasFinishedAt()) 'finished_at': _timestampToIso(job.finishedAt),
      if (job.downloadedBytes != 0)
        'downloaded_bytes': job.downloadedBytes.toInt(),
      if (job.speedBytesPerSec != 0)
        'speed_bytes_per_sec': job.speedBytesPerSec.toInt(),
      if (job.totalBytes != 0) 'total_bytes': job.totalBytes.toInt(),
      if (job.nodeId.isNotEmpty) 'node_id': job.nodeId,
      if (job.nodeName.isNotEmpty) 'node_name': job.nodeName,
    };
  }

  Map<String, dynamic> _activeModelToMap(mppb.ActiveApiModel model) {
    return {
      'provider': _providerName(model.provider),
      'model_id': model.modelId,
      'display_name': model.displayName,
      'model_ref': model.modelRef,
      if (model.hasStartedAt()) 'started_at': _timestampToIso(model.startedAt),
      if (model.hasLastUsedAt())
        'last_used_at': _timestampToIso(model.lastUsedAt),
    };
  }

  String _timestampToIso(tspb.Timestamp value) =>
      value.toDateTime().toIso8601String();
}
