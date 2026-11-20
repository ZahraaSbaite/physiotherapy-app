import 'package:dio/dio.dart';

/// Wraps an API call and turns Dio failures into a readable Exception.
/// Swap for the project's ApiException if it exposes a Dio factory.
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    final data = e.response?.data;
    final msg = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Something went wrong. Check your connection and try again.';
    throw Exception(msg);
  }
}

/// Reads `body[key]` (or `body['data']`) when the API wraps its payload,
/// otherwise returns the body itself.
dynamic unwrap(dynamic body, String key) =>
    body is Map ? (body[key] ?? body['data'] ?? body) : body;
