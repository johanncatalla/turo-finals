import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/course_provider.dart';
import 'package:turo/Screens/Students/book_tutor_session_screen.dart';
import 'package:turo/services/directus_service.dart';

class InstructorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> instructor;

  const InstructorDetailScreen({super.key, required this.instructor});

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Instructor Profile'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructor header with image and basic info
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.1),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Instructor image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 2),
                      image: DecorationImage(
                        image: instructor['image'] != null && instructor['image'].toString().isNotEmpty
                            ? NetworkImage(courseProvider.getAssetUrl(instructor['image']))
                            : const AssetImage('assets/joshua.png') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Instructor name
                  Text(
                    instructor['name'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Instructor title/specialty
                  Text(
                    instructor['specialty'] ?? 'Instructor',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats row: Rating, Students, Courses
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatColumn(Icons.star, '${instructor['rating'] ?? 4.5}', 'Rating'),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _buildStatColumn(Icons.people, '${instructor['students'] ?? 250}', 'Students'),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _buildStatColumn(Icons.book, '${instructor['courses'] ?? 5}', 'Courses'),
                    ],
                  ),
                ],
              ),
            ),
            
            // About section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    instructor['bio'] ?? 'An experienced instructor passionate about teaching and helping students achieve their learning goals.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Expertise
                  const Text(
                    'Areas of Expertise',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExpertiseChips(),
                  
                  const SizedBox(height: 24),
                  
                  // Courses taught
                  const Text(
                    'Courses',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCoursesList(),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Book button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Get user ID and resolve to real tutor profile ID
                              String tutorUserId = instructor['user_id']?.toString() ?? 
                                                 instructor['id']?.toString() ?? '';
                              
                              if (tutorUserId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Unable to identify this tutor. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Show loading dialog while resolving tutor profile
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const AlertDialog(
                                    content: Row(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(width: 16),
                                        Text('Loading booking page...'),
                                      ],
                                    ),
                                  );
                                },
                              );
                              
                              try {
                                // Use the DirectusService to resolve user ID to tutor profile ID
                                final directusService = DirectusService();
                                final response = await directusService.fetchCoursesByTutorId(tutorUserId);
                                
                                // Close loading dialog
                                if (context.mounted) Navigator.pop(context);
                                
                                print('🔍 Resolved courses for tutorUserId: $tutorUserId');
                                print('📋 Response: ${response.toString()}');
                                
                                // Navigate to booking regardless of courses found
                                // The booking screen will handle the course loading itself
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookTutorSessionScreen(
                                        tutorUserId: tutorUserId,
                                        tutorName: instructor['name']?.toString() ?? 'Unknown Instructor',
                                        tutorProfileId: tutorUserId, // Pass the user ID, let booking screen resolve it
                                        hourlyRate: instructor['hourly_rate'] is num ? instructor['hourly_rate'].toDouble() : 100.0,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Close loading dialog if still open
                                if (context.mounted) Navigator.pop(context);
                                
                                print('❌ Error resolving tutor profile: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error loading booking page: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Contact button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement contact functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Contact request sent to ${instructor['name']}')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Contact',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpertiseChips() {
    // This would ideally come from the instructor data
    final List<String> expertiseAreas = instructor['expertise'] ?? [
      'Python Programming', 
      'Data Science', 
      'Machine Learning', 
      'Web Development'
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: expertiseAreas.map((area) {
        return Chip(
          backgroundColor: Colors.blue.withOpacity(0.1),
          label: Text(
            area,
            style: TextStyle(
              color: Colors.blue[700],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildCoursesList() {
    // Extract teachingCourses with proper type safety
    List<Map<String, dynamic>> courses = [];
    
    // Check if teachingCourses exists and handle different types
    if (instructor.containsKey('teachingCourses')) {
      final teachingCourses = instructor['teachingCourses'];
      
      if (teachingCourses is List) {
        // Convert each item to Map<String, dynamic> with type safety
        courses = teachingCourses.map<Map<String, dynamic>>((course) {
          if (course is Map) {
            // Convert to Map<String, dynamic> with proper type safety
            return {
              'title': course['title']?.toString() ?? 'Untitled Course',
              'students': course['students'] is num ? course['students'] : 0,
              'rating': course['rating'] is num ? course['rating'] : 4.5,
            };
          } else {
            // Default for non-map items
            return {
              'title': 'Untitled Course',
              'students': 0,
              'rating': 4.5,
            };
          }
        }).toList();
      }
    }
    
    // Use fallback if no courses were found
    if (courses.isEmpty) {
      courses = [
        {
          'title': 'Introduction to Python',
          'students': 120,
          'rating': 4.8,
        },
        {
          'title': 'Advanced Data Structures',
          'students': 85,
          'rating': 4.6,
        },
      ];
    }
    
    return Column(
      children: courses.map((course) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course['students']} students enrolled',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${course['rating']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 