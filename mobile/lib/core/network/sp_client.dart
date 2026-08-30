import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/exec_sp_response.dart';
import '../models/json_field.dart';
import '../storage/token_storage.dart';
import 'api_error.dart';
import 'auth_interceptor.dart';
import 'auth_refresh.dart';

typedef UnauthorizedCallback = void Function();

class SpClient {
  SpClient(this._dio);

  final Dio _dio;

  Future<ExecSpResponse> exec(
    String sp,
    Map<String, dynamic>? params, {
    bool auth = true,
  }) async {
    final path = auth ? '/exec' : '/auth/exec';
    try {
      final response = await _dio.post(
        path,
        data: {'sp': sp, 'params': params ?? {}},
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response.statusCode == 401) {
        return ExecSpResponse(
          success: false,
          error: 'Oturum geçersiz veya süresi doldu. Tekrar giriş yapın.',
        );
      }

      final body = response.data;
      final json = _asJsonMap(body);
      if (json == null) {
        return ExecSpResponse(
          success: false,
          error: 'Geçersiz sunucu yanıtı (${response.statusCode})',
        );
      }
      return ExecSpResponse.fromJson(json);
    } on DioException catch (e) {
      return ExecSpResponse(success: false, error: formatApiError(e));
    }
  }
}

Map<String, dynamic>? _asJsonMap(dynamic body) {
  if (body is Map<String, dynamic>) return body;
  if (body is Map) return Map<String, dynamic>.from(body);
  return null;
}

Dio createDio(
  TokenStorage tokenStorage, {
  UnauthorizedCallback? onUnauthorized,
}) {
  final options = BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  );
  final dio = Dio(options);
  // Nested refresh/retry must not go through the queued interceptor: that
  // queue waits for onResponse to finish, which is waiting for the nested call.
  final refreshDio = Dio(options);
  refreshDio.interceptors.add(AuthInterceptor(tokenStorage));

  dio.interceptors.add(AuthInterceptor(tokenStorage));
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onResponse: (response, handler) async {
        final retried = response.requestOptions.extra['authRetried'] == true;
        if (!shouldAttemptTokenRefresh(
          statusCode: response.statusCode,
          path: response.requestOptions.path,
          alreadyRetried: retried,
        )) {
          if (response.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(response);
          return;
        }

        refreshDio.httpClientAdapter = dio.httpClientAdapter;
        final refreshed = await _refreshAccessToken(refreshDio, tokenStorage);
        if (!refreshed) {
          onUnauthorized?.call();
          handler.next(response);
          return;
        }

        try {
          final retryOptions = response.requestOptions;
          retryOptions.extra['authRetried'] = true;
          final retryResponse = await refreshDio.fetch(retryOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          onUnauthorized?.call();
          handler.next(response);
        }
      },
    ),
  );
  return dio;
}

Future<bool> _refreshAccessToken(Dio dio, TokenStorage tokenStorage) async {
  final refreshToken = await tokenStorage.getRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) return false;

  try {
    final response = await dio.post(
      '/auth/exec',
      data: {
        'sp': 'Auth.RefreshToken',
        'params': {'RefreshToken': refreshToken},
      },
      options: Options(
        validateStatus: (status) => status != null && status < 600,
        extra: {'authRetried': true},
      ),
    );
    if (response.statusCode != 200) return false;
    final json = _asJsonMap(response.data);
    if (json == null) return false;
    final parsed = ExecSpResponse.fromJson(json);
    if (!parsed.success) return false;
    final data = parseAuthPayload(parsed.data);
    final accessToken = data != null ? readAuthToken(data, 'accessToken') : null;
    final nextRefresh = data != null ? readAuthToken(data, 'refreshToken') : null;
    if (accessToken == null || nextRefresh == null) return false;
    await tokenStorage.saveTokens(accessToken, nextRefresh);
    final user = data?['user'] ?? data?['User'];
    if (user is Map) {
      final role = Map<String, dynamic>.from(user).stringField('Role');
      await tokenStorage.saveRole(role);
    }
    return true;
  } catch (_) {
    return false;
  }
}
