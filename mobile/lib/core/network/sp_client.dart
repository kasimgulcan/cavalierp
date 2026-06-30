import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/exec_sp_response.dart';
import '../storage/token_storage.dart';
import 'api_error.dart';
import 'auth_interceptor.dart';

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
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  dio.interceptors.add(AuthInterceptor(tokenStorage));
  if (onUnauthorized != null) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.statusCode == 401) {
            onUnauthorized();
          }
          handler.next(response);
        },
      ),
    );
  }
  return dio;
}
