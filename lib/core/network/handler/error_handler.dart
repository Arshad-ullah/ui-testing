import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ui_testing/core/error/exception.dart';

class ErrorHandler {
  /// Handles errors and converts them to AppException
  AppException handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    }
    return ServerException(error.toString());
  }

  /// Handle DioException based on type
  AppException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _handleTimeoutError();

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.connectionError:
        return _handleConnectionError(error);

      case DioExceptionType.cancel:
        return const ServerException('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const ServerException('Certificate verification failed.');

      case DioExceptionType.unknown:
        return _handleUnknownError(error);
    }
  }

  /// Handle timeout errors
  AppException _handleTimeoutError() {
    return const TimeoutException('Request timeout. Please try again.');
  }

  /// Handle API error response and extract meaningful message
  AppException _handleBadResponse(DioException error) {
    final data = error.response?.data;

    String extractErrorMessage() {
      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message is List) {
          return message
              .map((e) {
                if (e is Map<String, dynamic>) {
                  final field = e['field'] ?? '';
                  final msg = e['message'] ?? '';
                  return "$field: $msg";
                }
                return e.toString();
              })
              .join("\n");
        }

        if (message is String && message.isNotEmpty) {
          return message;
        }
      }

      return 'Server error occurred';
    }

    return ServerException(extractErrorMessage());
  }

  /// Handle connection errors
  AppException _handleConnectionError(DioException error) {
    if (error.error is SocketException) {
      return const NetworkException(
        'No internet connection. Please check your network.',
      );
    }
    return const ServerException(
      'Connection error. Please check your internet connection.',
    );
  }

  /// Handle unknown errors
  AppException _handleUnknownError(DioException error) {
    if (error.error is SocketException) {
      return const NetworkException(
        'No internet connection. Please check your network.',
      );
    }
    return ServerException(error.message ?? 'An unexpected error occurred');
  }
}
