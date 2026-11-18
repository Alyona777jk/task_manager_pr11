import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _tasksBoxName = 'tasks_cache_box';
  static const String _tasksCacheKey = 'cached_todos';
  static const String _tokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _userEmailKey = 'user_email';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_tasksBoxName);
  }

  Future<void> saveAuthData({
    required String token,
    String? refreshToken,
    required String email,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _secureStorage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getToken() async => await _secureStorage.read(key: _tokenKey);

  Future<String?> getRefreshToken() async =>
      await _secureStorage.read(key: _refreshTokenKey);

  Future<String?> getUserEmail() async =>
      await _secureStorage.read(key: _userEmailKey);

  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userEmailKey);
  }

  Future<void> cacheTasks(List<Map<String, dynamic>> tasksJson) async {
    await _box.put(_tasksCacheKey, jsonEncode(tasksJson));
  }

  List<Map<String, dynamic>>? getCachedTasks() {
    final raw = _box.get(_tasksCacheKey);
    if (raw == null) return null;
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }
}
