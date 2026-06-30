import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

String formatApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['error'] ?? data['Error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (error.response?.statusCode != null) {
      return 'Sunucu hatası (${error.response!.statusCode})';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Bağlantı zaman aşımı';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Sunucuya bağlanılamadı';
    }
    return error.message ?? 'Ağ hatası';
  }
  return error.toString();
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
