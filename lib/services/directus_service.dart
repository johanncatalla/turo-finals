import 'dart:convert';
import 'dart:io';
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
        
        // Also fetch enrolled courses for students
        final enrolledCoursesResponse = await http.get(
          Uri.parse('$baseUrl/items/junction_directus_users_Courses?filter={"directus_users_id":"$userId"}&fields=*,Courses_id.*,Courses_id.subject_id.*,Courses_id.course_image.*,Courses_id.tutor_id.user_id.*'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $adminToken',
          },
        );
        
        if (enrolledCoursesResponse.statusCode == 200) {
          final enrolledCoursesData = jsonDecode(enrolledCoursesResponse.body);
          final junctionItems = enrolledCoursesData['data'] as List;
          
          if (junctionItems.isNotEmpty) {
            // Extract just the course data for easier use
            final coursesList = junctionItems.map((item) => item).toList();
            profileData['enrolled_courses'] = coursesList;
            // print('Loaded ${coursesList.length} enrolled courses for profile');
          } else {
            profileData['enrolled_courses'] = [];
            print('No enrolled courses found for user');
          }
        }
      }

      return {'success': true, 'data': profileData};
    } catch (e) {
      print('Error fetching full user profile: ${e.toString()}');
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

  // Fetch all tutors (instructors)
  Future<Map<String, dynamic>> getTutors() async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      print('Fetching tutors from Directus...');

      final response = await http.get(
        Uri.parse('$baseUrl/users?filter={"user_type":"Tutor"}&fields=*,tutor_profile.*,subjects.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['data'] is List && data['data'].isNotEmpty) {
          var firstTutor = data['data'][0];
          print('First tutor sample: ${firstTutor['first_name']} ${firstTutor['last_name']}');
          print('Tutor profile type: ${firstTutor['tutor_profile'].runtimeType}');
          print('Subjects type: ${firstTutor['subjects'].runtimeType}');
        }

        return {'success': true, 'data': data['data']};
      } else {
        print('Error fetching tutors: ${data['errors'] != null ? data['errors'][0]['message'] : 'Unknown error'}');
        return {
          'success': false,
          'message': data['errors']?[0]?['message'] ?? 'Failed to fetch tutors'
        };
      }
    } catch (e) {
      print('Network error fetching tutors: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Fetch all courses
  Future<Map<String, dynamic>> getCourses() async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      print('Fetching courses from Directus...');
      final response = await http.get(
        Uri.parse('$baseUrl/items/Courses?fields=*,subject_id.*,course_image.*,tutor_id.user_id.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['data'] is List && data['data'].isNotEmpty) {
          var firstCourse = data['data'][0];
          if (firstCourse['tutor_id'] != null) {
            print('Course has tutor_id: ${firstCourse['tutor_id'].runtimeType}');
            if (firstCourse['tutor_id'] is Map) {
              print('Tutor details: ${firstCourse['tutor_id']}');

              // Check if user_id is expanded
              if (firstCourse['tutor_id']['user_id'] != null && firstCourse['tutor_id']['user_id'] is Map) {
                var userData = firstCourse['tutor_id']['user_id'];
                print('Tutor user data: ${userData['first_name']} ${userData['last_name']}');
              }
            }
          } else {
            print('Course has no tutor_id');
          }
          if (firstCourse['directus_users'] != null) {
            print('Course also has directus_users relationship: ${firstCourse['directus_users'].runtimeType}');
          }
        }

        return {'success': true, 'data': data['data']};
      } else {
        print('Error fetching courses: ${data['errors'] != null ? data['errors'][0]['message'] : 'Unknown error'}');
        return {
          'success': false,
          'message': data['errors']?[0]?['message'] ?? 'Failed to fetch courses'
        };
      }
    } catch (e) {
      print('Network error fetching courses: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get course details by ID
  Future<Map<String, dynamic>> getCourseById(String courseId) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/items/Courses/$courseId?fields=*,tutor_id.*,subject_id.*,course_image.*,modules.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['errors']?[0]?['message'] ?? 'Failed to fetch course details'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Fetch all subjects
  Future<Map<String, dynamic>> getSubjects() async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      print('Fetching subjects from Directus...');

      final response = await http.get(
        Uri.parse('$baseUrl/items/Subjects?fields=*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        print('Error fetching subjects: ${data['errors'] != null ? data['errors'][0]['message'] : 'Unknown error'}');
        return {
          'success': false,
          'message': data['errors']?[0]?['message'] ?? 'Failed to fetch subjects'
        };
      }
    } catch (e) {
      print('Network error fetching subjects: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Enroll a student in a course (add course to user's enrolled_courses)
  Future<Map<String, dynamic>> enrollInCourse(String userId, String courseId) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      print('Enrolling user $userId in course $courseId...');

      // First, check if the user is already enrolled in this course
      final checkResponse = await http.get(
        Uri.parse('$baseUrl/users/$userId?fields=enrolled_courses.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (checkResponse.statusCode != 200) {
        final errorData = jsonDecode(checkResponse.body);
        return {
          'success': false,
          'message': errorData['errors']?[0]?['message'] ?? 'Failed to check enrollment status'
        };
      }

      final userData = jsonDecode(checkResponse.body)['data'];
      final enrolledCourses = userData['enrolled_courses'] ?? [];

      // Check if already enrolled
      bool alreadyEnrolled = false;
      if (enrolledCourses is List) {
        alreadyEnrolled = enrolledCourses.any((course) =>
          course is Map && course['id'] != null && course['id'].toString() == courseId
        );
      }

      if (alreadyEnrolled) {
        return {'success': false, 'message': 'Already enrolled in this course', 'alreadyEnrolled': true};
      }

      // Create a booking for this enrollment
      final bookingResponse = await http.post(
        Uri.parse('$baseUrl/items/Bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'client_id': userId,
          'course_id': courseId,
          'status': 'Active',
          'payment_status': 'Paid',
        }),
      );

      if (bookingResponse.statusCode != 200) {
        final errorData = jsonDecode(bookingResponse.body);
        return {
          'success': false,
          'message': errorData['errors']?[0]?['message'] ?? 'Failed to create booking'
        };
      }

      // Create an entry in the junction table to connect the user with the course
      final enrollResponse = await http.post(
        Uri.parse('$baseUrl/items/junction_directus_users_Courses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'directus_users_id': userId,
          'Courses_id': courseId
        }),
      );

      if (enrollResponse.statusCode == 200) {
        print('Successfully enrolled user in course');
        return {'success': true, 'message': 'Successfully enrolled in course'};
      } else {
        final errorData = jsonDecode(enrollResponse.body);
        return {
          'success': false,
          'message': errorData['errors']?[0]?['message'] ?? 'Failed to enroll in course'
        };
      }
    } catch (e) {
      print('Error enrolling in course: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Check if a user is enrolled in a specific course
  Future<Map<String, dynamic>> checkEnrollmentStatus(String userId, String courseId) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      // Query the junction table directly
      final response = await http.get(
        Uri.parse('$baseUrl/items/junction_directus_users_Courses?filter={"directus_users_id":"$userId","Courses_id":"$courseId"}&limit=1'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] as List;

        return {
          'success': true,
          'isEnrolled': items.isNotEmpty
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['errors']?[0]?['message'] ?? 'Failed to check enrollment status'
        };
      }
    } catch (e) {
      print('Error checking enrollment: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get all courses a user is enrolled in
  Future<Map<String, dynamic>> getEnrolledCourses(String userId) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      // Get the enrolled courses through the junction table
      final response = await http.get(
        Uri.parse('$baseUrl/items/junction_directus_users_Courses?filter={"directus_users_id":"$userId"}&fields=*,Courses_id.*,Courses_id.subject_id.*,Courses_id.course_image.*,Courses_id.tutor_id.user_id.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final junctionItems = data['data'] as List;

        // Map junction items to the actual courses
        final courses = junctionItems.map((item) => item['Courses_id']).toList();

        return {
          'success': true,
          'data': courses
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['errors']?[0]?['message'] ?? 'Failed to fetch enrolled courses'
        };
      }
    } catch (e) {
      print('Error fetching enrolled courses: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
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
      // print(userData);
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
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      // First, get the tutor_profile relation for this user
      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/$userId?fields=id,first_name,last_name,email,user_type,tutor_profile.*,tutor_profile.subjects.*'),
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
    required String subjectId,
    required String tutorId,
    required String? courseImageId,
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/items/Courses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'subject_id': subjectId,
          'tutor_id': tutorId,
          'course_image': courseImageId,
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
    required List<String> daysOfWeek,
    required String startTime,
    required String endTime,
    required bool recurring,
    String? specificDate,
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
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
        Uri.parse('$baseUrl/items/TutorAvailability'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
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

  Future<Map<String, dynamic>> fetchCoursesByTutorId(String tutorId) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        print('Error: Admin token not configured in .env');
        return {'success': false, 'message': 'Admin token not configured'};
      }
      if (baseUrl == null) {
        print('Error: Base URL not configured in .env');
        return {'success': false, 'message': 'Base URL not configured'};
      }


      final fields = '*,subject_id.*,course_image.*,tutor_id.user_id.*,bookings.*';
      final url = Uri.parse(
        '$baseUrl/items/Courses?filter[tutor_id][_eq]=$tutorId&fields=$fields',
      );



      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['data'] is List && data['data'].isNotEmpty) {
          var firstCourse = data['data'][0];
          if (firstCourse['tutor_id'] != null) {

            if (firstCourse['tutor_id']['user_id'] != null) {
              // print('    - Tutor User data: ${firstCourse['tutor_id']['user_id']}');
            }
          }
          if (firstCourse['subject_id'] != null) {
            // print('  - Subject ID data: ${firstCourse['subject_id']}');
          }
          if (firstCourse['course_image'] != null) {
            // print('  - Course Image data: ${firstCourse['course_image']}');
          }
          if (firstCourse['bookings'] != null) { // If bookings.* was used and it's a relation
            // print('  - Bookings data: ${firstCourse['bookings']}');
          }
        } else if (data['data'] is List && data['data'].isEmpty) {
          // print('No courses found for Tutor ID: $tutorId');
        }


        return {'success': true, 'data': data['data']};
      } else {
        String errorMessage = 'Failed to fetch courses for Tutor ID: $tutorId.';
        if (data != null && data['errors'] is List && data['errors'].isNotEmpty) {
          errorMessage += ' Error: ${data['errors'][0]['message']}';
        } else if (response.body.isNotEmpty) {
          errorMessage += ' Response: ${response.body}';
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Network error fetching courses by Tutor ID $tutorId: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  Future<Map<String, dynamic>> updateTutorProfile(String tutorProfileId, Map<String, dynamic> profileData) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/items/Tutors/$tutorProfileId'),
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
          'message': data['errors']?[0]?['message'] ?? 'Failed to update tutor profile'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  Future<Map<String, dynamic>> updateCourse({
    required String courseId, // ID of the course to update
    required String title,
    required String description,
    required String subjectId,
    required String? courseImageId, // Pass null if image is not changed, or new ID if changed
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      Map<String, dynamic> payload = {
        'title': title,
        'description': description,
        'subject_id': subjectId,
      };
      if (courseImageId != null) {
        payload['course_image'] = courseImageId;
      } else {
        // to allow REMOVING an image by passing null explicitly
        // payload['course_image'] = null;
        // Otherwise, if courseImageId is null and you don't send the key,
        // Directus will leave the existing image untouched.
      }


      final response = await http.patch(
        Uri.parse('$baseUrl/items/Courses/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(payload),
      );

      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': null, 'message': 'Course updated successfully (no content). Status: ${response.statusCode}'};
        } else {
          return {'success': false, 'message': 'Failed to update course. Status ${response.statusCode} (empty response).'};
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) { // HTTP 200 for successful PATCH
        return {'success': true, 'data': data['data']};
      } else {
        String errorMessage = data['errors']?[0]?['message'] ?? data['message'] ?? 'Failed to update course.';
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Error in updateCourse: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getCourseDetailsForEdit(String courseId) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/items/Courses/$courseId?fields=id,title,description,subject_id.id,course_image.id,tutor_id.id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['errors']?[0]?['message'] ?? 'Failed to fetch course for editing'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  Future<Map<String, dynamic>> fetchTutorAvailabilities(String tutorProfileId) async {
    if (baseUrl == null) return {'success': false, 'message': 'API URL not configured.'};
    
    print('🔍 Fetching tutor availability from Directus for tutor profile ID: $tutorProfileId');
    
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) return {'success': false, 'message': 'Admin token not configured.'};

      // Fetch availability from TutorAvailability collection
      final response = await http.get(
        Uri.parse('$baseUrl/items/TutorAvailability?filter[tutor_id][_eq]=$tutorProfileId&fields=id,day_of_week,start_time,end_time,recurring,specific_date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print('📡 Directus API Response Status: ${response.statusCode}');
      print('📡 Directus API Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final availabilityData = data['data'] as List? ?? [];
        print('✅ Successfully fetched ${availabilityData.length} availability records from Directus');

        // Log each record for debugging
        for (int i = 0; i < availabilityData.length; i++) {
          final record = availabilityData[i];
          print('   📋 Record ${i + 1}: ${record}');
        }

        return {'success': true, 'data': availabilityData};
      } else {
        final errorMessage = data['errors']?[0]?['message'] ?? 'Failed to fetch availabilities';
        print('❌ Directus API Error: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('💥 Exception fetching availability: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Delete a specific Tutor Availability slot by its ID
  Future<Map<String, dynamic>> deleteTutorAvailability(String availabilityId) async {
    if (baseUrl == null) return {'success': false, 'message': 'API URL not configured.'};
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) return {'success': false, 'message': 'Admin token not configured.'};

      final response = await http.delete(
        Uri.parse('$baseUrl/items/TutorAvailability/$availabilityId'),
        headers: {'Authorization': 'Bearer $adminToken'},
      );

      if (response.statusCode == 204) {
        return {'success': true, 'message': 'Availability deleted successfully.'};
      } else if (response.statusCode == 200 && response.body.isNotEmpty) {
        return {'success': true, 'message': 'Availability deleted (with response).', 'data': jsonDecode(response.body)};
      }
      else {
        String errorMessage = 'Failed to delete availability.';
        try {
          if (response.body.isNotEmpty) {
            final data = jsonDecode(response.body);
            errorMessage = data['errors']?[0]?['message'] ?? errorMessage;
          }
        } catch (e) {/* ignore json decode error if body is not json */}
        return {'success': false, 'message': '$errorMessage Status: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
  Future<Map<String, dynamic>> fetchSubjects() async {
    // Check if the base URL is configured
    if (baseUrl == null) {
      return {'success': false, 'message': 'Directus API URL is not configured.'};
    }

    try {
      // Retrieve the admin token from environment variables
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      // Check if the admin token is available
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      // Make the HTTP GET request to the 'Subjects' collection endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/items/Subjects?fields=*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken', // Use Bearer token for authorization
        },
      );

      // Decode the JSON response body
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {

        return {'success': true, 'data': responseData['data']};
      } else {
        final errorMessage = responseData['errors']?[0]?['message'] ?? 'Failed to fetch subjects';
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get all students enrolled in courses taught by a specific tutor
  Future<Map<String, dynamic>> getTutorStudents(String tutorUserId) async {
    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      // First, find the tutor profile for this user
      final tutorResponse = await http.get(
        Uri.parse('$baseUrl/items/Tutors?filter={"user_id":"$tutorUserId"}&fields=id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (tutorResponse.statusCode != 200) {
        final tutorData = jsonDecode(tutorResponse.body);
        return {
          'success': false,
          'message': tutorData['errors']?[0]?['message'] ?? 'Failed to fetch tutor profile'
        };
      }

      final tutorData = jsonDecode(tutorResponse.body);
      final tutors = tutorData['data'] as List;

      if (tutors.isEmpty) {
        return {
          'success': true,
          'data': [],
          'message': 'No tutor profile found for this user'
        };
      }

      final tutorId = tutors[0]['id'];

      // Now get all courses taught by this tutor using the tutor profile ID
      final coursesResponse = await http.get(
        Uri.parse('$baseUrl/items/Courses?filter={"tutor_id":"$tutorId"}&fields=id,title'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (coursesResponse.statusCode != 200) {
        final coursesData = jsonDecode(coursesResponse.body);
        return {
          'success': false,
          'message': coursesData['errors']?[0]?['message'] ?? 'Failed to fetch tutor courses'
        };
      }

      final coursesData = jsonDecode(coursesResponse.body);
      final courses = coursesData['data'] as List;

      if (courses.isEmpty) {
        return {
          'success': true,
          'data': [],
          'message': 'No courses found for this tutor'
        };
      }

      // Extract course IDs
      final courseIds = courses.map((course) => course['id']).toList();

      // Get all students enrolled in these courses through the junction table
      final studentsResponse = await http.get(
        Uri.parse('$baseUrl/items/junction_directus_users_Courses?filter={"Courses_id":{"_in":${jsonEncode(courseIds)}}}&fields=*,directus_users_id.*,Courses_id.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (studentsResponse.statusCode != 200) {
        final errorData = jsonDecode(studentsResponse.body);
        return {
          'success': false,
          'message': errorData['errors']?[0]?['message'] ?? 'Failed to fetch enrolled students'
        };
      }

      final studentsData = jsonDecode(studentsResponse.body);
      final junctionItems = studentsData['data'] as List;
      Map<String, Map<String, dynamic>> uniqueStudents = {};

      for (var item in junctionItems) {
        final user = item['directus_users_id'];
        final course = item['Courses_id'];
        
        // Only include users who are students
        if (user != null && user['user_type'] == 'Student') {
          final userId = user['id'];
          
          if (!uniqueStudents.containsKey(userId)) {
            uniqueStudents[userId] = {
              'id': user['id'],
              'first_name': user['first_name'],
              'last_name': user['last_name'],
              'email': user['email'],
              'user_type': user['user_type'],
              'avatar': user['avatar'],
              'enrolled_courses': []
            };
          }
          
          // Add course to student's enrolled courses list
          if (course != null) {
            uniqueStudents[userId]!['enrolled_courses'].add({
              'id': course['id'],
              'title': course['title']
            });
          }
        }
      }

      print('getTutorStudents: Successfully found ${uniqueStudents.length} students enrolled in ${courses.length} courses');

      return {
        'success': true,
        'data': uniqueStudents.values.toList()
      };
    } catch (e) {
      print('Error fetching tutor students: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update an existing Tutor Availability slot
  Future<Map<String, dynamic>> updateTutorAvailability({
    required String availabilityId,
    required List<String> daysOfWeek,
    required String startTime,
    required String endTime,
    required bool recurring,
    String? specificDate,
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'}; 
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];

      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      Map<String, dynamic> payload = {
        'day_of_week': daysOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'recurring': recurring,
      };

      if (!recurring && specificDate != null && specificDate.isNotEmpty) {
        payload['specific_date'] = specificDate;
      } else if (recurring) {
        payload['specific_date'] = null; // Clear specific date for recurring
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/items/TutorAvailability/$availabilityId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(payload),
      );

      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': null, 'message': 'Availability updated successfully (no content). Status: ${response.statusCode}'};
        } else {
          return {'success': false, 'message': 'Failed to update availability. Status ${response.statusCode} (empty response).'};
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        String errorMessage = data['errors']?[0]?['message'] ?? data['message'] ?? 'Failed to update availability.';
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Error in updateTutorAvailability: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String clientId,
    required String tutorId,
    required String courseId,
    required List<String> schedule, // Days of week
    required String mode, // "Online" or "In-person"
    required int totalHours,
    required double totalCost,
    List<String>? subjectIds,
    String status = 'Pending',
    String paymentStatus = 'Unpaid',
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      Map<String, dynamic> payload = {
        'client_id': clientId,
        'tutor_id': tutorId,
        'course_id': courseId,
        'schedule': schedule,
        'status': status,
        'mode': mode,
        'payment_status': paymentStatus,
        'total_hours': totalHours,
        'total_cost': totalCost,
      };

      // Add subjects if provided
      if (subjectIds != null && subjectIds.isNotEmpty) {
        payload['subjects'] = subjectIds;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/items/Bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(payload),
      );

      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': null, 'message': 'Booking created successfully (no content). Status: ${response.statusCode}'};
        } else {
          return {'success': false, 'message': 'Failed to create booking. Status ${response.statusCode} (empty response).'};
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        String errorMessage = data['errors']?[0]?['message'] ?? data['message'] ?? 'Failed to create booking.';
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Error in createBooking: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Create chosen dates for a booking
  Future<Map<String, dynamic>> createChosenDates({
    required String bookingId,
    required List<Map<String, dynamic>> dateTimeSlots, // [{date, start_time, end_time}]
  }) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      List<Map<String, dynamic>> createdDates = [];
      List<String> errors = [];

      for (var slot in dateTimeSlots) {
        Map<String, dynamic> payload = {
          'booking_id': bookingId,
          'date': slot['date'],
          'start_time': slot['start_time'],
          'end_time': slot['end_time'],
          'status': 'Pending',
        };

        final response = await http.post(
          Uri.parse('$baseUrl/items/ChosenDates'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $adminToken',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.body.isNotEmpty) {
            final data = jsonDecode(response.body);
            createdDates.add(data['data']);
          }
        } else {
          String errorMessage = 'Failed to create date slot';
          try {
            if (response.body.isNotEmpty) {
              final data = jsonDecode(response.body);
              errorMessage = data['errors']?[0]?['message'] ?? errorMessage;
            }
          } catch (e) {/* ignore json decode error */}
          errors.add('$errorMessage for ${slot['date']} ${slot['start_time']}-${slot['end_time']}');
        }
      }

      if (errors.isEmpty) {
        return {'success': true, 'data': createdDates};
      } else if (createdDates.isNotEmpty) {
        return {
          'success': true,
          'data': createdDates,
          'message': 'Some dates created successfully, but there were errors: ${errors.join(', ')}'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create any date slots: ${errors.join(', ')}'
        };
      }
    } catch (e) {
      print('Error in createChosenDates: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Get bookings for a specific user (either as client or tutor)
  Future<Map<String, dynamic>> getUserBookings(String userId, {String? role}) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      String filterField;
      if (role == 'tutor') {
        filterField = 'tutor_id';
      } else if (role == 'client' || role == 'student') {
        filterField = 'client_id';
      } else {
        // Get both client and tutor bookings
        final clientBookings = await getUserBookings(userId, role: 'client');
        final tutorBookings = await getUserBookings(userId, role: 'tutor');
        
        List<dynamic> allBookings = [];
        if (clientBookings['success']) {
          allBookings.addAll(clientBookings['data'] ?? []);
        }
        if (tutorBookings['success']) {
          allBookings.addAll(tutorBookings['data'] ?? []);
        }
        
        return {'success': true, 'data': allBookings};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/items/Bookings?filter={"$filterField":"$userId"}&fields=*,client_id.*,tutor_id.*,course_id.*,dates.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = data['errors']?[0]?['message'] ?? 'Failed to fetch bookings.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error in getUserBookings: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Get specific booking details with all related data
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/items/Bookings/$bookingId?fields=*,client_id.*,tutor_id.*,course_id.*,subjects.*,dates.*'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = data['errors']?[0]?['message'] ?? 'Failed to fetch booking details.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error in getBookingDetails: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Update booking status
  Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      Map<String, dynamic> payload = {'status': status};

      final response = await http.patch(
        Uri.parse('$baseUrl/items/Bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = data['errors']?[0]?['message'] ?? 'Failed to update booking status.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error in updateBookingStatus: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Update payment status
  Future<Map<String, dynamic>> updatePaymentStatus(String bookingId, String paymentStatus) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      Map<String, dynamic> payload = {'payment_status': paymentStatus};

      final response = await http.patch(
        Uri.parse('$baseUrl/items/Bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = data['errors']?[0]?['message'] ?? 'Failed to update payment status.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error in updatePaymentStatus: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Update chosen date status
  Future<Map<String, dynamic>> updateChosenDateStatus(String chosenDateId, String status) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      Map<String, dynamic> payload = {'status': status};

      final response = await http.patch(
        Uri.parse('$baseUrl/items/ChosenDates/$chosenDateId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = data['errors']?[0]?['message'] ?? 'Failed to update chosen date status.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error in updateChosenDateStatus: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Delete a booking (and its associated chosen dates)
  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    if (baseUrl == null) {
      return {'success': false, 'message': 'API base URL is not configured.'};
    }

    try {
      final adminToken = dotenv.env['ADMIN_TOKEN'];
      if (adminToken == null) {
        return {'success': false, 'message': 'Admin token not configured'};
      }

      // First, delete all associated chosen dates
      final chosenDatesResponse = await http.get(
        Uri.parse('$baseUrl/items/ChosenDates?filter={"booking_id":"$bookingId"}&fields=id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      if (chosenDatesResponse.statusCode == 200) {
        final chosenDatesData = jsonDecode(chosenDatesResponse.body);
        final chosenDates = chosenDatesData['data'] as List;
        
        for (var date in chosenDates) {
          await http.delete(
            Uri.parse('$baseUrl/items/ChosenDates/${date['id']}'),
            headers: {'Authorization': 'Bearer $adminToken'},
          );
        }
      }

      // Then delete the booking
      final response = await http.delete(
        Uri.parse('$baseUrl/items/Bookings/$bookingId'),
        headers: {'Authorization': 'Bearer $adminToken'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true, 'message': 'Booking deleted successfully.'};
      } else {
        String errorMessage = 'Failed to delete booking.';
        try {
          if (response.body.isNotEmpty) {
            final data = jsonDecode(response.body);
            errorMessage = data['errors']?[0]?['message'] ?? errorMessage;
          }
        } catch (e) {/* ignore json decode error */}
        return {'success': false, 'message': '$errorMessage Status: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error in deleteBooking: $e');
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }
}