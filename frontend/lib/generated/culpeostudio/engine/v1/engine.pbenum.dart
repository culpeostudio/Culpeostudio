// This is a generated file - do not edit.
//
// Generated from culpeostudio/engine/v1/engine.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// RuntimeKind names an inference runtime. RUNTIME_KIND_AUTO is only meaningful
/// in a config, where it asks the engine to pick; an instance that is running
/// reports the runtime it actually got.
class RuntimeKind extends $pb.ProtobufEnum {
  static const RuntimeKind RUNTIME_KIND_UNSPECIFIED =
      RuntimeKind._(0, _omitEnumNames ? '' : 'RUNTIME_KIND_UNSPECIFIED');
  static const RuntimeKind RUNTIME_KIND_AUTO =
      RuntimeKind._(1, _omitEnumNames ? '' : 'RUNTIME_KIND_AUTO');
  static const RuntimeKind RUNTIME_KIND_LLAMA_CPP =
      RuntimeKind._(2, _omitEnumNames ? '' : 'RUNTIME_KIND_LLAMA_CPP');

  static const $core.List<RuntimeKind> values = <RuntimeKind>[
    RUNTIME_KIND_UNSPECIFIED,
    RUNTIME_KIND_AUTO,
    RUNTIME_KIND_LLAMA_CPP,
  ];

  static final $core.List<RuntimeKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static RuntimeKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RuntimeKind._(super.value, super.name);
}

/// ContextMode decides how the context window is sized. The HTTP API took it as
/// a string and rejected anything but these two after the fact.
class ContextMode extends $pb.ProtobufEnum {
  /// Unset means auto_max, which is what an omitted field meant.
  static const ContextMode CONTEXT_MODE_UNSPECIFIED =
      ContextMode._(0, _omitEnumNames ? '' : 'CONTEXT_MODE_UNSPECIFIED');
  static const ContextMode CONTEXT_MODE_AUTO_MAX =
      ContextMode._(1, _omitEnumNames ? '' : 'CONTEXT_MODE_AUTO_MAX');
  static const ContextMode CONTEXT_MODE_FIXED =
      ContextMode._(2, _omitEnumNames ? '' : 'CONTEXT_MODE_FIXED');

  static const $core.List<ContextMode> values = <ContextMode>[
    CONTEXT_MODE_UNSPECIFIED,
    CONTEXT_MODE_AUTO_MAX,
    CONTEXT_MODE_FIXED,
  ];

  static final $core.List<ContextMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ContextMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ContextMode._(super.value, super.name);
}

/// Priority weighs an instance against the others when memory runs short.
/// PRIORITY_PINNED is not a weight but an exemption: a pinned instance is not
/// evicted.
class Priority extends $pb.ProtobufEnum {
  /// Unset means normal.
  static const Priority PRIORITY_UNSPECIFIED =
      Priority._(0, _omitEnumNames ? '' : 'PRIORITY_UNSPECIFIED');
  static const Priority PRIORITY_LOW =
      Priority._(1, _omitEnumNames ? '' : 'PRIORITY_LOW');
  static const Priority PRIORITY_NORMAL =
      Priority._(2, _omitEnumNames ? '' : 'PRIORITY_NORMAL');
  static const Priority PRIORITY_HIGH =
      Priority._(3, _omitEnumNames ? '' : 'PRIORITY_HIGH');
  static const Priority PRIORITY_PINNED =
      Priority._(4, _omitEnumNames ? '' : 'PRIORITY_PINNED');

  static const $core.List<Priority> values = <Priority>[
    PRIORITY_UNSPECIFIED,
    PRIORITY_LOW,
    PRIORITY_NORMAL,
    PRIORITY_HIGH,
    PRIORITY_PINNED,
  ];

  static final $core.List<Priority?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Priority? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Priority._(super.value, super.name);
}

/// KvCachePolicy is the wish for the KV cache before the runtime has had its
/// say; the resolved type is reported as KvCacheDtype on the plan.
class KvCachePolicy extends $pb.ProtobufEnum {
  /// Unset means prefer_4bit.
  static const KvCachePolicy KV_CACHE_POLICY_UNSPECIFIED =
      KvCachePolicy._(0, _omitEnumNames ? '' : 'KV_CACHE_POLICY_UNSPECIFIED');
  static const KvCachePolicy KV_CACHE_POLICY_NATIVE =
      KvCachePolicy._(1, _omitEnumNames ? '' : 'KV_CACHE_POLICY_NATIVE');
  static const KvCachePolicy KV_CACHE_POLICY_PREFER_4BIT =
      KvCachePolicy._(2, _omitEnumNames ? '' : 'KV_CACHE_POLICY_PREFER_4BIT');

  static const $core.List<KvCachePolicy> values = <KvCachePolicy>[
    KV_CACHE_POLICY_UNSPECIFIED,
    KV_CACHE_POLICY_NATIVE,
    KV_CACHE_POLICY_PREFER_4BIT,
  ];

  static final $core.List<KvCachePolicy?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static KvCachePolicy? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const KvCachePolicy._(super.value, super.name);
}

/// KvCacheDtype is what the planner settled on.
class KvCacheDtype extends $pb.ProtobufEnum {
  static const KvCacheDtype KV_CACHE_DTYPE_UNSPECIFIED =
      KvCacheDtype._(0, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_UNSPECIFIED');

  /// Q4 is q4_0, the smallest cache type llama.cpp supports, and the default.
  static const KvCacheDtype KV_CACHE_DTYPE_Q4 =
      KvCacheDtype._(1, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_Q4');
  static const KvCacheDtype KV_CACHE_DTYPE_FP16 =
      KvCacheDtype._(3, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_FP16');
  static const KvCacheDtype KV_CACHE_DTYPE_BF16 =
      KvCacheDtype._(4, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_BF16');
  static const KvCacheDtype KV_CACHE_DTYPE_FP32 =
      KvCacheDtype._(5, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_FP32');
  static const KvCacheDtype KV_CACHE_DTYPE_Q4_1 =
      KvCacheDtype._(6, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_Q4_1');
  static const KvCacheDtype KV_CACHE_DTYPE_IQ4_NL =
      KvCacheDtype._(7, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_IQ4_NL');
  static const KvCacheDtype KV_CACHE_DTYPE_Q5_0 =
      KvCacheDtype._(8, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_Q5_0');
  static const KvCacheDtype KV_CACHE_DTYPE_Q5_1 =
      KvCacheDtype._(9, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_Q5_1');
  static const KvCacheDtype KV_CACHE_DTYPE_Q8_0 =
      KvCacheDtype._(10, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_Q8_0');

  /// Two-bit K-quant. Upstream llama.cpp rejects it for the KV cache; only a
  /// build that reports it can be planned with it.
  static const KvCacheDtype KV_CACHE_DTYPE_Q2_K =
      KvCacheDtype._(11, _omitEnumNames ? '' : 'KV_CACHE_DTYPE_Q2_K');

  static const $core.List<KvCacheDtype> values = <KvCacheDtype>[
    KV_CACHE_DTYPE_UNSPECIFIED,
    KV_CACHE_DTYPE_Q4,
    KV_CACHE_DTYPE_FP16,
    KV_CACHE_DTYPE_BF16,
    KV_CACHE_DTYPE_FP32,
    KV_CACHE_DTYPE_Q4_1,
    KV_CACHE_DTYPE_IQ4_NL,
    KV_CACHE_DTYPE_Q5_0,
    KV_CACHE_DTYPE_Q5_1,
    KV_CACHE_DTYPE_Q8_0,
    KV_CACHE_DTYPE_Q2_K,
  ];

  static final $core.List<KvCacheDtype?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static KvCacheDtype? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const KvCacheDtype._(super.value, super.name);
}

/// InstanceState is the lifecycle of a single instance.
class InstanceState extends $pb.ProtobufEnum {
  static const InstanceState INSTANCE_STATE_UNSPECIFIED =
      InstanceState._(0, _omitEnumNames ? '' : 'INSTANCE_STATE_UNSPECIFIED');
  static const InstanceState INSTANCE_STATE_INSTALLING =
      InstanceState._(1, _omitEnumNames ? '' : 'INSTANCE_STATE_INSTALLING');
  static const InstanceState INSTANCE_STATE_QUEUED =
      InstanceState._(2, _omitEnumNames ? '' : 'INSTANCE_STATE_QUEUED');
  static const InstanceState INSTANCE_STATE_STARTING =
      InstanceState._(3, _omitEnumNames ? '' : 'INSTANCE_STATE_STARTING');
  static const InstanceState INSTANCE_STATE_READY =
      InstanceState._(4, _omitEnumNames ? '' : 'INSTANCE_STATE_READY');
  static const InstanceState INSTANCE_STATE_DRAINING =
      InstanceState._(5, _omitEnumNames ? '' : 'INSTANCE_STATE_DRAINING');
  static const InstanceState INSTANCE_STATE_RESTARTING =
      InstanceState._(6, _omitEnumNames ? '' : 'INSTANCE_STATE_RESTARTING');
  static const InstanceState INSTANCE_STATE_STOPPED =
      InstanceState._(7, _omitEnumNames ? '' : 'INSTANCE_STATE_STOPPED');
  static const InstanceState INSTANCE_STATE_FAILED =
      InstanceState._(8, _omitEnumNames ? '' : 'INSTANCE_STATE_FAILED');
  static const InstanceState INSTANCE_STATE_FAILED_ROLLBACK = InstanceState._(
      9, _omitEnumNames ? '' : 'INSTANCE_STATE_FAILED_ROLLBACK');

  static const $core.List<InstanceState> values = <InstanceState>[
    INSTANCE_STATE_UNSPECIFIED,
    INSTANCE_STATE_INSTALLING,
    INSTANCE_STATE_QUEUED,
    INSTANCE_STATE_STARTING,
    INSTANCE_STATE_READY,
    INSTANCE_STATE_DRAINING,
    INSTANCE_STATE_RESTARTING,
    INSTANCE_STATE_STOPPED,
    INSTANCE_STATE_FAILED,
    INSTANCE_STATE_FAILED_ROLLBACK,
  ];

  static final $core.List<InstanceState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static InstanceState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InstanceState._(super.value, super.name);
}

/// OperationState is the lifecycle of a scheduled operation.
class OperationState extends $pb.ProtobufEnum {
  static const OperationState OPERATION_STATE_UNSPECIFIED =
      OperationState._(0, _omitEnumNames ? '' : 'OPERATION_STATE_UNSPECIFIED');
  static const OperationState OPERATION_STATE_QUEUED =
      OperationState._(1, _omitEnumNames ? '' : 'OPERATION_STATE_QUEUED');
  static const OperationState OPERATION_STATE_RUNNING =
      OperationState._(2, _omitEnumNames ? '' : 'OPERATION_STATE_RUNNING');
  static const OperationState OPERATION_STATE_COMPLETED =
      OperationState._(3, _omitEnumNames ? '' : 'OPERATION_STATE_COMPLETED');
  static const OperationState OPERATION_STATE_FAILED =
      OperationState._(4, _omitEnumNames ? '' : 'OPERATION_STATE_FAILED');
  static const OperationState OPERATION_STATE_CANCELLED =
      OperationState._(5, _omitEnumNames ? '' : 'OPERATION_STATE_CANCELLED');

  static const $core.List<OperationState> values = <OperationState>[
    OPERATION_STATE_UNSPECIFIED,
    OPERATION_STATE_QUEUED,
    OPERATION_STATE_RUNNING,
    OPERATION_STATE_COMPLETED,
    OPERATION_STATE_FAILED,
    OPERATION_STATE_CANCELLED,
  ];

  static final $core.List<OperationState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static OperationState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OperationState._(super.value, super.name);
}

/// Placement says where the weights and the cache ended up.
class Placement extends $pb.ProtobufEnum {
  /// Unset means unknown, which is what the engine reports before it has
  /// planned the instance.
  static const Placement PLACEMENT_UNSPECIFIED =
      Placement._(0, _omitEnumNames ? '' : 'PLACEMENT_UNSPECIFIED');
  static const Placement PLACEMENT_GPU =
      Placement._(1, _omitEnumNames ? '' : 'PLACEMENT_GPU');
  static const Placement PLACEMENT_RAM =
      Placement._(2, _omitEnumNames ? '' : 'PLACEMENT_RAM');
  static const Placement PLACEMENT_HYBRID =
      Placement._(3, _omitEnumNames ? '' : 'PLACEMENT_HYBRID');

  static const $core.List<Placement> values = <Placement>[
    PLACEMENT_UNSPECIFIED,
    PLACEMENT_GPU,
    PLACEMENT_RAM,
    PLACEMENT_HYBRID,
  ];

  static final $core.List<Placement?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Placement? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Placement._(super.value, super.name);
}

/// GuardState is how close the resource guard is to intervening.
class GuardState extends $pb.ProtobufEnum {
  /// Unset means normal.
  static const GuardState GUARD_STATE_UNSPECIFIED =
      GuardState._(0, _omitEnumNames ? '' : 'GUARD_STATE_UNSPECIFIED');
  static const GuardState GUARD_STATE_NORMAL =
      GuardState._(1, _omitEnumNames ? '' : 'GUARD_STATE_NORMAL');
  static const GuardState GUARD_STATE_WARNING =
      GuardState._(2, _omitEnumNames ? '' : 'GUARD_STATE_WARNING');
  static const GuardState GUARD_STATE_CRITICAL =
      GuardState._(3, _omitEnumNames ? '' : 'GUARD_STATE_CRITICAL');
  static const GuardState GUARD_STATE_EMERGENCY =
      GuardState._(4, _omitEnumNames ? '' : 'GUARD_STATE_EMERGENCY');

  static const $core.List<GuardState> values = <GuardState>[
    GUARD_STATE_UNSPECIFIED,
    GUARD_STATE_NORMAL,
    GUARD_STATE_WARNING,
    GUARD_STATE_CRITICAL,
    GUARD_STATE_EMERGENCY,
  ];

  static final $core.List<GuardState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static GuardState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GuardState._(super.value, super.name);
}

/// ModelFormat is the on-disk shape of a catalog entry.
class ModelFormat extends $pb.ProtobufEnum {
  static const ModelFormat MODEL_FORMAT_UNSPECIFIED =
      ModelFormat._(0, _omitEnumNames ? '' : 'MODEL_FORMAT_UNSPECIFIED');
  static const ModelFormat MODEL_FORMAT_GGUF =
      ModelFormat._(1, _omitEnumNames ? '' : 'MODEL_FORMAT_GGUF');

  static const $core.List<ModelFormat> values = <ModelFormat>[
    MODEL_FORMAT_UNSPECIFIED,
    MODEL_FORMAT_GGUF,
  ];

  static final $core.List<ModelFormat?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ModelFormat? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModelFormat._(super.value, super.name);
}

/// ModelStatus summarises whether a catalog entry can be started. The HTTP API
/// derived it from the complete and startable flags on every response; it is
/// derived here too, and the flags are still carried so the reason survives.
class ModelStatus extends $pb.ProtobufEnum {
  static const ModelStatus MODEL_STATUS_UNSPECIFIED =
      ModelStatus._(0, _omitEnumNames ? '' : 'MODEL_STATUS_UNSPECIFIED');
  static const ModelStatus MODEL_STATUS_READY =
      ModelStatus._(1, _omitEnumNames ? '' : 'MODEL_STATUS_READY');
  static const ModelStatus MODEL_STATUS_INVALID =
      ModelStatus._(2, _omitEnumNames ? '' : 'MODEL_STATUS_INVALID');
  static const ModelStatus MODEL_STATUS_INCOMPLETE =
      ModelStatus._(3, _omitEnumNames ? '' : 'MODEL_STATUS_INCOMPLETE');

  static const $core.List<ModelStatus> values = <ModelStatus>[
    MODEL_STATUS_UNSPECIFIED,
    MODEL_STATUS_READY,
    MODEL_STATUS_INVALID,
    MODEL_STATUS_INCOMPLETE,
  ];

  static final $core.List<ModelStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ModelStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModelStatus._(super.value, super.name);
}

/// IssueSeverity grades a catalog validation finding.
class IssueSeverity extends $pb.ProtobufEnum {
  static const IssueSeverity ISSUE_SEVERITY_UNSPECIFIED =
      IssueSeverity._(0, _omitEnumNames ? '' : 'ISSUE_SEVERITY_UNSPECIFIED');
  static const IssueSeverity ISSUE_SEVERITY_WARNING =
      IssueSeverity._(1, _omitEnumNames ? '' : 'ISSUE_SEVERITY_WARNING');
  static const IssueSeverity ISSUE_SEVERITY_ERROR =
      IssueSeverity._(2, _omitEnumNames ? '' : 'ISSUE_SEVERITY_ERROR');

  static const $core.List<IssueSeverity> values = <IssueSeverity>[
    ISSUE_SEVERITY_UNSPECIFIED,
    ISSUE_SEVERITY_WARNING,
    ISSUE_SEVERITY_ERROR,
  ];

  static final $core.List<IssueSeverity?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static IssueSeverity? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const IssueSeverity._(super.value, super.name);
}

/// ChangeMode says whether a config field can be changed on a running instance.
class ChangeMode extends $pb.ProtobufEnum {
  static const ChangeMode CHANGE_MODE_UNSPECIFIED =
      ChangeMode._(0, _omitEnumNames ? '' : 'CHANGE_MODE_UNSPECIFIED');
  static const ChangeMode CHANGE_MODE_LIVE =
      ChangeMode._(1, _omitEnumNames ? '' : 'CHANGE_MODE_LIVE');
  static const ChangeMode CHANGE_MODE_RESTART_REQUIRED =
      ChangeMode._(2, _omitEnumNames ? '' : 'CHANGE_MODE_RESTART_REQUIRED');

  static const $core.List<ChangeMode> values = <ChangeMode>[
    CHANGE_MODE_UNSPECIFIED,
    CHANGE_MODE_LIVE,
    CHANGE_MODE_RESTART_REQUIRED,
  ];

  static final $core.List<ChangeMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ChangeMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ChangeMode._(super.value, super.name);
}

/// Confidence separates a measured reading from an estimate.
class Confidence extends $pb.ProtobufEnum {
  static const Confidence CONFIDENCE_UNSPECIFIED =
      Confidence._(0, _omitEnumNames ? '' : 'CONFIDENCE_UNSPECIFIED');
  static const Confidence CONFIDENCE_MEASURED =
      Confidence._(1, _omitEnumNames ? '' : 'CONFIDENCE_MEASURED');
  static const Confidence CONFIDENCE_ESTIMATED =
      Confidence._(2, _omitEnumNames ? '' : 'CONFIDENCE_ESTIMATED');

  static const $core.List<Confidence> values = <Confidence>[
    CONFIDENCE_UNSPECIFIED,
    CONFIDENCE_MEASURED,
    CONFIDENCE_ESTIMATED,
  ];

  static final $core.List<Confidence?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Confidence? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Confidence._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
