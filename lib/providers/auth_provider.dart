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
  Map<String, dynamic>? _fullUserProfile;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get fullUserProfile => _fullUserProfile;

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
      
      // Check if account type matches expected type (case-insensitive)
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

  // Get full user profile with all details
  Future<Map<String, dynamic>> getFullUserProfile() async {
    if (_user == null) {
      _errorMessage = 'User not authenticated';
      return {'success': false, 'message': 'User not authenticated'};
    }

    final response = await _directusService.getFullUserProfile(_user!.id);
    
    if (response['success']) {
      _fullUserProfile = response['data'];
      notifyListeners();
    } else {
      _errorMessage = response['message'];
    }
    
    return response;
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    if (_user == null) {
      _errorMessage = 'User not authenticated';
      return {'success': false, 'message': 'User not authenticated'};
    }

    final response = await _directusService.updateUserProfile(_user!.id, userData);
    
    if (response['success']) {
      // Update the local user data
      _user = User.fromJson(response['data']);
      
      // If we have the full profile, update that too
      if (_fullUserProfile != null) {
        _fullUserProfile = {
          ..._fullUserProfile!,
          ...response['data'],
        };
      }
      
      notifyListeners();
    } else {
      _errorMessage = response['message'];
    }
    
    return response;
  }

  // Update student profile
  Future<Map<String, dynamic>> updateStudentProfile(String studentId, Map<String, dynamic> profileData) async {
    if (_user == null || !_user!.isStudent) {
      _errorMessage = 'Not authorized to update student profile';
      return {'success': false, 'message': 'Not authorized to update student profile'};
    }

    final response = await _directusService.updateStudentProfile(studentId, profileData);
    
    if (response['success'] && _fullUserProfile != null) {
      // Check the types before updating the student profile
      final studentProfile = _fullUserProfile!['student_profile'];
      final responseData = response['data'];
      
      // Only update if both are maps
      if (studentProfile is Map && responseData is Map) {
        // Update the student profile in the full user profile with explicit typing
        _fullUserProfile!['student_profile'] = <String, dynamic>{
          ...(studentProfile as Map<String, dynamic>),
          ...(responseData as Map<String, dynamic>),
        };
      } else {
        // If not a map, just replace the whole thing
        _fullUserProfile!['student_profile'] = responseData;
      }
      
      notifyListeners();
    } else {
      _errorMessage = response['message'];
    }
    
    return response;
  }

  // Logout
  Future<void> logout() async {
    await _directusService.logout();
    _status = AuthStatus.unauthenticated;
    _user = null;
    _fullUserProfile = null;
    notifyListeners();
  }
}