import 'package:dio/dio.dart';
import '../storage/cache_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Налаштований екземпляр Dio з підключеними перехоплювачами
class DioClient {
  late final Dio dio;

  DioClient(CacheService cacheService) {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(cacheService: cacheService, dio: dio),
      RetryInterceptor(dio: dio),
      LoggingInterceptor(),
    ]);
  }
}
