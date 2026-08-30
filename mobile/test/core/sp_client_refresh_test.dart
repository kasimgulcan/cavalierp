import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cavalierp/core/network/sp_client.dart';
import 'package:cavalierp/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;
  String? role;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> saveRole(String? value) async {
    role = value;
  }

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<String?> getRole() async => role;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    role = null;
  }
}

class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter({this.refreshSucceeds = true});

  final bool refreshSucceeds;
  int execCalls = 0;
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path.toLowerCase();
    if (path.contains('/auth/exec')) {
      refreshCalls += 1;
      if (!refreshSucceeds) {
        return _json(401, {'success': false, 'error': 'Authentication required.'});
      }
      return _json(200, {
        'success': true,
        'data': {
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
          'user': {'Role': 'Staff'},
        },
      });
    }

    execCalls += 1;
    final auth = options.headers['Authorization']?.toString() ?? '';
    if (auth.contains('new-access')) {
      return _json(200, {
        'success': true,
        'data': [
          {'Username': 'kasim', 'Role': 'Staff'},
        ],
      });
    }
    return _json(401, {'success': false, 'error': 'Authentication required.'});
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _json(int status, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('expired access token is refreshed and the original call completes', () async {
    final storage = _MemoryTokenStorage(
      access: 'expired-access',
      refresh: 'valid-refresh',
    );
    final adapter = _RefreshAdapter();
    final dio = createDio(storage);
    dio.httpClientAdapter = adapter;
    final client = SpClient(dio);

    final response = await client.exec('Auth.GetProfile', {}).timeout(
      const Duration(seconds: 2),
    );

    expect(response.success, isTrue);
    expect(adapter.refreshCalls, 1);
    expect(adapter.execCalls, 2);
    expect(storage.access, 'new-access');
    expect(storage.refresh, 'new-refresh');
  });

  test('failed refresh logs the session out instead of hanging', () async {
    final storage = _MemoryTokenStorage(
      access: 'expired-access',
      refresh: 'stale-refresh',
    );
    var loggedOut = false;
    final adapter = _RefreshAdapter(refreshSucceeds: false);
    final dio = createDio(storage, onUnauthorized: () => loggedOut = true);
    dio.httpClientAdapter = adapter;
    final client = SpClient(dio);

    final response = await client.exec('Auth.GetProfile', {}).timeout(
      const Duration(seconds: 2),
    );

    expect(response.success, isFalse);
    expect(loggedOut, isTrue);
  });
}
