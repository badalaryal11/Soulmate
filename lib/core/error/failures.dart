abstract class Failure implements Exception {
  final String message;

  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  AuthFailure(super.message);
}
