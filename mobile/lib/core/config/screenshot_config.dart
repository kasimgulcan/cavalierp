/// CI screenshot tour (flutter run + simctl screenshot). Not used in production builds.
///
/// Each screen is captured by a separate `flutter run` invocation with its own
/// `--dart-define` values (compile-time constants), reusing a prebuilt native
/// app shell via `--use-application-binary` for speed. Runtime environment
/// variables (e.g. via `simctl launch SIMCTL_CHILD_*`) are NOT used because
/// they don't reliably reach GUI apps launched via SpringBoard.
class ScreenshotConfig {
  static const route = String.fromEnvironment('SCREENSHOT_ROUTE');
  static const tabIndex = int.fromEnvironment('SCREENSHOT_TAB', defaultValue: 0);
  static const autoLogin = bool.fromEnvironment('SCREENSHOT_AUTO_LOGIN');
  static const email = String.fromEnvironment('SCREENSHOT_EMAIL');
  static const password = String.fromEnvironment('SCREENSHOT_PASSWORD');

  static bool get enabled => route.isNotEmpty;
}
