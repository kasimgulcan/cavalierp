import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      final bearer = 'Bearer $token';
      options.headers['Authorization'] = bearer;
      // IIS bazen Authorization header'ını düşürür; yedek header.
      options.headers['X-Authorization'] = bearer;
    }
    handler.next(options);
  }
}
