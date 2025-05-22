import 'package:flutter/material.dart';
import 'package:turo/services/directus_service.dart';
import 'dart:math';

class CourseProvider extends ChangeNotifier {
  final DirectusService _directusService = DirectusService();
  
  bool _isLoading = false;
  String? _error;
  
  List<Map<String, dynamic>> _instructors = [];
  List<Map<String, dynamic>> _courses = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get instructors => _instructors;
  List<Map<String, dynamic>> get courses => _courses;
  
  // Initialize data
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('Initializing CourseProvider...');
      
      // First, fetch instructors
      await fetchInstructors();
      
      // Only fetch courses after instructors are loaded
      if (_instructors.isNotEmpty) {
        print('Instructors loaded successfully, now fetching courses...');
        await fetchCourses();
      } else {
        print('No instructors were loaded, aborting course fetching');
        _error = 'Failed to load instructors before courses';
      }
    } catch (e) {
      _error = 'Initialization error: ${e.toString()}';
      print('CourseProvider initialization error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch instructors from Directus
  Future<void> fetchInstructors() async {
    try {
      print('Fetching instructors from Directus...');
      final response = await _directusService.getTutors();
      
      if (response['success']) {
        if (response['data'] == null) {
          print('Received null data from getTutors()');
          _error = 'Received null data from server';
          return;
        }
        
        if (!(response['data'] is List)) {
          print('Expected a List of tutors but got: ${response['data'].runtimeType}');
          _error = 'Received invalid data format';
          return;
        }
        
        print('Received ${response['data'].length} tutors from Directus');
        
        // Convert Directus tutor data to instructor format
        _instructors = _mapTutorsToInstructors(response['data']);
        print('Mapped tutors to ${_instructors.length} instructors');
      } else {
        _error = response['message'];
        print('Error from getTutors(): ${response['message']}');
      }
    } catch (e) {
      _error = 'Failed to load instructors: ${e.toString()}';
      print('Exception in fetchInstructors: ${e.toString()}');
    }
  }
  
  // Fetch courses from Directus
  Future<void> fetchCourses() async {
    try {
      final response = await _directusService.getCourses();
      
      if (response['success']) {
        // Convert Directus course data to course format
        _courses = _mapDirectusCoursesToCourses(response['data']);
        print('Loaded ${_courses.length} courses');
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = 'Failed to load courses: ${e.toString()}';
    }
  }
  
  // Map Directus tutors data to instructors format for the UI
  List<Map<String, dynamic>> _mapTutorsToInstructors(List<dynamic> tutors) {
    if (tutors == null || tutors.isEmpty) {
      print('No tutors to map');
      return [];
    }
    
    try {
      return tutors.map<Map<String, dynamic>>((tutor) {
        // Debug the tutor data structure
        print('Processing tutor: ${tutor['first_name']} ${tutor['last_name']}');
        
        // Get tutor profile data - this is likely where the error is occurring
        Map<String, dynamic> tutorProfile = {};
        if (tutor['tutor_profile'] != null) {
          // If tutor_profile is a list (which could happen with O2M relationships), take the first item
          if (tutor['tutor_profile'] is List && (tutor['tutor_profile'] as List).isNotEmpty) {
            tutorProfile = (tutor['tutor_profile'] as List).first;
            print('Tutor profile from list: ${tutorProfile.keys}');
          } 
          // If it's already a map, use it directly
          else if (tutor['tutor_profile'] is Map) {
            tutorProfile = tutor['tutor_profile'] as Map<String, dynamic>;
            print('Tutor profile is a map: ${tutorProfile.keys}');
          }
        }
        
        // Safely access bio field
        String bio = '';
        if (tutorProfile.containsKey('bio')) {
          var bioValue = tutorProfile['bio'];
          // Ensure bio is treated as a string
          bio = bioValue != null ? bioValue.toString() : '';
        }
        
        // Map tutor subjects to expertise
        List<String> expertise = [];
        if (tutor['subjects'] is List) {
          expertise = (tutor['subjects'] as List)
              .map((subject) {
                if (subject is Map && subject.containsKey('subject_name')) {
                  return subject['subject_name']?.toString() ?? '';
                }
                return '';
              })
              .where((name) => name.isNotEmpty)
              .toList();
        }
        
        // Map to instructor format - ensure all fields are type-safe
        return {
          'id': tutor['id'] != null ? tutor['id'].toString() : '',
          'name': '${tutor['first_name'] ?? ''} ${tutor['last_name'] ?? ''}',
          'first_name': tutor['first_name'] ?? 'Instructor',
          'image': tutor['avatar'] != null ? tutor['avatar'].toString() : '',
          'specialty': expertise.isNotEmpty ? expertise.first : 'Instructor',
          'bio': bio.isNotEmpty ? bio : (tutor['description']?.toString() ?? 'An experienced instructor passionate about teaching.'),
          'rating': 4.5, // Default rating if not available
          'students': 100, // Default students count if not available
          'courses': 3, // Default courses count if not available
          'expertise': expertise,
          'hour_rate': _safelyGetNumber(tutorProfile['hour_rate'], 0),
          'verified': tutorProfile['verified'] == true,
          'education_background': tutorProfile['education_background']?.toString() ?? '',
          'teachingCourses': [], // Will be populated when courses are loaded
        };
      }).toList();
    } catch (e) {
      print('Error mapping tutors: ${e.toString()}');
      return [];
    }
  }
  
  // Helper method to safely get a number value
  dynamic _safelyGetNumber(dynamic value, dynamic defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    try {
      return double.parse(value.toString());
    } catch (e) {
      return defaultValue;
    }
  }
  
  // Map Directus courses data to courses format for the UI
  List<Map<String, dynamic>> _mapDirectusCoursesToCourses(List<dynamic> directusCourses) {
    if (directusCourses == null || directusCourses.isEmpty) {
      print('No courses to map');
      return [];
    }
    
    if (_instructors.isEmpty) {
      print('Warning: No instructors available when mapping courses');
    } else {
      print('Number of instructors available: ${_instructors.length}');
      // Debug: print first few instructor IDs
      for (int i = 0; i < min(3, _instructors.length); i++) {
        print('Instructor ${i}: ID=${_instructors[i]['id']}, Name=${_instructors[i]['name']}');
      }
    }
    
    try {
      // First pass: map courses
      final List<Map<String, dynamic>> mappedCourses = directusCourses.map<Map<String, dynamic>>((course) {
        // Get tutor data from the tutor_id relationship
        String tutorUserId = '';
        Map<String, dynamic>? tutorData;
        
        // FIXED: First check for tutor_id relationship which is the primary relationship for instructors
        if (course['tutor_id'] != null && course['tutor_id'] is Map) {
          // If tutor_id is expanded and contains user_id reference
          if (course['tutor_id']['user_id'] != null && course['tutor_id']['user_id'] is Map) {
            tutorData = course['tutor_id']['user_id'];
            tutorUserId = tutorData!['id']?.toString() ?? '';
            print('Course "${course['title']}" has tutor user from tutor_id.user_id: $tutorUserId (${tutorData['first_name']} ${tutorData['last_name']})');
          } 
          // If we just have the tutor record but not expanded user data
          else {
            print('Course "${course['title']}" has tutor_id but user_id is not expanded: ${course['tutor_id']}');
          }
        }
        // Fallback to previous directus_users check
        else if (course['directus_users'] != null && course['directus_users'] is List && course['directus_users'].isNotEmpty) {
          tutorData = course['directus_users'][0];
          tutorUserId = tutorData!['id']?.toString() ?? '';
          print('Course "${course['title']}" has instructor from directus_users: $tutorUserId (${tutorData['first_name']} ${tutorData['last_name']})');
        }
        // Last resort, check for tutor_id as a simple ID value
        else if (course['tutor_id'] != null) {
          tutorUserId = course['tutor_id'].toString();
          print('Course "${course['title']}" has simple tutor_id: $tutorUserId (not expanded)');
        } else {
          print('Course "${course['title']}" has no instructor association');
        }
        
        // Find the instructor in our list by matching user ID
        int instructorIndex = -1;
        if (tutorUserId.isNotEmpty) {
          instructorIndex = _instructors.indexWhere((instructor) => instructor['id'].toString() == tutorUserId);
          
          if (instructorIndex != -1) {
            print('Found instructor for course "${course['title']}": ${_instructors[instructorIndex]['name']}');
          } else {
            print('No instructor found in cached list for course "${course['title']}" with ID $tutorUserId');
          }
        }
        
        // Get instructor details
        String instructorName = "Unknown Instructor";
        String instructorFirstName = "Instructor";
        
        // If we found the instructor in our list, use that data
        if (instructorIndex >= 0 && instructorIndex < _instructors.length) {
          instructorName = _instructors[instructorIndex]['name'];
          instructorFirstName = _instructors[instructorIndex]['first_name'];
        } 
        // If we have expanded tutor user data but it wasn't in our instructor list
        else if (tutorData != null) {
          instructorName = '${tutorData['first_name'] ?? ''} ${tutorData['last_name'] ?? ''}';
          instructorFirstName = tutorData['first_name'] ?? 'Instructor';
        }
        
        // Get course image
        String courseImage = 'assets/courses/python.png'; // Default image
        if (course['course_image'] != null && course['course_image'] is Map) {
          var imageId = course['course_image']['id'];
          courseImage = imageId != null ? imageId.toString() : courseImage;
        }
        
        // Get subject tags
        List<String> tags = [];
        if (course['subject_id'] != null && course['subject_id'] is Map) {
          String subjectName = course['subject_id']['subject_name'] ?? '';
          if (subjectName.isNotEmpty) {
            tags.add(subjectName);
          }
        }
        
        // Map to course format
        return {
          'id': course['id'] != null ? course['id'].toString() : '',
          'title': course['title'] ?? 'Untitled Course',
          'description': course['description'] ?? 'No description available.',
          'instructorId': instructorIndex,
          'instructorName': instructorName,
          'instructorFirstName': instructorFirstName,
          'tutorUserId': tutorUserId, // Store the actual tutor user ID for reference
          'duration': '1hr/day', // Default duration
          'image': courseImage,
          'categories': ['Hot', ...tags], // Add "Hot" category by default
          'lessons': 12, // Default lessons count
          'level': 'Beginner', // Default level
          'rating': 4.5, // Default rating
          'tags': tags.isEmpty ? ['General'] : tags,
        };
      }).toList();
      
      // Second pass: update instructor's teachingCourses
      for (var course in mappedCourses) {
        final instructorIndex = course['instructorId'];
        if (instructorIndex >= 0 && instructorIndex < _instructors.length) {
          final instructor = _instructors[instructorIndex];
          
          // Add course to instructor's teachingCourses
          List<Map<String, dynamic>> teachingCourses = List.from(instructor['teachingCourses'] ?? []);
          teachingCourses.add({
            'title': course['title'],
            'students': 50, // Default student count
            'rating': course['rating'],
          });
          
          // Update instructor
          instructor['teachingCourses'] = teachingCourses;
          
          // Update instructor courses count
          instructor['courses'] = teachingCourses.length;
        }
      }
      
      return mappedCourses;
    } catch (e) {
      print('Error mapping courses: ${e.toString()}');
      return [];
    }
  }
  
  // Get asset URL for images
  String getAssetUrl(String? assetId) {
    if (assetId == null || assetId.isEmpty) return '';
    return _directusService.getAssetUrl(assetId);
  }
} 