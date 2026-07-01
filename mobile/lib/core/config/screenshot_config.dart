import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// CI screenshot tour. Not used in production builds.
///
/// Tour builds are compiled with `--dart-define=SCREENSHOT_TOUR=true`. Before
/// each launch the shell writes `Documents/screenshot_config.json` into the
/// app container; [init] reads it at startup. This avoids both the broken
/// `simctl launch` env-var path and the fact that `--dart-define` values are
/// ignored when reusing a binary via `--use-application-binary`.
class ScreenshotConfig {
  static const tourMode = bool.fromEnvironment('SCREENSHOT_TOUR');

  static const _compileRoute = String.fromEnvironment('SCREENSHOT_ROUTE');
  static const _compileTab =
      int.fromEnvironment('SCREENSHOT_TAB', defaultValue: 0);
  static const _compileAutoLogin =
      bool.fromEnvironment('SCREENSHOT_AUTO_LOGIN');
  static const _compileEmail = String.fromEnvironment('SCREENSHOT_EMAIL');
  static const _compilePassword =
      String.fromEnvironment('SCREENSHOT_PASSWORD');

  static String route = _compileRoute;
  static int tabIndex = _compileTab;
  static bool autoLogin = _compileAutoLogin;
  static String email = _compileEmail;
  static String password = _compilePassword;

  static bool get enabled => tourMode || route.isNotEmpty;

  static Future<void> init() async {
    if (!tourMode) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/screenshot_config.json');
      if (!await file.exists()) {
        route = '/login';
        return;
      }

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      route = json['route'] as String? ?? '/login';
      tabIndex = json['tab'] as int? ?? 0;
      autoLogin = json['autoLogin'] as bool? ?? false;
      email = json['email'] as String? ?? '';
      password = json['password'] as String? ?? '';
    } catch (e) {
      route = '/login';
      autoLogin = false;
    }
  }
}
