import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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
  Future<Map<String, dynamic>> uploadFile(dynamic file) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }
      
      // Create a multipart request
      var uri = Uri.parse('$baseUrl/files');
      var request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $adminToken',
      });

      // Handle different file types based on platform
      if (kIsWeb) {
        // For web platform, handle XFile or similar web-compatible file types
        if (file is XFile) {
          print('Handling web XFile upload');
          final bytes = await file.readAsBytes();
          final fileName = file.name;

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            )
          );
        } else {
          return {'success': false, 'message': 'Unsupported file type for web'};
        }
      } else {
        // For native platforms, handle File objects
        if (file is File) {
          print('Handling native File upload');
          final bytes = await file.readAsBytes();
          final fileName = file.path.split('/').last;

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            )
          );
        } else {
          return {'success': false, 'message': 'Unsupported file type for native'};
        }
      }

      // Send the request
      print('Sending file upload request');
      var streamedResponse = await request.send();
      print('Response status: ${streamedResponse.statusCode}');
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData['data']};
      } else {
        var responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['errors']?[0]?['message'] ?? 'Failed to upload file',
        };
      }
    } catch (e) {
      print('File upload error: ${e.toString()}');
      return {'success': false, 'message': 'File upload error: ${e.toString()}'};
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
  // Create a new course
  Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    required String subjectId, // ID of the related subject item
    required String tutorId,   // ID of the user (e.g., from directus_users) who is the tutor
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        // This case should ideally be caught by refreshTokenIfNeeded if it performs logout on no token
        return {'success': false, 'message': 'Not authenticated. No access token found.'};
      }

      // Ensure token is fresh before making the call
      if (!await refreshTokenIfNeeded()) {
        return {'success': false, 'message': 'Session expired or invalid. Please log in again.'};
      }

      // Re-fetch the access token as it might have been refreshed
      accessToken = prefs.getString('accessToken');
      if (accessToken == null) {
        // This implies tokens were cleared during the refresh process (e.g., by logout() call within refreshTokenIfNeeded)
        return {'success': false, 'message': 'Authentication token unavailable after refresh attempt. Please log in again.'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/items/Courses'), // Assuming 'courses' is the collection key
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'subject_id': subjectId, // This should be the ID (PK) of an item in the "subjects" collection
          'tutor_id': tutorId,     // This should be the ID (PK) of an item in the "users" or "tutors" collection
        }),
      );

      // Handle cases where response body might be empty
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': null, 'message': 'Course created successfully (server returned no content). Status: ${response.statusCode}'};
        } else {
          return {'success': false, 'message': 'Failed to create course. Server returned status ${response.statusCode} with an empty response.'};
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        String errorMessage = 'Failed to create course.';
        if (data['errors'] != null && data['errors'] is List && data['errors'].isNotEmpty) {
          if (data['errors'][0]['message'] != null) {
            errorMessage = data['errors'][0]['message'];
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Error in createCourse: $e');
      if (e is http.ClientException || e.toString().toLowerCase().contains('socketexception')) {
        return {'success': false, 'message': 'Network error: Could not connect to the server.'};
      } else if (e is FormatException) {
        return {'success': false, 'message': 'Error parsing server response.'};
      }
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }
  // Create a new Tutor Availability slot
  Future<Map<String, dynamic>> createTutorAvailability({
    required String tutorId,
    required List<String> daysOfWeek, // MODIFIED: Now accepts a List of day names
    required String startTime,
    required String endTime,
    required bool recurring,
    String? specificDate,
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      if (!await refreshTokenIfNeeded()) {
        return {'success': false, 'message': 'Session expired or invalid. Please log in again.'};
      }

      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');
      if (accessToken == null) {
        return {'success': false, 'message': 'Authentication token unavailable after refresh attempt. Please log in again.'};
      }

      Map<String, dynamic> payload = {
        'tutor_id': tutorId,
        'day_of_week': daysOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'recurring': recurring,
      };

      if (!recurring && specificDate != null && specificDate.isNotEmpty) {
        payload['specific_date'] = specificDate;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/items/TutorAvailability'), // Ensure 'TutorAvailability' is your collection key
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': null, 'message': 'Tutor availability created (no content). Status: ${response.statusCode}'};
        } else {
          return {'success': false, 'message': 'Failed to create tutor availability. Status ${response.statusCode} (empty response).'};
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        String errorMessage = data['errors']?[0]?['message'] ?? data['message'] ?? 'Failed to create tutor availability.';
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Error in createTutorAvailability: $e');
      if (e is http.ClientException || e.toString().toLowerCase().contains('socketexception')) {
        return {'success': false, 'message': 'Network error: Could not connect.'};
      } else if (e is FormatException) {
        return {'success': false, 'message': 'Error parsing server response.'};
      }
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }
}
