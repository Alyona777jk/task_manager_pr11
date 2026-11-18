import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';

enum TaskFilter { all, active, completed }

class TaskProvider extends ChangeNotifier {
  final TaskRepository repository;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  List<TaskModel> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isOnline = true;
  String? _error;

  TaskProvider(this.repository) {
    _initConnectivity();
  }

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;
  TaskFilter get filter => _filter;
  String get searchQuery => _searchQuery;

  // Статистика (Extra)
  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.completed).length;
  int get activeCount => _tasks.where((t) => !t.completed).length;

  /// Відфільтрований список задач з урахуванням статусу та пошуку по title
  List<TaskModel> get filteredTasks {
    return _tasks.where((task) {
      final matchesFilter = switch (_filter) {
        TaskFilter.all => true,
        TaskFilter.active => !task.completed,
        TaskFilter.completed => task.completed,
      };
      final matchesSearch = task.title
          .toLowerCase()
          .contains(_searchQuery.trim().toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  /// Відстеження стану мережі в реальному часі
  Future<void> _initConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    loadTasks();

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final onlineNow = !results.contains(ConnectivityResult.none);
      if (_isOnline != onlineNow) {
        _isOnline = onlineNow;
        notifyListeners();
        // Якщо мережа з'явилася — синхронізуємо дані
        if (_isOnline) {
          loadTasks();
        }
      }
    });
  }

  void setFilter(TaskFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Завантаження задач з API або Hive
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await repository.fetchTasks(isOnline: _isOnline);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Створення нової задачі з прив'язкою до userId
  Future<String?> addTask({
    required String title,
    required int userId,
    bool completed = false,
  }) async {
    try {
      if (_isOnline) {
        final created = await repository.createTask(
          title: title,
          userId: userId,
          completed: completed,
        );
        _tasks.insert(0, created);
      } else {
        // Локальне створення в offline режимі
        _tasks.insert(
          0,
          TaskModel(
            id: DateTime.now().millisecondsSinceEpoch,
            userId: userId,
            title: title,
            completed: completed,
          ),
        );
      }
      await repository.updateLocalCache(_tasks);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Редагування задачі або перемикання статусу
  Future<String?> updateTask(TaskModel updatedTask) async {
    try {
      if (_isOnline) {
        await repository.updateTask(updatedTask);
      }
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        await repository.updateLocalCache(_tasks);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    await updateTask(task.copyWith(completed: !task.completed));
  }

  /// Видалення задачі
  Future<String?> deleteTask(int id) async {
    try {
      if (_isOnline) {
        await repository.deleteTask(id);
      }
      _tasks.removeWhere((t) => t.id == id);
      await repository.updateLocalCache(_tasks);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
