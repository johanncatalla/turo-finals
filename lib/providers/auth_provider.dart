import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turo/services/directus_service.dart';
import 'package:turo/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  final DirectusService _directusService = DirectusService();
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Check authentication status when app starts
    checkAuthStatus();
  }

  // Check if user is logged in
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.containsKey('accessToken');
    
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
      return;
    }

    // Check if token is valid and not expired
    if (await _directusService.refreshTokenIfNeeded()) {
      final response = await _directusService.getCurrentUser();
      
      if (response['success']) {
        _user = User.fromJson(response['data']);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
        _user = null;
      }
    } else {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    
    notifyListeners();
  }

  // Login with email and password
  Future<bool> login(String email, String password, String expectedAccountType) async {
    _errorMessage = null;
    final response = await _directusService.login(email, password);
    
    if (response['success']) {
      final userData = response['data']['data'];
      _user = User.fromJson(userData);
      
      // Check if account type matches expected type
      if (_user!.accountType.toLowerCase() != expectedAccountType.toLowerCase()) {
        _errorMessage = 'This account is not registered as a $expectedAccountType';
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
        return false;
      }
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['message'];
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Register a new user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String accountType,
  }) async {
    _errorMessage = null;
    final response = await _directusService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      accountType: accountType,
    );
    
    if (response['success']) {
      final userData = response['data']['data'];
      _user = User.fromJson(userData);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['message'];
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _directusService.logout();
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }
}