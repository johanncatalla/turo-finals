import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/Widgets/navbar.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({Key? key}) : super(key: key);

  @override
  _MyCoursesScreenState createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  int _selectedMenuIndex = 2; // Selected menu index for My Courses
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _enrolledCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;

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

  // Load enrolled courses - this would normally come from a backend
  void _loadEnrolledCourses() {
    // Simulate loading from backend
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        // Dummy data for enrolled courses
        _enrolledCourses = [
          {
            'title': 'Introduction to Python',
            'description': 'An engaging beginner-friendly course that introduces the fundamentals of Python programming language.',
            'instructor': 'Mr. J. Seb Catalla',
            'progress': 0.75, // 75% complete
            'duration': '1hr/day',
            'image': 'assets/courses/python.png',
            'categories': ['Programming'],
          },
          {
            'title': 'Conversational English',
            'description': 'A practical course designed to build confidence and fluency in conversational English.',
            'instructor': 'Mr. J.L Echevaria',
            'progress': 0.3, // 30% complete
            'duration': '1hr/day',
            'image': 'assets/courses/python.png',
            'categories': ['Language'],
          },
          {
            'title': 'Foundational Algebra',
            'description': 'A foundational course that explores the core principles of algebra, including solving equations and inequalities.',
            'instructor': 'Ms. PNC. Oriola',
            'progress': 0.5, // 50% complete
            'duration': '1hr/day',
            'image': 'assets/courses/python.png',
            'categories': ['Math'],
          },
        ];
        _filteredCourses = List.from(_enrolledCourses);
        _isLoading = false;
      });
    });
  }

  void _filterCourses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = List.from(_enrolledCourses);
      } else {
        _filteredCourses = _enrolledCourses
            .where((course) =>
                course['title'].toLowerCase().contains(query) ||
                course['instructor'].toLowerCase().contains(query) ||
                course['description'].toLowerCase().contains(query))
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
        Navigator.pushReplacementNamed(context, '/');
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
            icon: const Icon(Icons.filter_list, color: Colors.orange),
            onPressed: () {
              // Filter functionality could be added here
            },
          ),
        ],
      ),
      body: Stack(
        children: [
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
                    _buildFilterChip('Programming'),
                    _buildFilterChip('Language'),
                    _buildFilterChip('Math'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Enrolled Courses List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : _filteredCourses.isEmpty
                        ? const Center(
                            child: Text(
                              'No courses found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filteredCourses.length,
                            itemBuilder: (context, index) {
                              return _buildEnrolledCourseItem(_filteredCourses[index]);
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

  Widget _buildEnrolledCourseItem(Map<String, dynamic> course) {
    return Card(
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
                  child: Image.asset(
                    course['image'],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                // Course details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.cyan[700]),
                          const SizedBox(width: 4),
                          Text(
                            course['duration'],
                            style: TextStyle(
                              color: Colors.cyan[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person, size: 16, color: Colors.cyan[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              course['instructor'],
                              style: TextStyle(
                                color: Colors.cyan[700],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(course['progress'] * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: course['progress'],
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the course content
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text(
                    'Continue Learning',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 