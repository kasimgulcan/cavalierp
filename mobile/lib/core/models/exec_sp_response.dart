class ExecSpResponse {
  final bool success;
  final dynamic data;
  final String? error;

  ExecSpResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ExecSpResponse.fromJson(Map<String, dynamic> json) => ExecSpResponse(
        success: json['success'] as bool? ?? json['Success'] as bool? ?? false,
        data: json['data'] ?? json['Data'],
        error: json['error'] as String? ?? json['Error'] as String?,
      );
}
