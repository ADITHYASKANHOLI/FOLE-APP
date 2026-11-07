import 'package:dio/dio.dart';
import '../errors/failures.dart';
import '../storage/secure_storage_service.dart';
import '../../app/config/app_config.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storageService;

  ApiClient({SecureStorageService? storageService, String? baseUrl})
      : _storageService = storageService ?? SecureStorageService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Student or Admin Bearer Token if available
          final accessToken = await _storageService.getAccessToken();
          final adminToken = await _storageService.getAdminToken();

          final token = accessToken ?? adminToken;
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Failure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final response = e.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;
      String message = 'An unexpected server error occurred.';
      String? code;

      if (data is Map<String, dynamic>) {
        message = data['error']?.toString() ?? message;
        code = data['code']?.toString();
      }

      if (statusCode == 401) {
        return AuthFailure(message, code: code ?? 'UNAUTHORIZED');
      } else if (statusCode == 403) {
        return AuthFailure(message, code: code ?? 'FORBIDDEN');
      } else if (statusCode == 400) {
        return ValidationFailure(message, code: code ?? 'VALIDATION_FAILED');
      } else if (statusCode == 404) {
        return NotFoundFailure(message);
      } else if (statusCode == 429) {
        return ServerFailure(message, code: 'RATE_LIMITED');
      } else if (statusCode == 503) {
        return ServerFailure(message, code: 'SERVICE_UNAVAILABLE');
      }

      return ServerFailure(message, code: code);
    }

    return Failure(e.message ?? 'An unknown error occurred.');
  }
}
