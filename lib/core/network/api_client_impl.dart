import 'package:dio/dio.dart';
import 'package:ui_testing/core/network/api_client.dart';
import 'package:ui_testing/core/network/api_end_points.dart';
import 'package:ui_testing/core/network/handler/error_handler.dart';
import 'package:ui_testing/core/network/handler/response_handler.dart';
import 'package:ui_testing/core/network/interceptor/interceptor.dart';

class ApiClientImpl implements ApiClient {
  final Dio _dio;
  final ResponseHandler _responseHandler;
  final ErrorHandler _errorHandler;

  ApiClientImpl({
    required Dio dio,
    ResponseHandler? responseHandler,
    ErrorHandler? errorHandler,
  }) : _dio = dio,
       _responseHandler = responseHandler ?? ResponseHandler(),
       _errorHandler = errorHandler ?? ErrorHandler() {
    _setupDio();
  }

  void _setupDio() {
    // Set base options including timeouts and baseUrl
    _dio.options.baseUrl = ApiEndPoints.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.responseType = ResponseType.json;

    // Add interceptors
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      return _responseHandler.handleResponse(response);
    } catch (e) {
      throw _errorHandler.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      return _responseHandler.handleResponse(response);
    } catch (e) {
      throw _errorHandler.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return _responseHandler.handleResponse(response);
    } catch (e) {
      throw _errorHandler.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return _responseHandler.handleResponse(response);
    } catch (e) {
      throw _errorHandler.handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      return _responseHandler.handleResponse(response);
    } catch (e) {
      throw _errorHandler.handleError(e);
    }
  }
}
