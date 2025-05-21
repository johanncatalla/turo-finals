import 'dart:convert';
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
      final normalizedAccountType = accountType.toLowerCase() == 'student' ? 'Student' : accountType;

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
          'role': normalizedAccountType == 'Student' ? 'e492a4a1-4f3f-42f2-a63e-5fa988dacb33' : null,
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
  // Fetch a tutor profile with related data for the current user
  Future<Map<String, dynamic>> fetchTutorProfile() async {
    try {
      // Get current user's access token
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }

      // Fetch the current user with expanded tutor_profile
      final response = await http.get(
        Uri.parse('$baseUrl/users/me?fields=id,first_name,last_name,email,user_type,tutor_profile.*, tutor_profile.teach_levels.TeachLevels_id.name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': responseData['errors']?[0]?['message'] ?? 'Failed to fetch user data'
        };
      }

      // Extract the data part of the response
      var userData = responseData['data'];

      if (userData == null) {
        return {
          'success': false,
          'message': 'No user data found'
        };
      }

      // If tutor_profile exists, fetch subjects separately
      if (userData['tutor_profile'] != null) {
        var tutorProfileId;

        // Handle different data structures - tutor_profile could be an object or just an ID
        if (userData['tutor_profile'] is Map) {
          tutorProfileId = userData['tutor_profile']['id'];
        } else {
          tutorProfileId = userData['tutor_profile'];
        }

        if (tutorProfileId != null) {
          // Fetch subjects for this tutor profile
          final subjectsResponse = await http.get(
            Uri.parse('$baseUrl/items/tutor_profile/$tutorProfileId?fields=*,subjects.*'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );

          if (subjectsResponse.statusCode == 200) {
            final subjectsData = jsonDecode(subjectsResponse.body);

            // If tutor_profile is just an ID in the original response, replace it with the full object
            if (!(userData['tutor_profile'] is Map)) {
              userData['tutor_profile'] = subjectsData['data'];
            }
            // If it's already a map, add the subjects to it
            else if (subjectsData['data'] != null && subjectsData['data']['subjects'] != null) {
              userData['tutor_profile']['subjects'] = subjectsData['data']['subjects'];
            }
          }
        }
      }
      print(userData);
      // Return the processed user data
      return {
        'success': true,
        'data': userData
      };
    } catch (e) {
      print('Error in fetchTutorProfile: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

// Fetch a tutor profile with related data by user ID
  // Fetch a tutor profile with related data by user ID using the user's token
  Future<Map<String, dynamic>> fetchTutorProfileByUserId(String userId) async {
    try {
      // Get current user's access token
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }

      // First, get the tutor_profile relation for this user
      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/me?fields=id,first_name,last_name,email,user_type,tutor_profile.*,tutor_profile.subjects.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final userData = jsonDecode(userResponse.body);

      if (userResponse.statusCode != 200) {
        return {
          'success': false,
          'message': userData['errors']?[0]?['message'] ?? 'Failed to fetch user data'
        };
      }

      // Return the complete data
      return {
        'success': true,
        'data': userData['data']
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }
}
