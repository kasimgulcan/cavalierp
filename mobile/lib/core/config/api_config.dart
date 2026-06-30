class ApiConfig {
  /// Production: https://app.devcloud.com.tr/cavalierp/api
  /// Local dev:    http://localhost:5160
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.devcloud.com.tr/cavalierp/api',
  );
}
