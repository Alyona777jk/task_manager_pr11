import 'package:dio/dio.dart';

/// Кастомний клас винятків для уніфікованої обробки мережевих та локальних помилок
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  /// Перетворення помилок Dio у зрозумілі для користувача повідомлення
  factory AppException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException('Час очікування відповіді від сервера вичерпано.');
      case DioExceptionType.connectionError:
        return AppException('Відсутнє підключення до Інтернету.');
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final serverMsg = error.response?.data is Map
            ? error.response?.data['error']
            : null;
        if (status == 400) {
          return AppException(serverMsg ?? 'Невірний запит (перевірте дані).', 400);
        } else if (status == 401) {
          return AppException('Помилка авторизації. Увійдіть знову.', 401);
        } else if (status == 404) {
          return AppException('Ресурс не знайдено.', 404);
        } else if (status != null && status >= 500) {
          return AppException('Помилка сервера ($status). Спробуйте пізніше.', status);
        }
        return AppException(serverMsg ?? 'Помилка сервера: $status', status);
      case DioExceptionType.cancel:
        return AppException('Запит було скасовано.');
      default:
        return AppException('Невідома мережева помилка.');
    }
  }

  @override
  String toString() => message;
}
