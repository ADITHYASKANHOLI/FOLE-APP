class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(
      [super.message =
          'Unable to connect to the server. Please check your internet connection.'])
      : super(code: 'NETWORK_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(
      [super.message = 'The requested resource was not found.'])
      : super(code: 'NOT_FOUND');
}
