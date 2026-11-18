import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor для автоматичного повтору невдалих запитів (при таймаутах або 5xx)
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 2});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = (err.requestOptions.extra['retry_count'] as int?) ?? 0;

    final shouldRetry = retryCount < maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            (err.response?.statusCode != null &&
                err.response!.statusCode! >= 500));

    if (shouldRetry) {
      final nextRetry = retryCount + 1;
      debugPrint('Retry ($nextRetry/$maxRetries) for ${err.requestOptions.uri}');
      await Future.delayed(Duration(milliseconds: 500 * nextRetry));

      final options = err.requestOptions;
      options.extra['retry_count'] = nextRetry;

      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    handler.next(err);
  }
}
