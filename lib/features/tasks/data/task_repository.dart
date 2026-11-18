import 'package:dio/dio.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/cache_service.dart';
import '../domain/task_model.dart';

/// Репозиторій задач з підтримкою CRUD через JSONPlaceholder та кешуванням у Hive
class TaskRepository {
  final Dio dio;
  final CacheService cacheService;

  TaskRepository({required this.dio, required this.cacheService});

  /// Отримання задач: спочатку з мережі + збереження в Hive;
  /// при відсутності мережі — повернення з кешу
  Future<List<TaskModel>> fetchTasks({required bool isOnline}) async {
    if (!isOnline) {
      final cached = cacheService.getCachedTasks();
      if (cached != null) {
        return cached.map((e) => TaskModel.fromJson(e)).toList();
      }
      throw AppException('Немає підключення до мережі та збереженого кешу.');
    }

    try {
      // Завантажуємо задачі (обмежуємо 30 елементами для зручності)
      final response = await dio.get(
        ApiEndpoints.todos,
        queryParameters: {'_limit': 30},
      );

      final List<dynamic> data = response.data;
      final tasks = data
          .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Кешуємо свіжі дані у Hive
      await cacheService.cacheTasks(tasks.map((t) => t.toJson()).toList());
      return tasks;
    } on DioException catch (e) {
      // Fallback на кеш, якщо запит впав
      final cached = cacheService.getCachedTasks();
      if (cached != null) {
        return cached.map((e) => TaskModel.fromJson(e)).toList();
      }
      throw AppException.fromDioError(e);
    }
  }

  /// Створення нової задачі (POST)
  Future<TaskModel> createTask({
    required String title,
    required int userId,
    bool completed = false,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.todos,
        data: {
          'title': title,
          'userId': userId,
          'completed': completed,
        },
      );
      // JSONPlaceholder завжди повертає id: 201, тому генеруємо унікальний локальний ID
      final created = TaskModel.fromJson(response.data).copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        title: title,
        completed: completed,
      );
      return created;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Оновлення задачі або зміна статусу (PATCH/PUT)
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      // Для нових локально створених ID (> 200) JSONPlaceholder повертає 500 на PUT,
      // тому робимо запит тільки для існуючих на сервері ID або обробляємо коректно
      if (task.id <= 200) {
        await dio.put(
          ApiEndpoints.todoById(task.id),
          data: task.toJson(),
        );
      }
      return task;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Видалення задачі (DELETE)
  Future<void> deleteTask(int id) async {
    try {
      if (id <= 200) {
        await dio.delete(ApiEndpoints.todoById(id));
      }
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Оновлення локального кешу після змін
  Future<void> updateLocalCache(List<TaskModel> currentTasks) async {
    await cacheService.cacheTasks(currentTasks.map((t) => t.toJson()).toList());
  }
}
