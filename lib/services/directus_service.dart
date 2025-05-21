import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DirectusService {
  final String? baseUrl = dotenv.env['DIRECTUS_API_URL']; 
  
  // Singleton pattern
  static final DirectusService _instance = DirectusService._internal();
  factory DirectusService() => _instance;
  DirectusService._internal();

  // User login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Save tokens to SharedPreferences
        await _saveAuthData(data['data']);
        
        // Get user data to verify account type
        final userData = await getCurrentUser();
        return {
          'success': true,
          'data': userData,
        };
      } else {
        return {
          'success': false, 
          'message': data['errors']?[0]?['message'] ?? 'Authentication failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // User registration
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String accountType,
  }) async {
    try {
      // Normalize accountType to handle both lowercase and uppercase
      final normalizedAccountType = accountType.toLowerCase() == 'student' ? 'Student' : 
                                   accountType.toLowerCase() == 'tutor' ? 'Tutor' : accountType;
      
      // Use admin token to create user (this should be configured in your .env file)
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'user_type': normalizedAccountType,
          'role': normalizedAccountType == 'Student' ? 'e492a4a1-4f3f-42f2-a63e-5fa988dacb33' : 
                 normalizedAccountType == 'Tutor' ? 'f3742571-de1f-4a19-a249-743834adb070' : null,
          'status': 'active', // Set status to active for immediate access
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // After registration, log the user in
        return await login(email, password);
      } else {
        return {
          'success': false, 
          'message': data['errors']?[0]?['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get current user data
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      
      if (accessToken == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false, 
          'message': data['errors']?[0]?['message'] ?? 'Failed to fetch user data'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update user profile 
  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      // Use admin token for guaranteed access
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }
      
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(userData),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false, 
          'message': data['errors']?[0]?['message'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get full user profile including student/tutor specific data
  Future<Map<String, dynamic>> getFullUserProfile(String userId) async {
    try {
      // Use admin token for guaranteed access
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      // First, get basic user data
      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      final userData = jsonDecode(userResponse.body);
      
      if (userResponse.statusCode != 200) {
        return {
          'success': false, 
          'message': userData['errors']?[0]?['message'] ?? 'Failed to fetch user data'
        };
      }

      final userType = userData['data']['user_type'];
      Map<String, dynamic> profileData = userData['data'];

      // If user is a student, get student profile data
      if (userType == 'Student') {
        final studentResponse = await http.get(
          Uri.parse('$baseUrl/items/Students?filter={"user_id":"$userId"}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $adminToken',
          },
        );

        final studentData = jsonDecode(studentResponse.body);
        
        if (studentResponse.statusCode == 200 && studentData['data'].isNotEmpty) {
          profileData['student_profile'] = studentData['data'][0];
        }
      }

      return {'success': true, 'data': profileData};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  
  // Update student profile (in the Students collection)
  Future<Map<String, dynamic>> updateStudentProfile(String studentId, Map<String, dynamic> profileData) async {
    try {
      // Use admin token for guaranteed access
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/items/Students/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(profileData),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false, 
          'message': data['errors']?[0]?['message'] ?? 'Failed to update student profile'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Save authentication data to SharedPreferences
  Future<void> _saveAuthData(Map<String, dynamic> authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', authData['access_token']);
    await prefs.setString('refreshToken', authData['refresh_token']);
    
    // Calculate expiration time
    final expiresAt = DateTime.now().add(Duration(seconds: authData['expires'])).millisecondsSinceEpoch;
    await prefs.setInt('expiresAt', expiresAt);
  }

  // Clear authentication data (for logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('expiresAt');
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt('expiresAt');
    
    if (expiresAt == null) return true;
    
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  // Get the full URL for a Directus asset
  String getAssetUrl(dynamic assetId) {
    if (assetId == null) return '';
    
    // Get admin token for authentication
    final adminToken = dotenv.env['ADMIN_TOKEN'];
    if (adminToken == null) return '';
    
    // Add token as query parameter for authentication
    return '$baseUrl/assets/$assetId?access_token=$adminToken';
  }

  // Upload a file to Directus
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/files'));
      
      // Add the file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      
      final multipartFile = http.MultipartFile(
        'file', 
        fileStream, 
        fileLength,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      
      request.files.add(multipartFile);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $adminToken';
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false, 
          'message': data['errors']?[0]?['message'] ?? 'Failed to upload file'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Refresh the token if expired
  Future<bool> refreshTokenIfNeeded() async {
    if (await isTokenExpired()) {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');
      
      if (refreshToken == null) return false;
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'refresh_token': refreshToken,
          }),
        );

        final data = jsonDecode(response.body);
        
        if (response.statusCode == 200) {
          await _saveAuthData(data['data']);
          return true;
        } else {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    
    return true;
  }
}
