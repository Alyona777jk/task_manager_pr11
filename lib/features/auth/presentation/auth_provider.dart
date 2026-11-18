import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../domain/user_entity.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository;

  UserEntity? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  AuthProvider(this.repository) {
    _initAutoLogin();
  }

  UserEntity? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  /// Автоматичний вхід при старті додатку, якщо є JWT у SecureStorage
  Future<void> _initAutoLogin() async {
    _user = await repository.checkSavedSession();
    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await repository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await repository.register(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    _user = null;
    notifyListeners();
  }
}
