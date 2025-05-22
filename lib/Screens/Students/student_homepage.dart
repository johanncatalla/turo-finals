import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/providers/course_provider.dart';
import 'package:turo/role_select.dart';
import 'package:turo/Widgets/navbar.dart';
import 'package:turo/Screens/Students/all_instructors_screen.dart';
import 'package:turo/Screens/Students/all_courses_screen.dart';
import 'package:turo/Screens/Students/course_detail_screen.dart';
import 'package:turo/Screens/Students/instructor_detail_screen.dart';
import 'package:turo/Screens/Students/search.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomepage> {
  // Tab selection state
  int _selectedCourseTab = 0;
  List<String> _courseTabs = ['Hot'];
  
  // Selected menu item
  int _selectedMenuIndex = 0;

  // Define navigation items
  final List<NavBarItem> _navItems = [
    NavBarItem(icon: Icons.home, label: "Home"),
    NavBarItem(icon: Icons.search, label: "Search"),
    NavBarItem(icon: Icons.library_books_outlined, label: "My Courses"),
    NavBarItem(icon: Icons.person_outline, label: "Profile"),
  ];

  // User data - to be populated from auth provider
  String _userName = "Juan Dela Cruz";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeData();
  }

  // Load user data from auth provider
  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        setState(() {
          _userName = authProvider.user!.fullName;
        });
      }
    });
  }
  
  // Initialize course and instructor data
  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      courseProvider.initialize().then((_) {
        // After initialization, update the course tabs with available subjects
        _updateCourseTabs();
      });
    });
  }
  
  // Update course tabs based on available subjects
  void _updateCourseTabs() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final subjects = courseProvider.subjects;
    
    // Create a set of unique subject names from courses
    final Set<String> subjectNames = {};
    
    // Add all subject names from the subjects list
    for (var subject in subjects) {
      final name = subject['name'];
      if (name != null && name.isNotEmpty) {
        subjectNames.add(name);
      }
    }
    
    // Fallback to default categories if no subjects found
    if (subjectNames.isEmpty) {
      setState(() {
        _courseTabs = ['Hot', 'Programming', 'Language', 'Math'];
      });
      return;
    }
    
    // Update the tabs with 'Hot' first, followed by subject names
    setState(() {
      _courseTabs = ['Hot', ...subjectNames];
      
      // Reset the selected tab if it's out of bounds
      if (_selectedCourseTab >= _courseTabs.length) {
        _selectedCourseTab = 0;
      }
    });
  }

  // Add logout method
  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (shouldLogout) {
      await authProvider.logout();
      
      // Navigate to role selection screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  // Add a method to handle navigation
  void _handleNavigation(int index) {
    // Update the selected index state
    setState(() {
      _selectedMenuIndex = index;
    });

    // Navigation logic using named routes
    switch (index) {
      case 0:
      // Already on Home page, don't navigate
        break;
      case 1:
      // Navigate to search page
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
      // Navigate to my courses
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        
        // Pre-fetch enrolled courses for a smoother experience
        if (authProvider.status == AuthStatus.authenticated && authProvider.user != null) {
          courseProvider.fetchEnrolledCourses(authProvider.user!.id);
        }
        
        Navigator.pushReplacementNamed(context, '/courses');
        break;
      case 3:
      // Navigate to profile
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the course provider
    final courseProvider = Provider.of<CourseProvider>(context);
    final bool isLoading = courseProvider.isLoading;
    final String? error = courseProvider.error;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null, // Remove the app bar completely
      body: Stack(
        children: [
          if (isLoading) 
            // Show loading indicator
            Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            )
          else if (error != null) 
            // Show error message
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Error loading data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => courseProvider.initialize(),
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
          else
            // Show content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message and notification button
                  _buildWelcomeHeader(),
                  
                  // Hero Banner with search bar overlay
                  _buildHeroBanner(),
              
                  // Instructors Section
                  _buildSectionHeader('Instructors', () {
                    Navigator.pushReplacementNamed(context, '/search');
                  }),
                  _buildInstructorsRow(courseProvider),
              
                  // Courses Section
                  _buildSectionHeader('Courses', () {
                    // Navigate to search screen with Course filter pre-selected
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Search(initialMode: 1), // 1 = Course mode
                      ),
                    );
                  }),
                  _buildCoursesTabs(),
                  _buildCoursesListing(courseProvider),
                  
                  // Add bottom padding to avoid content being hidden by the bottom navigation bar
                  SizedBox(height: 100),
                ],
              ),
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
              // You can customize colors if needed:
              // selectedColor: Colors.orange,
              // unselectedColor: Colors.white60,
              // backgroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Modified Welcome message to include user's name and add logout button
  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good day,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 20,
                  height: 0,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Logout button
              Container(
                height: 40,
                width: 40,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  iconSize: 20,
                  onPressed: _handleLogout,
                ),
              ),
              // Notification button
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  iconSize: 20,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Stack(
      children: [
        // Banner with correct aspect ratio to match viewport
        Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          height: 220, // Adjusted height to match viewport
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage('assets/homecard.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Overlay search bar on the banner image - positioned precisely
        Positioned(
          bottom: 16,
          left: 30,
          right: 30,
          child: _buildSearchBar(),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 5, left: 0, right: 0),
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for a topic...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.search, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // Section header with "See All" button
  Widget _buildSectionHeader(String title, VoidCallback onSeeAllPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: onSeeAllPressed,
            child: const Text(
              'See All',
              style: TextStyle(
                fontSize: 18,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Instructors row with rounded rectangular avatars
  Widget _buildInstructorsRow(CourseProvider courseProvider) {
    final instructors = courseProvider.instructors;
    
    print('Building instructors row with ${instructors.length} instructors');
    
    if (instructors.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Center(
          child: Text(
            'No instructors available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return Container(
      height: 120,
      padding: const EdgeInsets.only(left: 6, right: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: instructors.length,
        itemBuilder: (context, index) {
          print('Building instructor item ${index}: ${instructors[index]['name']}');
          return _buildInstructorItem(instructors[index], courseProvider);
        },
      ),
    );
  }

  Widget _buildInstructorItem(Map<String, dynamic> instructor, CourseProvider courseProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstructorDetailScreen(instructor: instructor),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: instructor['image'] != null && instructor['image'].toString().isNotEmpty
                        ? NetworkImage(courseProvider.getAssetUrl(instructor['image']))
                        : const AssetImage('assets/joshua.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              instructor['first_name'] ?? 'Instructor',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tabs for course categories
  Widget _buildCoursesTabs() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _courseTabs.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCourseTab == index;
          Color textColor = isSelected ? Colors.black87 : Colors.grey.shade400;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCourseTab = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 16 : 24,
                right: index == _courseTabs.length - 1 ? 16 : 0,
              ),
              padding: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (index == 0) Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                  SizedBox(width: index == 0 ? 4 : 0),
                  Text(
                    _courseTabs[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Course listing
  Widget _buildCoursesListing(CourseProvider courseProvider) {
    // Filter courses based on selected tab
    final String selectedCategory = _courseTabs[_selectedCourseTab];
    final courses = courseProvider.courses;
    
    // If 'Hot' is selected, show all courses
    // Otherwise filter by the selected subject name
    final filteredCourses = selectedCategory == 'Hot' 
        ? courses 
        : courseProvider.getCoursesBySubjectName(selectedCategory);

    // Calculate the minimum height for 3 items
    // Each course item is about 140 pixels high (120px image height + margins)
    final minHeight = 3 * 140.0;

    return Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
      ),
      child: filteredCourses.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No courses available in this category',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true, // Make list take only the space it needs
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling
            itemCount: filteredCourses.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildCourseItem(filteredCourses[index], courseProvider);
            },
          ),
    );
  }

  // Individual course item
  Widget _buildCourseItem(Map<String, dynamic> course, CourseProvider courseProvider) {
    // Get instructor data
    final String tutorUserId = course['tutorUserId'] ?? '';
    final instructors = courseProvider.instructors;
    
    // Try to find instructor by ID
    Map<String, dynamic> instructor = {
      'first_name': course['instructorFirstName'] ?? 'Instructor',
      'name': course['instructorName'] ?? 'Instructor'
    };
    
    if (tutorUserId.isNotEmpty) {
      final int instructorIndex = instructors.indexWhere((inst) => inst['id'].toString() == tutorUserId);
      if (instructorIndex >= 0) {
        instructor = instructors[instructorIndex];
      }
    }
    
    return GestureDetector(
      onTap: () {
        // Pass both course and instructor data to the detail screen
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 150, // Increased height to prevent overflow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image with Hero animation
            Hero(
              tag: 'course-${course['title']}',
              child: Container(
                width: 120,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  image: DecorationImage(
                    image: course['image'] != null && !course['image'].toString().startsWith('assets/')
                        ? NetworkImage(courseProvider.getAssetUrl(course['image']))
                        : const AssetImage('assets/courses/python.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Course details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Use minimum height needed
                  children: [
                    Text(
                      course['title'],
                      style: const TextStyle(
                        fontSize: 18, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    Text(
                      course['description'],
                      style: TextStyle(
                        fontSize: 13, // Reduced font size
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(), // Push metadata to bottom
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.cyan[700]),
                        const SizedBox(width: 4),
                        Text(
                          course['duration'],
                          style: TextStyle(
                            color: Colors.cyan[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.person, size: 16, color: Colors.cyan[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            instructor['name'] ?? instructor['instructorName'] ?? 'Instructor',
                            style: TextStyle(
                              color: Colors.cyan[700],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // View details indicator
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}