import 'package:dio/dio.dart';
import 'package:ui_testing/core/error/exception.dart';

class ResponseHandler {
  Map<String, dynamic> handleResponse(Response response) {
    final token = _extractToken(response);

    if (_isSuccessful(response.statusCode)) {
      final data = _parseResponseData(response.data);

      if (token != null) {
        data['accessToken'] = token.toString();
      }

      return data;
    }

    throw ServerException(
      'Server error: ${response.statusCode} ${response.statusMessage}',
    );
  }

  /// Extract and clean token from headers
  String? _extractToken(Response response) {
    final raw = response.headers.value("x-access-token");

    if (raw == null) return null;

    return raw
        .replaceAll("[", "")
        .replaceAll("]", "")
        .replaceFirst("Bearer ", "")
        .trim();
  }

  bool _isSuccessful(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  Map<String, dynamic> _parseResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is List) {
      return {'data': data};
    } else if (data is String) {
      return {'message': data};
    }
    return {'data': data};
  }
}
