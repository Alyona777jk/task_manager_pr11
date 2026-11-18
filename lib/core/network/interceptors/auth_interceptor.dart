import 'package:dio/dio.dart';
import '../../storage/cache_service.dart';

/// Interceptor для автоматичного додавання JWT токена до заголовків
/// та оновлення токена (refresh flow) при отриманні помилки 401 Unauthorized
class AuthInterceptor extends Interceptor {
  final CacheService cacheService;
  final Dio dio;

  AuthInterceptor({required this.cacheService, required this.dio});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Додаємо API ключ для ReqRes (вимога ReqRes v2 для уникнення лімітів)
    if (options.uri.host.contains('reqres.in')) {
      options.headers['x-api-key'] = 'reqres-free-v1';
    }

    final token = await cacheService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Обробка простроченого токена (401) та спроба оновлення
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.extra.containsKey('retried')) {
      final refreshToken = await cacheService.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Симуляція запиту оновлення токена (оскільки ReqRes не має /refresh)
          final newToken = 'refreshed_${DateTime.now().millisecondsSinceEpoch}';
          final email = await cacheService.getUserEmail() ?? 'user@reqres.in';

          await cacheService.saveAuthData(
            token: newToken,
            refreshToken: refreshToken,
            email: email,
          );

          // Повторюємо оригінальний запит з новим токеном
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          opts.extra['retried'] = true;

          final cloneReq = await dio.fetch(opts);
          return handler.resolve(cloneReq);
        } catch (_) {
          await cacheService.clearAuthData();
        }
      }
    }
    handler.next(err);
  }
}
