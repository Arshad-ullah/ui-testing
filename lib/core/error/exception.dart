/// Base exception class for all custom exceptions in the application
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when there's a server-related error
class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred']);
}

/// Exception thrown when there's a cache-related error
class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred']);
}

/// Exception thrown when there's no network connection
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation error occurred']);
}

/// Exception thrown when user is not authorized
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized access']);
}

/// Exception thrown when a timeout occurs
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timeout']);
}

/// Exception thrown when response format is invalid
class FormatException extends AppException {
  const FormatException([super.message = 'Invalid response format']);
}
