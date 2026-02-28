class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server Error']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Error']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network Error']);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication Error']);

  @override
  String toString() => message;
}
