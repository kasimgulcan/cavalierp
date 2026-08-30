import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/core/network/auth_refresh.dart';

void main() {
  test('refreshes expired API calls but not auth endpoints', () {
    expect(
      shouldAttemptTokenRefresh(
        statusCode: 401,
        path: '/exec',
        alreadyRetried: false,
      ),
      isTrue,
    );
    expect(
      shouldAttemptTokenRefresh(
        statusCode: 401,
        path: '/auth/exec',
        alreadyRetried: false,
      ),
      isFalse,
    );
    expect(
      shouldAttemptTokenRefresh(
        statusCode: 401,
        path: '/exec',
        alreadyRetried: true,
      ),
      isFalse,
    );
    expect(
      shouldAttemptTokenRefresh(
        statusCode: 403,
        path: '/exec',
        alreadyRetried: false,
      ),
      isFalse,
    );
  });
}
