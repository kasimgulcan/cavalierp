import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/screenshot_config.dart';
import '../../core/models/json_field.dart';
import '../../core/network/api_error.dart';
import '../../core/network/sp_client.dart';
import '../../core/storage/token_storage.dart';
import '../sale/currency_selection.dart';
import '../sale/pending_cart_add_provider.dart';
import 'unauthorized_notifier.dart';
import 'username_validator.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final unauthorized = ref.watch(unauthorizedNotifierProvider);
  return createDio(
    ref.watch(tokenStorageProvider),
    onUnauthorized: unauthorized.notify,
  );
});

final spClientProvider = Provider<SpClient>((ref) {
  return SpClient(ref.watch(dioProvider));
});

final lastKnownRoleProvider = StateProvider<String?>((ref) => null);

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(
    ref.watch(spClientProvider),
    ref.watch(tokenStorageProvider),
    ref,
    ref.watch(unauthorizedNotifierProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  AuthNotifier(
    this._spClient,
    this._tokenStorage,
    this._ref,
    UnauthorizedNotifier unauthorized,
  )   : _unauthorized = unauthorized,
        super(const AsyncValue.loading()) {
    _unauthorized.onUnauthorized = handleUnauthorized;
    _bootstrap();
  }

  final SpClient _spClient;
  final TokenStorage _tokenStorage;
  final Ref _ref;
  final UnauthorizedNotifier _unauthorized;

  void _resetCurrencySelection() {
    _ref.read(selectedCurrencyIdProvider.notifier).state = kDefaultCurrencyId;
  }

  Future<void> _bootstrap() async {
    if (ScreenshotConfig.autoLogin &&
        ScreenshotConfig.username.isNotEmpty &&
        ScreenshotConfig.password.isNotEmpty) {
      await login(ScreenshotConfig.username, ScreenshotConfig.password);
      return;
    }
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(false);
      return;
    }
    final role = await _tokenStorage.getRole();
    _ref.read(lastKnownRoleProvider.notifier).state = role;
    state = const AsyncValue.data(true);
  }

  Future<void> handleUnauthorized() async {
    if (state.valueOrNull != true) return;
    await _tokenStorage.clear();
    _resetCurrencySelection();
    _ref.read(lastKnownRoleProvider.notifier).state = null;
    state = const AsyncValue.data(false);
  }

  Future<String?> login(String username, String password) async {
    try {
      final response = await _spClient.exec(
        'Auth.Login',
        {'Username': username, 'Password': password},
        auth: false,
      );
      if (!response.success) {
        state = const AsyncValue.data(false);
        return response.error ?? 'Giriş başarısız';
      }
      final data = parseAuthPayload(response.data);
      final accessToken = data != null ? readAuthToken(data, 'accessToken') : null;
      final refreshToken = data != null ? readAuthToken(data, 'refreshToken') : null;
      if (accessToken == null || refreshToken == null) {
        state = const AsyncValue.data(false);
        return 'Kullanıcı adı veya şifre hatalı';
      }
      await _tokenStorage.saveTokens(accessToken, refreshToken);
      await _applyRoleFromAuthPayload(data);
      _resetCurrencySelection();
      state = const AsyncValue.data(true);
      return null;
    } catch (e) {
      state = const AsyncValue.data(false);
      return formatApiError(e);
    }
  }

  Future<String?> register(String username, String password) async {
    final trimmedUsername = username.trim();
    final validationError = validateUsername(trimmedUsername);
    if (validationError != null) return validationError;
    final passwordError = validatePassword(password);
    if (passwordError != null) return passwordError;
    try {
      final response = await _spClient.exec(
        'Auth.Register',
        {
          'Username': trimmedUsername,
          'Password': password,
          'AcceptedTerms': true,
        },
        auth: false,
      );
      if (!response.success) return response.error ?? 'Kayıt başarısız';
      final data = parseAuthPayload(response.data);
      final accessToken = data != null ? readAuthToken(data, 'accessToken') : null;
      final refreshToken = data != null ? readAuthToken(data, 'refreshToken') : null;
      if (accessToken == null || refreshToken == null) {
        return response.error ?? 'Kayıt yanıtı geçersiz';
      }
      await _tokenStorage.saveTokens(accessToken, refreshToken);
      await _applyRoleFromAuthPayload(data);
      _resetCurrencySelection();
      state = const AsyncValue.data(true);
      return null;
    } catch (e) {
      return formatApiError(e);
    }
  }

  Future<void> logout() async {
    _ref.read(pendingCartAddProvider.notifier).clear();
    await _tokenStorage.clear();
    _resetCurrencySelection();
    _ref.read(lastKnownRoleProvider.notifier).state = null;
    state = const AsyncValue.data(false);
  }

  Future<void> _applyRoleFromAuthPayload(Map<String, dynamic>? data) async {
    if (data == null) return;
    final user = data['user'] ?? data['User'];
    String? role;
    if (user is Map) {
      role = Map<String, dynamic>.from(user).stringField('Role');
    }
    await _tokenStorage.saveRole(role);
    _ref.read(lastKnownRoleProvider.notifier).state = role;
  }

  Future<String?> deleteAccount() async {
    try {
      final response = await _spClient.exec('Auth.DeleteAccount', {});
      if (!response.success) return response.error ?? 'Silme başarısız';
      await logout();
      return null;
    } catch (e) {
      return formatApiError(e);
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final passwordError = validatePassword(newPassword);
    if (passwordError != null) return passwordError;
    if (currentPassword == newPassword) {
      return 'Yeni şifre mevcut şifreden farklı olmalıdır';
    }
    try {
      final response = await _spClient.exec('Auth.ChangePassword', {
        'CurrentPassword': currentPassword,
        'NewPassword': newPassword,
      });
      if (!response.success) {
        return response.error ?? 'Şifre değiştirilemedi';
      }
      return null;
    } catch (e) {
      return formatApiError(e);
    }
  }
}
