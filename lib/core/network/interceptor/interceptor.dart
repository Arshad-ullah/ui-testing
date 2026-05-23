import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// import 'package:zeggo_crm/src/core/services/hive_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add token to headers if available
    // final token = HiveService.getTokken();
    // if (token.isNotEmpty) {
    //   options.headers['x-access-token'] = 'Bearer $token';
    // }
    super.onRequest(options, handler);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logRequest(options);
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logResponse(response);
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logError(err);
    }
    super.onError(err, handler);
  }

  void _logRequest(RequestOptions options) {
    debugPrint('╔════════════════════════════════════════════════════════════');
    debugPrint('║ REQUEST[${options.method}] => ${options.path}');
    debugPrint('║ Headers: ${options.headers}');
    debugPrint('║ Query Parameters: ${options.queryParameters}');
    if (options.data != null) {
      debugPrint('║ Data: ${options.data}');
    }
    debugPrint('╚════════════════════════════════════════════════════════════');
  }

  void _logResponse(Response response) {
    debugPrint('╔════════════════════════════════════════════════════════════');
    debugPrint(
      '║ RESPONSE[${response.statusCode}] => ${response.requestOptions.path}',
    );
    if (response.data != null) {
      debugPrint('║ Data: ${response.data}');
    }
    debugPrint('╚════════════════════════════════════════════════════════════');
  }

  void _logError(DioException err) {
    debugPrint('╔════════════════════════════════════════════════════════════');
    debugPrint(
      '║ ERROR[${err.response?.statusCode}] => ${err.requestOptions.path}',
    );
    debugPrint('║ Message: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('║ Error Data: ${err.response?.data}');
    }
    debugPrint('╚════════════════════════════════════════════════════════════');
  }
}
