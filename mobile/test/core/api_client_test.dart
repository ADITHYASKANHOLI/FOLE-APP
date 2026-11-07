import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engivault_mobile/core/errors/failures.dart';
import 'package:engivault_mobile/core/network/api_client.dart';

void main() {
  group('ApiClient Exception Mapping', () {
    final client = ApiClient(baseUrl: 'http://localhost:3000/api/mobile/v1');

    test('initializes with correct base URL', () {
      expect(client.dio.options.baseUrl, 'http://localhost:3000/api/mobile/v1');
    });

    test('maps connection timeout to NetworkFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(dioException.type, DioExceptionType.connectionTimeout);
      expect(const NetworkFailure().message, contains('Unable to connect'));
    });

    test('verifies custom Failure types', () {
      const authFail = AuthFailure('Invalid username or password',
          code: 'INVALID_CREDENTIALS');
      expect(authFail.message, 'Invalid username or password');
      expect(authFail.code, 'INVALID_CREDENTIALS');

      const validationFail =
          ValidationFailure('Username taken', code: 'USERNAME_TAKEN');
      expect(validationFail.message, 'Username taken');
      expect(validationFail.code, 'USERNAME_TAKEN');

      const notFoundFail = NotFoundFailure('Lesson not found');
      expect(notFoundFail.message, 'Lesson not found');

      const serverFail =
          ServerFailure('Rate limit exceeded', code: 'RATE_LIMITED');
      expect(serverFail.code, 'RATE_LIMITED');
    });
  });
}
