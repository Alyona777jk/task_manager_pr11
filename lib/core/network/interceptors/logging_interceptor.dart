import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor для логування всіх HTTP-запитів, відповідей та помилок у консоль
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('--> [${options.method}] ${options.uri}');
    if (options.data != null) {
      debugPrint('Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('<-- [${response.statusCode}] ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('ERR [${err.response?.statusCode}] ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}
