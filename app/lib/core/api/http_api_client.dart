import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../socket/socket_client.dart';

class HttpApiClient {
  HttpApiClient(this.session)
    : _dio = Dio(
        BaseOptions(
          baseUrl: '${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
        ),
      );

  final SocketClient session;
  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) {
    return _request<T>('GET', path, query: query);
  }

  Future<T> post<T>(String path, {Object? data}) {
    return _request<T>('POST', path, data: data);
  }

  Future<T> put<T>(String path, {Object? data}) {
    return _request<T>('PUT', path, data: data);
  }

  Future<T> patch<T>(String path, {Object? data}) {
    return _request<T>('PATCH', path, data: data);
  }

  Future<T> delete<T>(String path, {Object? data}) {
    return _request<T>('DELETE', path, data: data);
  }

  Future<T> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? data,
    bool retryAuth = true,
  }) async {
    final refreshedToken = await session.onBeforeRequest?.call();
    final token = refreshedToken ?? session.token;
    try {
      final response = await _dio.request<dynamic>(
        _normalizePath(path),
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
      return _unwrap<T>(response.data);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (retryAuth &&
          (status == 401 || status == 403) &&
          session.onAuthError != null &&
          await session.onAuthError!()) {
        return _request<T>(
          method,
          path,
          query: query,
          data: data,
          retryAuth: false,
        );
      }
      throw HttpApiException(_errorMessage(error), statusCode: status);
    }
  }

  T _unwrap<T>(dynamic body) {
    if (body is Map) {
      final envelope = Map<String, dynamic>.from(body);
      final message = envelope['message'];
      if (message is String) session.rememberMessage(message);
      if (envelope.containsKey('data')) return envelope['data'] as T;
    }
    return body as T;
  }

  String _normalizePath(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return normalized.startsWith('api/')
        ? normalized.substring('api/'.length)
        : normalized;
  }

  String _errorMessage(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      final message = body['message'];
      if (message is List) return message.join(', ');
      if (message != null) return message.toString();
      final nested = body['error'];
      if (nested != null) return nested.toString();
    }
    return error.message ?? 'Não foi possível acessar o servidor.';
  }
}

class HttpApiException implements Exception {
  const HttpApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
