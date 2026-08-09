// This is a generated file - do not edit.
//
// Generated from culpeostudio/login/v1/login.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sessionDurationDescriptor instead')
const SessionDuration$json = {
  '1': 'SessionDuration',
  '2': [
    {'1': 'SESSION_DURATION_UNSPECIFIED', '2': 0},
    {'1': 'SESSION_DURATION_8H', '2': 1},
    {'1': 'SESSION_DURATION_24H', '2': 2},
    {'1': 'SESSION_DURATION_48H', '2': 3},
    {'1': 'SESSION_DURATION_PERMANENT', '2': 4},
  ],
};

/// Descriptor for `SessionDuration`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sessionDurationDescriptor = $convert.base64Decode(
    'Cg9TZXNzaW9uRHVyYXRpb24SIAocU0VTU0lPTl9EVVJBVElPTl9VTlNQRUNJRklFRBAAEhcKE1'
    'NFU1NJT05fRFVSQVRJT05fOEgQARIYChRTRVNTSU9OX0RVUkFUSU9OXzI0SBACEhgKFFNFU1NJ'
    'T05fRFVSQVRJT05fNDhIEAMSHgoaU0VTU0lPTl9EVVJBVElPTl9QRVJNQU5FTlQQBA==');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {
      '1': 'session_duration',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.login.v1.SessionDuration',
      '10': 'sessionDuration'
    },
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGA'
    'IgASgJUghwYXNzd29yZBJRChBzZXNzaW9uX2R1cmF0aW9uGAMgASgOMiYuY3VscGVvc3R1ZGlv'
    'LmxvZ2luLnYxLlNlc3Npb25EdXJhdGlvblIPc2Vzc2lvbkR1cmF0aW9u');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'session_duration',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.culpeostudio.login.v1.SessionDuration',
      '10': 'sessionDuration'
    },
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode(
    'Cg1Mb2dpblJlc3BvbnNlEhQKBXRva2VuGAEgASgJUgV0b2tlbhIaCgh1c2VybmFtZRgCIAEoCV'
    'IIdXNlcm5hbWUSUQoQc2Vzc2lvbl9kdXJhdGlvbhgDIAEoDjImLmN1bHBlb3N0dWRpby5sb2dp'
    'bi52MS5TZXNzaW9uRHVyYXRpb25SD3Nlc3Npb25EdXJhdGlvbg==');

@$core.Deprecated('Use getAuthStatusRequestDescriptor instead')
const GetAuthStatusRequest$json = {
  '1': 'GetAuthStatusRequest',
};

/// Descriptor for `GetAuthStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAuthStatusRequestDescriptor =
    $convert.base64Decode('ChRHZXRBdXRoU3RhdHVzUmVxdWVzdA==');

@$core.Deprecated('Use getAuthStatusResponseDescriptor instead')
const GetAuthStatusResponse$json = {
  '1': 'GetAuthStatusResponse',
  '2': [
    {'1': 'totp_configured', '3': 1, '4': 1, '5': 8, '10': 'totpConfigured'},
    {
      '1': 'authenticator_app',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'authenticatorApp'
    },
  ],
};

/// Descriptor for `GetAuthStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAuthStatusResponseDescriptor = $convert.base64Decode(
    'ChVHZXRBdXRoU3RhdHVzUmVzcG9uc2USJwoPdG90cF9jb25maWd1cmVkGAEgASgIUg50b3RwQ2'
    '9uZmlndXJlZBIrChFhdXRoZW50aWNhdG9yX2FwcBgCIAEoCVIQYXV0aGVudGljYXRvckFwcA==');

@$core.Deprecated('Use startAuthenticatorSetupRequestDescriptor instead')
const StartAuthenticatorSetupRequest$json = {
  '1': 'StartAuthenticatorSetupRequest',
};

/// Descriptor for `StartAuthenticatorSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startAuthenticatorSetupRequestDescriptor =
    $convert.base64Decode('Ch5TdGFydEF1dGhlbnRpY2F0b3JTZXR1cFJlcXVlc3Q=');

@$core.Deprecated('Use startAuthenticatorSetupResponseDescriptor instead')
const StartAuthenticatorSetupResponse$json = {
  '1': 'StartAuthenticatorSetupResponse',
  '2': [
    {'1': 'secret', '3': 1, '4': 1, '5': 9, '10': 'secret'},
    {'1': 'otpauth_url', '3': 2, '4': 1, '5': 9, '10': 'otpauthUrl'},
  ],
};

/// Descriptor for `StartAuthenticatorSetupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startAuthenticatorSetupResponseDescriptor =
    $convert.base64Decode(
        'Ch9TdGFydEF1dGhlbnRpY2F0b3JTZXR1cFJlc3BvbnNlEhYKBnNlY3JldBgBIAEoCVIGc2Vjcm'
        'V0Eh8KC290cGF1dGhfdXJsGAIgASgJUgpvdHBhdXRoVXJs');

@$core.Deprecated('Use confirmAuthenticatorSetupRequestDescriptor instead')
const ConfirmAuthenticatorSetupRequest$json = {
  '1': 'ConfirmAuthenticatorSetupRequest',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'app', '3': 2, '4': 1, '5': 9, '10': 'app'},
  ],
};

/// Descriptor for `ConfirmAuthenticatorSetupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List confirmAuthenticatorSetupRequestDescriptor =
    $convert.base64Decode(
        'CiBDb25maXJtQXV0aGVudGljYXRvclNldHVwUmVxdWVzdBISCgRjb2RlGAEgASgJUgRjb2RlEh'
        'AKA2FwcBgCIAEoCVIDYXBw');

@$core.Deprecated('Use confirmAuthenticatorSetupResponseDescriptor instead')
const ConfirmAuthenticatorSetupResponse$json = {
  '1': 'ConfirmAuthenticatorSetupResponse',
  '2': [
    {'1': 'totp_configured', '3': 1, '4': 1, '5': 8, '10': 'totpConfigured'},
  ],
};

/// Descriptor for `ConfirmAuthenticatorSetupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List confirmAuthenticatorSetupResponseDescriptor =
    $convert.base64Decode(
        'CiFDb25maXJtQXV0aGVudGljYXRvclNldHVwUmVzcG9uc2USJwoPdG90cF9jb25maWd1cmVkGA'
        'EgASgIUg50b3RwQ29uZmlndXJlZA==');

@$core.Deprecated('Use createAccountRequestDescriptor instead')
const CreateAccountRequest$json = {
  '1': 'CreateAccountRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {'1': 'totp_code', '3': 3, '4': 1, '5': 9, '10': 'totpCode'},
  ],
};

/// Descriptor for `CreateAccountRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAccountRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVBY2NvdW50UmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUSGgoIcG'
    'Fzc3dvcmQYAiABKAlSCHBhc3N3b3JkEhsKCXRvdHBfY29kZRgDIAEoCVIIdG90cENvZGU=');

@$core.Deprecated('Use createAccountResponseDescriptor instead')
const CreateAccountResponse$json = {
  '1': 'CreateAccountResponse',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
};

/// Descriptor for `CreateAccountResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createAccountResponseDescriptor =
    $convert.base64Decode(
        'ChVDcmVhdGVBY2NvdW50UmVzcG9uc2USGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1l');

@$core.Deprecated('Use resetPasswordRequestDescriptor instead')
const ResetPasswordRequest$json = {
  '1': 'ResetPasswordRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'new_password', '3': 2, '4': 1, '5': 9, '10': 'newPassword'},
    {'1': 'totp_code', '3': 3, '4': 1, '5': 9, '10': 'totpCode'},
  ],
};

/// Descriptor for `ResetPasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordRequestDescriptor = $convert.base64Decode(
    'ChRSZXNldFBhc3N3b3JkUmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUSIQoMbm'
    'V3X3Bhc3N3b3JkGAIgASgJUgtuZXdQYXNzd29yZBIbCgl0b3RwX2NvZGUYAyABKAlSCHRvdHBD'
    'b2Rl');

@$core.Deprecated('Use resetPasswordResponseDescriptor instead')
const ResetPasswordResponse$json = {
  '1': 'ResetPasswordResponse',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password_reset', '3': 2, '4': 1, '5': 8, '10': 'passwordReset'},
  ],
};

/// Descriptor for `ResetPasswordResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordResponseDescriptor = $convert.base64Decode(
    'ChVSZXNldFBhc3N3b3JkUmVzcG9uc2USGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEiUKDn'
    'Bhc3N3b3JkX3Jlc2V0GAIgASgIUg1wYXNzd29yZFJlc2V0');

@$core.Deprecated('Use userPreferencesDescriptor instead')
const UserPreferences$json = {
  '1': 'UserPreferences',
  '2': [
    {'1': 'configured', '3': 1, '4': 1, '5': 8, '10': 'configured'},
    {'1': 'language', '3': 2, '4': 1, '5': 9, '10': 'language'},
    {'1': 'frontend_version', '3': 3, '4': 1, '5': 9, '10': 'frontendVersion'},
  ],
};

/// Descriptor for `UserPreferences`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPreferencesDescriptor = $convert.base64Decode(
    'Cg9Vc2VyUHJlZmVyZW5jZXMSHgoKY29uZmlndXJlZBgBIAEoCFIKY29uZmlndXJlZBIaCghsYW'
    '5ndWFnZRgCIAEoCVIIbGFuZ3VhZ2USKQoQZnJvbnRlbmRfdmVyc2lvbhgDIAEoCVIPZnJvbnRl'
    'bmRWZXJzaW9u');

@$core.Deprecated('Use getUserPreferencesRequestDescriptor instead')
const GetUserPreferencesRequest$json = {
  '1': 'GetUserPreferencesRequest',
};

/// Descriptor for `GetUserPreferencesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserPreferencesRequestDescriptor =
    $convert.base64Decode('ChlHZXRVc2VyUHJlZmVyZW5jZXNSZXF1ZXN0');

@$core.Deprecated('Use getUserPreferencesResponseDescriptor instead')
const GetUserPreferencesResponse$json = {
  '1': 'GetUserPreferencesResponse',
  '2': [
    {
      '1': 'preferences',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.login.v1.UserPreferences',
      '10': 'preferences'
    },
  ],
};

/// Descriptor for `GetUserPreferencesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserPreferencesResponseDescriptor =
    $convert.base64Decode(
        'ChpHZXRVc2VyUHJlZmVyZW5jZXNSZXNwb25zZRJICgtwcmVmZXJlbmNlcxgBIAEoCzImLmN1bH'
        'Blb3N0dWRpby5sb2dpbi52MS5Vc2VyUHJlZmVyZW5jZXNSC3ByZWZlcmVuY2Vz');

@$core.Deprecated('Use updateUserPreferencesRequestDescriptor instead')
const UpdateUserPreferencesRequest$json = {
  '1': 'UpdateUserPreferencesRequest',
  '2': [
    {'1': 'language', '3': 1, '4': 1, '5': 9, '10': 'language'},
    {'1': 'frontend_version', '3': 2, '4': 1, '5': 9, '10': 'frontendVersion'},
  ],
};

/// Descriptor for `UpdateUserPreferencesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserPreferencesRequestDescriptor =
    $convert.base64Decode(
        'ChxVcGRhdGVVc2VyUHJlZmVyZW5jZXNSZXF1ZXN0EhoKCGxhbmd1YWdlGAEgASgJUghsYW5ndW'
        'FnZRIpChBmcm9udGVuZF92ZXJzaW9uGAIgASgJUg9mcm9udGVuZFZlcnNpb24=');

@$core.Deprecated('Use updateUserPreferencesResponseDescriptor instead')
const UpdateUserPreferencesResponse$json = {
  '1': 'UpdateUserPreferencesResponse',
  '2': [
    {
      '1': 'preferences',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.culpeostudio.login.v1.UserPreferences',
      '10': 'preferences'
    },
  ],
};

/// Descriptor for `UpdateUserPreferencesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserPreferencesResponseDescriptor =
    $convert.base64Decode(
        'Ch1VcGRhdGVVc2VyUHJlZmVyZW5jZXNSZXNwb25zZRJICgtwcmVmZXJlbmNlcxgBIAEoCzImLm'
        'N1bHBlb3N0dWRpby5sb2dpbi52MS5Vc2VyUHJlZmVyZW5jZXNSC3ByZWZlcmVuY2Vz');
