import 'dart:io' show Platform;

/// CI screenshot tour (simctl launch + env vars). Not used in production builds.
class ScreenshotConfig {
  static const tourEnabled = bool.fromEnvironment('SCREENSHOT_TOUR');

  static const _compileRoute = String.fromEnvironment('SCREENSHOT_ROUTE');
  static const _compileTab =
      int.fromEnvironment('SCREENSHOT_TAB', defaultValue: 0);
  static const _compileAutoLogin =
      bool.fromEnvironment('SCREENSHOT_AUTO_LOGIN');
  static const _compileEmail = String.fromEnvironment('SCREENSHOT_EMAIL');
  static const _compilePassword =
      String.fromEnvironment('SCREENSHOT_PASSWORD');

  static String get route {
    if (tourEnabled) {
      return _envString('SCREENSHOT_ROUTE', fallback: '/login');
    }
    return _compileRoute;
  }

  static int get tabIndex {
    if (tourEnabled) {
      return _envInt('SCREENSHOT_TAB', fallback: _compileTab);
    }
    return _compileTab;
  }

  static bool get autoLogin {
    if (tourEnabled) {
      return _envBool('SCREENSHOT_AUTO_LOGIN', fallback: _compileAutoLogin);
    }
    return _compileAutoLogin;
  }

  static String get email {
    if (tourEnabled) {
      return _envString('SCREENSHOT_EMAIL', fallback: _compileEmail);
    }
    return _compileEmail;
  }

  static String get password {
    if (tourEnabled) {
      return _envString('SCREENSHOT_PASSWORD', fallback: _compilePassword);
    }
    return _compilePassword;
  }

  static bool get enabled => tourEnabled || _compileRoute.isNotEmpty;

  static String _envString(String key, {String fallback = ''}) {
    final value = Platform.environment[key]?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  static int _envInt(String key, {int fallback = 0}) {
    return int.tryParse(Platform.environment[key] ?? '') ?? fallback;
  }

  static bool _envBool(String key, {bool fallback = false}) {
    final value = Platform.environment[key]?.toLowerCase();
    if (value == null || value.isEmpty) return fallback;
    return value == 'true' || value == '1' || value == 'yes';
  }
}
