import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/role_select.dart';
import 'package:turo/Screens/Tutors/tutor_profileui_test.dart';
import 'package:turo/Screens/Tutors/tutor_createcourse.dart'; // Import Create Course screen

// Import DirectusService and dotenv (ensure these files exist and are set up)
import 'package:turo/services/directus_service.dart'; // Create this file if it doesn't exist
import 'package:flutter_dotenv/flutter_dotenv.dart';

//import 'package:turo/Screens/Tutors/tutor_createmodule.dart'; (TODO: To add tutor_createmodule)
// Import the TutokFeed screen when it exists
// import 'package:turo/Screens/Tutors/tutokfeed.dart'; // Placeholder for future import

class TutorHomepage extends StatefulWidget {
  const TutorHomepage({super.key});

  @override
  State<TutorHomepage> createState() => _TutorHomepageState();
}

class _TutorHomepageState extends State<TutorHomepage>
    with TickerProviderStateMixin {
  String _tutorName = "Tutor";
  String? _tutorId; // To store the tutor's ID from AuthProvider
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _bottomNavIndex = 0; // 0: Home, 1: TuTok, 2: Profile

  final Color _primaryColor = const Color(0xFF53C6D9);
  final Color _secondaryTextColor = Colors.grey.shade600;
  final Color _cardBackgroundColor = Colors.white;
  final Color _shadowColor = Colors.grey.withOpacity(0.15);
  final Color _borderColor = Colors.grey.shade300;
  final Color _floatingNavBackground = Colors.black87;
  final Color _floatingNavIconColor = Colors.grey.shade400;

  // State for courses tab
  late DirectusService _directusService;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;
  String? _coursesError;
  String? _directusBaseUrl;


  @override
  void initState() {
    super.initState();
    _directusService = DirectusService(); // Initialize DirectusService
    _directusBaseUrl = dotenv.env['BASE_URL']; // Get base URL for images

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Fetch courses when "Courses" tab (index 1) is selected,
        // if not already loaded, not currently loading, or if there was a previous error.
        if (_currentTabIndex == 1 && (_courses.isEmpty || _coursesError != null) && !_isLoadingCourses) {
          _fetchTutorCourses();
        }
      }
    });
    _loadUserDataAndFetchInitialCourses(); // Load user data and then courses
    _bottomNavIndex = 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserDataAndFetchInitialCourses() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. Check if the user is logged in via AuthProvider
      if (authProvider.user == null) {
        print("User data not available in AuthProvider (not logged in).");
        if (mounted) {
          setState(() {
            _tutorName = "Tutor"; // Default
            _isLoadingCourses = false;
            _coursesError = "User not logged in. Please log in to view courses.";
            _tutorId = null; // Explicitly null
          });
        }
        return;
      }

      // User is logged in, set the name first.
      if (mounted) {
        setState(() {
          _tutorName = authProvider.user!.fullName ?? "Tutor";
        });
      }

      // 2. Attempt to fetch the detailed Tutor Profile from Directus
      // This profile should contain the ID used to link to courses.
      print("Fetching tutor profile...");
      // Ensure _directusService.fetchTutorProfile() is implemented correctly
      // and returns a structure like {'success': bool, 'data': Map_or_null, 'message': String_or_null}
      final profileResponse = await _directusService.fetchTutorProfile();

      String? newTutorId; // Temporary variable to hold the ID from profile

      if (profileResponse['success'] == true && profileResponse['data'] != null) {
        final userData = profileResponse['data'];
        try {
          // Safely try to extract the tutor profile ID.
          // Adjust the path userData['tutor_profile'][0]['id'] based on your actual API response structure.
          if (userData['tutor_profile'] != null &&
              userData['tutor_profile'] is List &&
              (userData['tutor_profile'] as List).isNotEmpty) {
            final tutorProfileData = userData['tutor_profile'][0];
            if (tutorProfileData != null && tutorProfileData['id'] != null) {
              newTutorId = tutorProfileData['id'].toString();
              print("Successfully fetched Tutor ID from profile: $newTutorId");
            } else {
              print("Tutor profile data or ID is null in the response.");
            }
          } else {
            print("Tutor profile array is missing, not a list, or empty in API response.");
          }
        } catch (e) {
          print("Error parsing tutor profile data: $e");
          newTutorId = null; // Ensure it's null on error
        }
      } else {
        // Profile fetch failed
        print("Failed to fetch tutor profile: ${profileResponse['message'] ?? 'Unknown error'}");
        if (mounted) {
          setState(() {
            _isLoadingCourses = false;
            _coursesError = "Could not load tutor profile details. ${profileResponse['message'] ?? ''}";
            _tutorId = null; // Explicitly null
          });
        }
        return; // Stop if profile fetch fails, as we might need its ID
      }

      // 3. If Tutor ID from profile is still null here, it means profile fetch or parsing failed for the ID.
      //    Decide on a fallback or error. For now, we'll treat it as an error if newTutorId is null.
      if (newTutorId == null) {
        print("Tutor ID could not be determined from profile. Cannot load courses.");
        if (mounted) {
          setState(() {
            _isLoadingCourses = false;
            _coursesError = "Tutor ID not found in profile data. Cannot load courses.";
            _tutorId = null; // Explicitly null
          });
        }
        return;
      }

      // 4. Successfully obtained newTutorId from the profile. Set it.
      if (mounted) {
        setState(() {
          _tutorId = newTutorId; // This is the ID we will use for fetching courses
          print('This is the tutor ID in use now:');
          print(_tutorId);
        });
      }

      // 5. Now, fetch courses using the _tutorId obtained from the profile.
      if (_tutorId != null) {
        // Fetch courses if on the courses tab or if courses list is empty (initial load)
        if (_currentTabIndex == 1 || _courses.isEmpty) {
          _fetchTutorCourses();
        } else {
          // If not on courses tab initially, mark as not loading so it can load on tab switch
          if (mounted) {
            setState(() {
              _isLoadingCourses = false;
            });
          }
        }
      }
      // The case where _tutorId is null after this point should have been handled by returns above.
    });
  }

  Future<void> _fetchTutorCourses() async {
    if (_tutorId == null) {
      if (mounted) {
        setState(() {
          _coursesError = "Tutor ID is not available to fetch courses.";
          _isLoadingCourses = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingCourses = true;
        _coursesError = null; // Clear previous error
      });
    }

    final result = await _directusService.fetchCoursesByTutorId(_tutorId!);

    if (mounted) {
      setState(() {
        if (result['success']) {
          _courses = List<Map<String, dynamic>>.from(result['data']);
          // Optional: if _courses is empty, you could set a specific message
          if (_courses.isEmpty) _coursesError = "No courses found.";
        } else {
          _coursesError = result['message'] ?? "An unknown error occurred while fetching courses.";
        }
        _isLoadingCourses = false;
      });
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorProfileScreen()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _bottomNavIndex = 0; // Reset to home or relevant nav index
        });
        // Optionally, refresh user data if profile changes might affect display
        _loadUserDataAndFetchInitialCourses();
      }
    });
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text('Logout', style: TextStyle(color: _primaryColor)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    ) ?? false; // If dialog is dismissed, default to false

    if (shouldLogout && mounted) {
      await authProvider.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
            (route) => false,
      );
    }
  }

  // Build methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(),
                  _buildHeroBanner(),
                  _buildTabBar(),
                  _buildTabContent(),
                  // _buildCalendar(), (to fix)
                  const SizedBox(
                    height: 100, // Adjusted for floating nav bar
                  ),
                ],
              ),
            ),
          ),
          _buildFloatingNavBar(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _navigateToProfile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good day,',
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tutorName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: _primaryColor,
              ),
              iconSize: 24,
              onPressed: () {
                // TODO: Implement notification action
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      height: 200, // Adjusted height
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _primaryColor,
        image: const DecorationImage(
          image: AssetImage('assets/tutor-home.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
        indicatorWeight: 3.0,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Courses'),
          Tab(text: 'Modules'),
          Tab(text: 'Videos'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    // Using AnimatedSize for smoother transitions if content height changes
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        constraints: const BoxConstraints(minHeight: 200), // Minimum height for tab content
        child: Builder( // Use Builder to ensure correct context for Provider if needed within tabs
          builder: (context) {
            switch (_currentTabIndex) {
              case 0:
                return _buildDashboardTab();
              case 1:
                return _buildCoursesTab(); // This will be the modified tab
              case 2:
                return _buildModulesTab();
              case 3:
                return _buildVideosTab();
              case 4:
                return _buildReviewsTab();
              default:
                return Container();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPlaceholderCard(
                  height: 150,
                  label: "Scheduled Classes\n(Placeholder)",
                  icon: Icons.calendar_today,
                  iconColor: _primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlaceholderCard(
                  height: 150,
                  label: "Overall Performance\n(Placeholder)",
                  icon: Icons.show_chart,
                  iconColor: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPlaceholderCard(
                  height: 180,
                  label: "Earnings Chart\n(Placeholder)",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlaceholderCard(
                  height: 180,
                  label: "Time Spent Chart\n(Placeholder)",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // MODIFIED Courses Tab
  Widget _buildCoursesTab() {
    final createCourseButton = ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateCourseScreen(),
          ),
        ).then((result) {
          // If the create screen might indicate success (e.g., returns true), refresh.
          // Or simply refresh always if a course might have been added.
          if (result == true || result == null) { // result == null if back button is pressed
            _fetchTutorCourses();
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor.withOpacity(0.1),
        foregroundColor: _primaryColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Create Course',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    if (_isLoadingCourses) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
    }

    if (_coursesError != null && _courses.isEmpty) { // Show error only if no courses could be loaded at all
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_coursesError', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _fetchTutorCourses, child: const Text("Retry")),
              const SizedBox(height: 20),
              createCourseButton, // Still offer to create a course
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30), // Give some space from the tab bar
            Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "You haven't created any courses yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_coursesError != null) // Show a subtle error if courses are empty but an error occurred during last fetch
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Last attempt to fetch failed: $_coursesError",
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            createCourseButton,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Optional: Show an error message if refresh failed but old data is present
          if (_coursesError != null && _courses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Couldn't refresh courses: $_coursesError",
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.refresh, size: 18, color: Colors.orange.shade700), onPressed: _fetchTutorCourses)
                  ],
                ),
              ),
            ),
          ListView.builder(
            shrinkWrap: true, // Important as it's inside SingleChildScrollView via Column
            physics: const NeverScrollableScrollPhysics(), // To disable ListView's own scrolling
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              final course = _courses[index]; // course is a Map<String, dynamic>
              String? imageUrl;
              String courseTitle = course['title'] as String? ?? 'Untitled Course';
              String courseDescription = course['description'] as String? ?? 'No description available.';
              String courseDuration = course['duration'] as String? ?? "N/A";

              // Extract image ID from the expanded course_image object
              if (course['course_image'] != null && course['course_image'] is Map) {
                final imageObject = course['course_image'] as Map<String, dynamic>;
                final imageId = imageObject['id'] as String?;

                if (imageId != null && _directusBaseUrl != null) {
                  imageUrl = '$_directusBaseUrl/assets/$imageId';
                  print('Constructed Image URL for "${courseTitle}": $imageUrl');
                } else {
                  print('Image ID or Directus Base URL is null for course: "${courseTitle}". Image ID from object: $imageId');
                }
              } else {
                // print('Course image data is null or not a map for course: "${courseTitle}". Data: ${course['course_image']}');
              }

              // Extract instructor name from tutor_id.user_id.*
              String instructorName = _tutorName; // Default to logged-in tutor's name from state
              if (course['tutor_id'] != null && course['tutor_id'] is Map) {
                final tutorObject = course['tutor_id'] as Map<String, dynamic>;
                if (tutorObject['user_id'] != null && tutorObject['user_id'] is Map) {
                  final userObject = tutorObject['user_id'] as Map<String, dynamic>;
                  String? firstName = userObject['first_name'] as String?;
                  String? lastName = userObject['last_name'] as String?;

                  if (firstName != null && firstName.isNotEmpty && lastName != null && lastName.isNotEmpty) {
                    instructorName = '$firstName $lastName';
                  } else if (firstName != null && firstName.isNotEmpty) {
                    instructorName = firstName;
                  } else if (lastName != null && lastName.isNotEmpty) {
                    instructorName = lastName; // Less common to use only last name, but a fallback
                  }
                  // If both are null or empty, instructorName remains _tutorName (from widget state)
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildCourseCard(
                  imagePath: imageUrl,
                  isNetworkImage: imageUrl != null,
                  fallbackImageAsset: 'assets/English.png',
                  title: courseTitle,
                  time: courseDuration,
                  instructor: instructorName,
                  description: courseDescription,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          createCourseButton,
        ],
      ),
    );
  }

  // MODIFIED Course Card to handle network images
  Widget _buildCourseCard({
    String? imagePath, // Can be a network URL or local asset path
    bool isNetworkImage = false, // True if imagePath is a network URL
    required String fallbackImageAsset, // Fallback asset if network/local fails or path is null
    required String title,
    required String time,
    required String instructor,
    required String description,
  }) {
    Widget imageWidget;

    if (isNetworkImage && imagePath != null) {
      imageWidget = Image.network(
        imagePath,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Container( // Placeholder while loading
            width: 90,
            height: 90,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                strokeWidth: 2.0,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) { // Fallback to asset on network error
          print("Network image error: $error for path $imagePath");
          return Image.asset(
            fallbackImageAsset,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          );
        },
      );
    } else if (!isNetworkImage && imagePath != null) { // If it's explicitly an asset path
      imageWidget = Image.asset(
        imagePath, // Assumed to be a local asset path already
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset( // Fallback for local asset error
          fallbackImageAsset,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    }
    else { // Default fallback if imagePath is null or not specified as network/local
      imageWidget = Image.asset(
        fallbackImageAsset,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: imageWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1, // Ensure title doesn't take too much space
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: _secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded( // Allow time text to take space
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Reduced space
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: _secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded( // Allow instructor name to take space
                      child: Text(
                        instructor,
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor.withOpacity(0.9),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: [
          _buildModuleCard(
            title: "Photosynthetic Process In Plants",
            tags: "Science | Biology | Highschool",
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            title: "Photosynthetic Process In Plants",
            tags: "Science | Biology | Highschool",
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              /*
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateModuleScreen(),
                ),
              );
              print(
                "Create Module button tapped - Navigating to CreateCourseScreen (TEMP)",
              );
              */
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor.withOpacity(0.1),
              foregroundColor: _primaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Create Module',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({required String title, required String tags}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _borderColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
        CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight
                        .w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  tags,
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.grey.shade600,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildVideosTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildVideoCard(
            thumbnailAsset: 'assets/journalism_video.png',
            title: "What is Journalism",
            views: "20.6k Views",
            comments: "5000 Comments",
            earnings: "12.3k Pesos",
          ),
          const SizedBox(height: 16),
          _buildVideoCard(
            thumbnailAsset: 'assets/journalism_video.png',
            title: "What is Journalism",
            views: "20.6k Views",
            comments: "5000 Comments",
            earnings: "12.3k Pesos",
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard({
    required String thumbnailAsset,
    required String title,
    required String views,
    required String comments,
    required String earnings,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(
                  thumbnailAsset,
                  width: 100, // Example width
                  height: 75,  // Example height
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100, height: 75, color: Colors.grey.shade300,
                    child: Icon(Icons.videocam_off_outlined, color: Colors.grey.shade600),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Icon(Icons.play_circle_outline_rounded, color: Colors.white.withOpacity(0.8), size: 30),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$views   $comments",
                  style: TextStyle(fontSize: 11, color: _secondaryTextColor),
                ),
                Text(
                  earnings,
                  style: TextStyle(fontSize: 11, color: _secondaryTextColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildActionButton(label: "Edit", onPressed: () {}),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: "Boost",
                      onPressed: () {},
                      isPrimary: true,
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

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor:
          isPrimary ? _primaryColor.withOpacity(0.1) : Colors.grey.shade200,
          foregroundColor: isPrimary ? _primaryColor : Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: [
          _buildReviewCard(
            imageAsset: 'assets/English.png',
            reviewerName: "John Leo Echevarria",
            date: "September 10, 2023",
            reviewText:
            "Excellent tutor! Adjusts his lesson to my level of understanding and provides a comfortable learning atmosphere in his class. 10/10 would recommend!",
            rating: 5,
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            imageAsset: 'assets/English.png',
            reviewerName: "John Leo Echevarria",
            date: "September 10, 2023",
            reviewText:
            "Excellent tutor! Adjusts his lesson to my level of understanding and provides a comfortable learning atmosphere in his class. 10/10 would recommend!",
            rating: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String imageAsset,
    required String reviewerName,
    required String date,
    required String reviewText,
    required int rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(
          color: _borderColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.asset(
              imageAsset,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.person_pin_circle_outlined,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reviewerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: _secondaryTextColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reviewText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87.withOpacity(
                      0.85,
                    ),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    5,
                        (index) => Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber.shade600,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required double height,
    required String label,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 30, color: iconColor ?? _secondaryTextColor),
            if (icon != null) const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Positioned(
      bottom: 20.0,
      left: 30.0,
      right: 30.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: _floatingNavBackground,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 0, icon: Icons.home_filled),
            _buildNavItem(index: 1, icon: Icons.video_library),
            _buildNavItem(index: 2, icon: Icons.person_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon}) {
    bool isSelected = _bottomNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });

        if (index == 0) {
          print("Home Nav Tapped");
          // If tapping home should also reset the tab controller to the first tab:
          // _tabController.animateTo(0);
        } else if (index == 1) {
          print("Video/TutokFeed Nav Tapped - Navigation Commented Out");
          /*
          // UNCOMMENT WHEN TutokFeed page is created:
          Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const TutokFeed()),
           ).then((_) {
               if (mounted) {
                 setState(() {
                   _bottomNavIndex = 0; // Or the index for "Home" if that's the desired return state
                 });
               }
           });
           */
        } else if (index == 2) {
          print("Profile Nav Tapped");
          _navigateToProfile();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : _floatingNavIconColor,
              size: 26.0,
            ),
            const SizedBox(height: 4.0),
            Container(
              height: 3.0,
              width: 20.0,
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}