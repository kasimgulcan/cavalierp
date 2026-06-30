import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/json_field.dart';
import '../../core/network/api_error.dart';
import '../../core/network/sp_client.dart';
import '../../core/storage/token_storage.dart';
import '../sale/currency_selection.dart';
import 'unauthorized_notifier.dart';

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
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(false);
      return;
    }
    state = const AsyncValue.data(true);
  }

  Future<void> handleUnauthorized() async {
    if (state.valueOrNull != true) return;
    await _tokenStorage.clear();
    _resetCurrencySelection();
    state = const AsyncValue.data(false);
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _spClient.exec(
        'Auth.Login',
        {'Email': email, 'Password': password},
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
        return 'E-posta veya şifre hatalı';
      }
      await _tokenStorage.saveTokens(accessToken, refreshToken);
      _resetCurrencySelection();
      state = const AsyncValue.data(true);
      return null;
    } catch (e) {
      state = const AsyncValue.data(false);
      return formatApiError(e);
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      final response = await _spClient.exec(
        'Auth.Register',
        {
          'Email': email,
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
      _resetCurrencySelection();
      state = const AsyncValue.data(true);
      return null;
    } catch (e) {
      return formatApiError(e);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _resetCurrencySelection();
    state = const AsyncValue.data(false);
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
}
