import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/providers/course_provider.dart';
import 'package:turo/Widgets/navbar.dart';
import 'package:turo/Screens/Students/course_detail_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({Key? key}) : super(key: key);

  @override
  _MyCoursesScreenState createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  int _selectedMenuIndex = 2; // Selected menu index for My Courses
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;
  String? _error;

  // Define navigation items - same as in homepage
  final List<NavBarItem> _navItems = [
    NavBarItem(icon: Icons.home, label: "Home"),
    NavBarItem(icon: Icons.search, label: "Search"),
    NavBarItem(icon: Icons.library_books_outlined, label: "My Courses"),
    NavBarItem(icon: Icons.person_outline, label: "Profile"),
  ];

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
    _searchController.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load enrolled courses from the CourseProvider
  void _loadEnrolledCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      
      if (authProvider.status != AuthStatus.authenticated || authProvider.user == null) {
        setState(() {
          _isLoading = false;
          _error = 'You need to be logged in to view your courses';
        });
        return;
      }
      
      // Fetch enrolled courses
      await courseProvider.fetchEnrolledCourses(authProvider.user!.id);
      
      setState(() {
        _filteredCourses = courseProvider.enrolledCourses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load enrolled courses: ${e.toString()}';
      });
    }
  }

  void _filterCourses() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = List.from(courseProvider.enrolledCourses);
      } else {
        _filteredCourses = courseProvider.enrolledCourses
            .where((course) =>
                course['title'].toString().toLowerCase().contains(query) ||
                course['instructorName'].toString().toLowerCase().contains(query) ||
                course['description'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _handleNavigation(int index) {
    if (index == _selectedMenuIndex) return;

    // Navigation logic
    switch (index) {
      case 0:
        // Navigate to Home page
        Navigator.pushReplacementNamed(context, '/studenthome');
        break;
      case 1:
        // Navigate to search page
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        // Already on My Courses page
        break;
      case 3:
        // Navigate to profile
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Courses',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _loadEnrolledCourses,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.orange))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Error loading your courses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadEnrolledCourses,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (courseProvider.enrolledCourses.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No Enrolled Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You haven\'t enrolled in any courses yet.\nGo to the search page to find courses.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Find Courses'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search your courses...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // Course Categories Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('In Progress'),
                      _buildFilterChip('Completed'),
                      // We could dynamically generate subject chips here based on enrolled courses
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Enrolled Courses List
                Expanded(
                  child: _filteredCourses.isEmpty
                      ? const Center(
                          child: Text(
                            'No courses match your search',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filteredCourses.length,
                          itemBuilder: (context, index) {
                            return _buildEnrolledCourseItem(context, _filteredCourses[index]);
                          },
                        ),
                ),
              ],
            ),
          
          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavBar(
              selectedIndex: _selectedMenuIndex,
              onItemSelected: _handleNavigation,
              items: _navItems,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: label == 'All' ? Colors.orange : Colors.grey[200],
        labelStyle: TextStyle(
          color: label == 'All' ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEnrolledCourseItem(BuildContext context, Map<String, dynamic> course) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    // Find the instructor for this course
    int instructorIndex = course['instructorId'] ?? -1;
    Map<String, dynamic> instructor = {};
    
    if (instructorIndex >= 0 && instructorIndex < courseProvider.instructors.length) {
      instructor = courseProvider.instructors[instructorIndex];
    }
    
    return GestureDetector(
      onTap: () {
        // Navigate to course detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              course: course,
              instructor: instructor,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: course['image'] != null && !course['image'].toString().startsWith('assets/')
                        ? Image.network(
                            courseProvider.getAssetUrl(course['image']),
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/courses/python.png',
                                width: 100,
                                height: 80,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/courses/python.png',
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Course details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] ?? 'Untitled Course',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course['instructorName'] ?? 'Unknown Instructor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              course['duration'] ?? '1hr/day',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '0%', // We could track this in the future
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: 0.0, // We could track progress in the future
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Continue learning functionality
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Show more options
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 