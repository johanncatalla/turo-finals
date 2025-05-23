import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/Screens/Students/instructor_detail_screen.dart';
import 'package:turo/providers/course_provider.dart';
import 'package:turo/providers/auth_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final Map<String, dynamic> instructor;

  const CourseDetailScreen({
    super.key, 
    required this.course, 
    required this.instructor
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isEnrolled = false;
  bool _isCheckingEnrollment = false;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _checkEnrollmentStatus();
  }
  
  // Check if the current user is enrolled in this course
  Future<void> _checkEnrollmentStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    // Only check if user is authenticated
    if (authProvider.status == AuthStatus.authenticated && authProvider.user != null) {
      setState(() {
        _isCheckingEnrollment = true;
      });
      
      try {
        final isEnrolled = await courseProvider.isEnrolledInCourse(
          authProvider.user!.id,
          widget.course['id'],
        );
        
        setState(() {
          _isEnrolled = isEnrolled;
          _isCheckingEnrollment = false;
        });
      } catch (e) {
        print('Error checking enrollment status: $e');
        setState(() {
          _isCheckingEnrollment = false;
        });
      }
    }
  }
  
  // Handle enrollment
  Future<void> _handleEnrollment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    // Check if user is authenticated
    if (authProvider.status != AuthStatus.authenticated || authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to enroll in a course')),
      );
      return;
    }
    
    setState(() {
      _isEnrolling = true;
    });
    
    try {
      final response = await courseProvider.enrollInCourse(
        authProvider.user!.id,
        widget.course['id'],
      );
      
      setState(() {
        _isEnrolling = false;
      });
      
      if (response['success']) {
        setState(() {
          _isEnrolled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully enrolled in ${widget.course['title']}')),
        );
      } else {
        // Check if user is already enrolled
        if (response.containsKey('alreadyEnrolled') && response['alreadyEnrolled'] == true) {
          setState(() {
            _isEnrolled = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You are already enrolled in ${widget.course['title']}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to enroll: ${response['message']}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isEnrolling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Details'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            Hero(
              tag: 'course-${widget.course['title']}',
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  image: DecorationImage(
                    image: widget.course['image'] != null && !widget.course['image'].toString().startsWith('assets/')
                        ? NetworkImage(courseProvider.getAssetUrl(widget.course['image']))
                        : const AssetImage('assets/courses/python.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Course title
            Text(
              widget.course['title'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Course stats
            Row(
              children: [
                _buildStatItem(Icons.star, '${widget.course['rating']}', Colors.amber),
                _buildStatItem(Icons.book, '${widget.course['lessons']} Lessons', Colors.blue),
                _buildStatItem(Icons.signal_cellular_alt, widget.course['level'], Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            
            // Course info row with clickable instructor
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.cyan[700]),
                const SizedBox(width: 4),
                Text(
                  widget.course['duration'],
                  style: TextStyle(
                    color: Colors.cyan[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 18, color: Colors.cyan[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InstructorDetailScreen(instructor: widget.instructor),
                        ),
                      );
                    },
                    child: Text(
                      widget.instructor['name'],
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Instructor preview section
            const SizedBox(height: 24),
            _buildInstructorPreview(context),
            
            // Course description
            const SizedBox(height: 24),
            const Text(
              'About this course',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.course['description'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // What you'll learn section
            const Text(
              'What you\'ll learn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildLearningPoints(),
            const SizedBox(height: 30),
            
            // Enroll button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isCheckingEnrollment
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : ElevatedButton(
                    onPressed: _isEnrolled || _isEnrolling
                      ? null // Disable button if already enrolled or currently enrolling
                      : _handleEnrollment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEnrolled ? Colors.grey : Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isEnrolling
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Enrolling...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _isEnrolled ? 'Enrolled' : 'Enroll Now',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructorPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Instructor image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                  image: DecorationImage(
                    image: widget.instructor['image'] != null && widget.instructor['image'].toString().isNotEmpty
                        ? NetworkImage(Provider.of<CourseProvider>(context, listen: false).getAssetUrl(widget.instructor['image']))
                        : const AssetImage('assets/joshua.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Instructor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InstructorDetailScreen(instructor: widget.instructor),
                          ),
                        );
                      },
                      child: Text(
                        widget.instructor['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      widget.instructor['specialty'] ?? 'Instructor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.instructor['rating'] ?? 4.5}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' • ${widget.instructor['students'] ?? 250} students',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // View profile button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstructorDetailScreen(instructor: widget.instructor),
                    ),
                  );
                },
                child: const Text(
                  'View Profile',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLearningPoints() {
    // This would ideally come from the course data
    final List<String> learningPoints = [
      'Understand core concepts and principles',
      'Apply knowledge to real-world scenarios',
      'Build practical skills through hands-on exercises',
      'Develop problem-solving abilities',
    ];
    
    return Column(
      children: learningPoints.map((point) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  point,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 