import 'package:dio/dio.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/cache_service.dart';
import '../domain/user_entity.dart';

/// Репозиторій авторизації через ReqRes API
class AuthRepository {
  final Dio dio;
  final CacheService cacheService;

  AuthRepository({required this.dio, required this.cacheService});

  /// Логін через ReqRes API
  Future<UserEntity> login(String email, String password) async {
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      await cacheService.saveAuthData(
        token: token,
        refreshToken: 'refresh_$token',
        email: email,
      );

      // Прив'язуємо до userId = 1 (стандартний ID у JSONPlaceholder)
      return UserEntity(id: 1, email: email, token: token);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Реєстрація через ReqRes API
  Future<UserEntity> register(String email, String password) async {
    try {
      final response = await dio.post(
        ApiEndpoints.register,
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      final id = response.data['id'] as int? ?? 1;
      await cacheService.saveAuthData(
        token: token,
        refreshToken: 'refresh_$token',
        email: email,
      );

      return UserEntity(id: id, email: email, token: token);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Перевірка збереженої сесії для auto-login
  Future<UserEntity?> checkSavedSession() async {
    final token = await cacheService.getToken();
    final email = await cacheService.getUserEmail();
    if (token != null && token.isNotEmpty && email != null) {
      return UserEntity(id: 1, email: email, token: token);
    }
    return null;
  }

  Future<void> logout() async {
    await cacheService.clearAuthData();
  }
}
