import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/role_select.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomepage> {
  // Tab selection state
  int _selectedCourseTab = 0;
  final List<String> _courseTabs = ['Hot', 'Programming', 'Language', 'Math'];
  
  // Selected menu item
  int _selectedMenuIndex = 0;

  // User data - to be populated from auth provider
  String _userName = "Juan Dela Cruz";

  // Dummy data for instructors
  final List<Map<String, dynamic>> _instructors = [
    {
      'name': 'Johann',
      'image': 'assets/joshua.png',
    },
    {
      'name': 'Leo',
      'image': 'assets/joshua.png',
    },
    {
      'name': 'Nicole',
      'image': 'assets/joshua.png',
    },
    {
      'name': 'Joshua',
      'image': 'assets/joshua.png',
    },
  ];

  // Dummy data for courses
  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Introduction to Python',
      'description': 'An engaging beginner-friendly course that introduces the fundamentals of Python...',
      'instructor': 'Mr. J. Seb Catalla',
      'duration': '1hr/day',
      'image': 'assets/courses/python.png',
      'categories': ['Hot', 'Programming'],
    },
    {
      'title': 'Conversational English',
      'description': 'A practical course designed to build confidence and fluency in conversational...',
      'instructor': 'Mr. J.L Echevaria',
      'duration': '1hr/day',
      'image': 'assets/courses/python.png',
      'categories': ['Hot', 'Language'],
    },
    {
      'title': 'Foundational Algebra',
      'description': 'A foundational course that explores the core principles of algebra, including solving...',
      'instructor': 'Ms. PNC. Oriola',
      'duration': '1hr/day',
      'image': 'assets/courses/python.png',
      'categories': ['Hot', 'Math'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null, // Remove the app bar completely
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message and notification button
                _buildWelcomeHeader(),
                
                // Hero Banner with search bar overlay
                _buildHeroBanner(),
          
                // Instructors Section
                _buildSectionHeader('Instructors', () {}),
                _buildInstructorsRow(),
          
                // Courses Section
                _buildSectionHeader('Courses', () {}),
                _buildCoursesTabs(),
                _buildCoursesListing(),
                
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
            child: _buildBottomNavigationBar(),
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
  Widget _buildInstructorsRow() {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(left: 6, right: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _instructors.length,
        itemBuilder: (context, index) {
          return _buildInstructorItem(_instructors[index]);
        },
      ),
    );
  }

  Widget _buildInstructorItem(Map<String, dynamic> instructor) {
    return Padding(
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
                  image: AssetImage(instructor['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            instructor['name'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
  Widget _buildCoursesListing() {
    // Filter courses based on selected tab
    final String selectedCategory = _courseTabs[_selectedCourseTab];
    final filteredCourses = _courses.where((course) {
      return course['categories'].contains(selectedCategory);
    }).toList();

    // Calculate the minimum height for 3 items
    // Each course item is about 140 pixels high (120px image height + margins)
    final minHeight = 3 * 140.0;

    return Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
      ),
      child: ListView.builder(
        shrinkWrap: true, // Make list take only the space it needs
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling
        itemCount: filteredCourses.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return _buildCourseItem(filteredCourses[index]);
        },
      ),
    );
  }

  // Individual course item
  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              course['image'],
              width: 120,
              height: 120,
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  course['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.cyan[700]),
                    const SizedBox(width: 4),
                    Text(
                      course['duration'],
                      style: TextStyle(
                        color: Colors.cyan[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 18, color: Colors.cyan[700]),
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
    );
  }
  
  // Bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 16),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home, "Home"),
          _buildNavItem(1, Icons.search, "Search"),
          _buildNavItem(2, Icons.library_books_outlined, "My Courses"),
          _buildNavItem(3, Icons.person_outline, "Profile"),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedMenuIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMenuIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.orange : Colors.white60,
            size: 24,
          ),
          SizedBox(height: 4),
          if (isSelected) // Show the indicator for the selected item
            Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}