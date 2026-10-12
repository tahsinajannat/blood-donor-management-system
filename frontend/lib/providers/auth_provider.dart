import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storage = StorageService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<void> bootstrap() async {
    final token = await _storage.getToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _userService.getProfile();
      status = AuthStatus.authenticated;
    } catch (_) {
      await _storage.clearSession();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _authService.login(email: email, password: password);
      final token = res['access_token'] as String;
      await _storage.saveToken(token);
      final userJson = res['user'] as Map;
      await _storage.saveUserId(userJson['id']);
      currentUser = await _userService.getProfile();
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String bloodGroup,
    required String password,
    String? area,
    String? road,
    String? city,
    String? dateOfBirth,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authService.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        bloodGroup: bloodGroup,
        password: password,
        area: area,
        road: road,
        city: city,
        dateOfBirth: dateOfBirth,
      );
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      currentUser = await _userService.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await _storage.clearSession();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
