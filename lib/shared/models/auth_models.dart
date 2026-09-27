import 'package:flutter/foundation.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String vendorId;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.vendorId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: (json['accessToken'] ?? json['accessToken '] ?? '') as String,
    refreshToken: (json['refreshToken'] ?? '') as String,
    vendorId:
        (json['vendorId'] ?? (json['vendor'] as Map?)?['id'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'vendorId': vendorId,
  };
}

class OtpResponse {
  final bool success;
  final String? message;
  final String? tempToken;

  OtpResponse({required this.success, this.message, this.tempToken});

  factory OtpResponse.fromJson(Map<String, dynamic> json) => OtpResponse(
    success: (json['success'] as bool? ?? true),
    message: json['message'] as String?,
    tempToken: json['tempToken'] as String?,
  );
}

class PinSetupResponse {
  final bool success;
  final String message;

  PinSetupResponse({required this.success, required this.message});

  factory PinSetupResponse.fromJson(Map<String, dynamic> json) =>
      PinSetupResponse(
        success: (json['success'] as bool? ?? true),
        message: (json['message'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {'success': success, 'message': message};
}

@immutable
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool hasPinSet;
  final String? vendorId;
  final String? lastPhone;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.hasPinSet = false,
    this.vendorId,
    this.lastPhone,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? hasPinSet,
    String? vendorId,
    String? lastPhone,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      vendorId: vendorId ?? this.vendorId,
      lastPhone: lastPhone ?? this.lastPhone,
      error: error,
    );
  }
}
