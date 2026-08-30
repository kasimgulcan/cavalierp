bool shouldAttemptTokenRefresh({
  required int? statusCode,
  required String path,
  required bool alreadyRetried,
}) {
  if (statusCode != 401 || alreadyRetried) return false;
  final normalized = path.toLowerCase();
  if (normalized.contains('/auth/exec')) return false;
  return true;
}
