import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/session_state.dart';
import '../../../shared/models/vendor_model.dart';
import 'vendor_auth_repository.dart';

enum AuthFlow { firstLogin, reconnection, unknown }

class VendorAuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? phone;
  final String? error;
  final AuthFlow flow;

  const VendorAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.phone,
    this.error,
    this.flow = AuthFlow.unknown,
  });

  VendorAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? phone,
    String? error,
    AuthFlow? flow,
  }) {
    return VendorAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      phone: phone ?? this.phone,
      error: error,
      flow: flow ?? this.flow,
    );
  }
}

class VendorAuthNotifier extends Notifier<VendorAuthState> {
  String _errorMessage(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: '), '');

  VendorAuthRepository get _repo => ref.read(vendorAuthRepositoryProvider);

  @override
  VendorAuthState build() {
    ref.listen(sessionExpiredProvider, (previous, expired) {
      if (expired) {
        state = VendorAuthState(flow: AuthFlow.firstLogin);
      }
    });
    final isAuth = _repo.hasTokens();
    if (isAuth) {
      return VendorAuthState(
        isAuthenticated: true,
        phone: _repo.getLastPhone(),
        flow: AuthFlow.reconnection,
      );
    }
    return VendorAuthState(flow: AuthFlow.firstLogin);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone, error: null);
    _repo.saveLastPhone(phone);
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.sendOtp(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.verifyOtp(phone, code);
      ref.read(sessionExpiredProvider.notifier).state = false;
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    ref.read(sessionExpiredProvider.notifier).state = false;
    state = VendorAuthState(flow: AuthFlow.firstLogin);
  }
}

final vendorAuthProvider =
    NotifierProvider<VendorAuthNotifier, VendorAuthState>(
      VendorAuthNotifier.new,
    );

final currentVendorProvider = FutureProvider<VendorModel>((ref) async {
  final repo = ref.watch(vendorAuthRepositoryProvider);
  return repo.getVendorProfile();
});
