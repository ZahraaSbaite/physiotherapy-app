import 'package:dio/dio.dart';

import '../utils/app_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

typedef JsonMap = Map<String, dynamic>;

class ApiClient {
  ApiClient(this._tokenStorage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final hadToken = error.requestOptions.headers.containsKey(
            'Authorization',
          );
          if (error.response?.statusCode == 401 && hadToken) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;

  void Function()? onUnauthorized;

  Future<JsonMap> get(String path, {JsonMap? query}) =>
      _send('GET', path, query: query);

  Future<JsonMap> post(String path, {Object? data}) =>
      _send('POST', path, data: data);

  Future<JsonMap> put(String path, {Object? data}) =>
      _send('PUT', path, data: data);

  Future<JsonMap> patch(String path, {Object? data}) =>
      _send('PATCH', path, data: data);

  Future<JsonMap> delete(String path, {Object? data}) =>
      _send('DELETE', path, data: data);

  Future<JsonMap> _send(
    String method,
    String path, {
    Object? data,
    JsonMap? query,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
      final body = response.data;
      return body is JsonMap ? body : <String, dynamic>{};
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          "Can't reach the server. Check your internet connection.",
        );
      case DioExceptionType.badResponse:
        {
          final status = e.response?.statusCode;
          final data = e.response?.data;
          final message =
              data is Map && data['message'] is String
                  ? data['message'] as String
                  : 'Something went wrong (code $status)';
          return ApiException(message, statusCode: status);
        }
      default:
        return ApiException(
          'Something went wrong. Please try again.',
        );
    }
  }
}
