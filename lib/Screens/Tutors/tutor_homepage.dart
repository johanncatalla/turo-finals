import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/providers/course_provider.dart'; // Import CourseProvider
import 'package:turo/role_select.dart';
import 'package:turo/Screens/Tutors/tutor_profileui_test.dart';

// Import the new tab widgets
import 'package:turo/screens/Tutors/tabs/dashboard_tab.dart';
import 'package:turo/screens/Tutors/tabs/courses_tab.dart';
import 'package:turo/screens/Tutors/tabs/modules_tab.dart';
import 'package:turo/screens/Tutors/tabs/videos_tab.dart';
import 'package:turo/screens/Tutors/tabs/reviews_tab.dart';

class TutorHomepage extends StatefulWidget {
  const TutorHomepage({super.key});

  @override
  State<TutorHomepage> createState() => _TutorHomepageState();
}

class _TutorHomepageState extends State<TutorHomepage>
    with TickerProviderStateMixin {
  // String _tutorName = "Tutor"; // Will get from AuthProvider
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _bottomNavIndex = 0;

  final Color _primaryColor = const Color(0xFF53C6D9);
  final Color _secondaryTextColor = Colors.grey.shade600;
  final Color _cardBackgroundColor = Colors.white;
  final Color _shadowColor = Colors.grey.withOpacity(0.15);
  final Color _borderColor = Colors.grey.shade300;
  final Color _floatingNavBackground = Colors.black87;
  final Color _floatingNavIconColor = Colors.grey.shade400;

  // Removed local course state, will use CourseProvider
  // late DirectusService _directusService; // Not needed directly for courses anymore
  // List<Map<String, dynamic>> _courses = [];
  // bool _isLoadingCourses = true;
  // String? _coursesError;
  // String? _directusBaseUrl; // Will get from CourseProvider

  @override
  void initState() {
    super.initState();
    // _directusService = DirectusService(); // Not needed directly for courses
    // _directusBaseUrl = dotenv.env['DIRECTUS_API_URL']; // Get from CourseProvider

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // No need to manually fetch courses here, CourseProvider handles it.
        // We might want to refresh if the tab becomes active and data is stale,
        // but CourseProvider's initialize should handle initial load.
      }
    });
    _initializeProvidersAndUserData();
    _bottomNavIndex = 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeProvidersAndUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      if (authProvider.user == null) {
        // User not logged in, AuthProvider should handle this state
        // print("User data not available in AuthProvider (not logged in).");
        return;
      }

      // Ensure CourseProvider is initialized.
      // If courses are empty and not loading, and instructors are loaded, just fetch courses.
      // If instructors are also not loaded, do a full initialize.
      // This logic can be refined based on when/how often you want to re-fetch.
      if (courseProvider.courses.isEmpty && !courseProvider.isLoading && courseProvider.instructors.isNotEmpty) {
        // print("TutorHomepage: Instructors loaded, courses empty. Fetching courses.");
        await courseProvider.fetchCourses();
      } else if (courseProvider.instructors.isEmpty && !courseProvider.isLoading) {
        // print("TutorHomepage: CourseProvider not fully initialized. Initializing now.");
        await courseProvider.initialize();
      } else {
        // print("TutorHomepage: CourseProvider seems initialized or is loading.");
      }
      // No need to call _fetchTutorCourses anymore.
      // setState will be triggered by Provider listeners when data changes.
    });
  }

  // Removed _fetchTutorCourses, as CourseProvider will handle this.
  // Future<void> _fetchTutorCourses() async { ... }

  void _refreshCourseData() {
    // This can be called to explicitly refresh data from CourseProvider
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    // print("TutorHomepage: Refreshing course data via CourseProvider.initialize()");
    courseProvider.initialize(); // Or just .fetchCourses() if only courses need refresh
  }


  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorProfileScreen()),
    ).then((_) {
      if (mounted) {
        if (_bottomNavIndex != 0) {
          setState(() => _bottomNavIndex = 0);
        }
        // Optionally, refresh data if profile changes might affect displayed info
        _initializeProvidersAndUserData();
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
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Logout', style: TextStyle(color: _primaryColor)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (shouldLogout && mounted) {
      await authProvider.logout();
      if (!mounted) return;
      // Clear CourseProvider data on logout if necessary, or let it re-initialize on next login
      // Provider.of<CourseProvider>(context, listen: false).clearData(); // Example method
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get providers
    final authProvider = Provider.of<AuthProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    // Get tutor name from AuthProvider
    final String tutorName = authProvider.user?.fullName ?? "Tutor";
    final String? currentUserId = authProvider.user?.id;

    // Filter courses from CourseProvider
    List<Map<String, dynamic>> tutorSpecificCourses = [];
    if (authProvider.status == AuthStatus.authenticated && currentUserId != null) {
      tutorSpecificCourses = courseProvider.courses.where((course) {
        // 'tutorUserId' is populated in CourseProvider._mapDirectusCoursesToCourses
        return course['tutorUserId'] == currentUserId;
      }).toList();
      print("TutorHomepage: Filtered ${tutorSpecificCourses.length} courses for tutor ID $currentUserId");
    } else {
      print("TutorHomepage: User not authenticated or ID null, no courses to filter.");
    }

    // Get Directus base URL from CourseProvider (which gets it from DirectusService)
    final String? directusBaseUrl = dotenv.env['DIRECTUS_API_URL'];
    // print(directusBaseUrl);

    if (authProvider.status == AuthStatus.unknown) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authProvider.status == AuthStatus.unauthenticated) {
      // This case should ideally lead to a login screen, but for safety:
      return Scaffold(
        appBar: AppBar(title: const Text("Tutor Home")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Please log in to continue."),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                      (route) => false,
                ),
                child: const Text("Go to Login"),
              )
            ],
          ),
        ),
      );
    }


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(tutorName), // Pass tutorName
              _buildHeroBanner(),
              _buildTabBar(),
              _buildTabContent(
                isLoading: courseProvider.isLoading, // From CourseProvider
                coursesError: courseProvider.error, // From CourseProvider
                courses: tutorSpecificCourses, // Filtered list
                directusBaseUrl: directusBaseUrl, // From CourseProvider
                tutorName: tutorName, // From AuthProvider
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildWelcomeHeader(String name) { // Accept name as parameter
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
                  name, // Use passed name
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
              onPressed: () { /* TODO: Notification action */ },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      height: 200,
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

  Widget _buildTabContent({
    required bool isLoading,
    required String? coursesError,
    required List<Map<String, dynamic>> courses,
    required String? directusBaseUrl,
    required String tutorName,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        child: Builder(
          builder: (context) {
            switch (_currentTabIndex) {
              case 0:
                return DashboardTab(
                  primaryColor: _primaryColor,
                  secondaryTextColor: _secondaryTextColor,
                  cardBackgroundColor: _cardBackgroundColor,
                  shadowColor: _shadowColor,
                  borderColor: _borderColor,
                );
              case 1:
                return CoursesTab(
                  isLoading: isLoading, // Pass from params
                  coursesError: coursesError, // Pass from params
                  courses: courses, // Pass from params (filtered list)
                  // directusBaseUrl: directusBaseUrl, // Pass from params
                  tutorName: tutorName, // Pass from params
                  onRetryFetchCourses: _refreshCourseData, // Use new refresh method
                  onRefreshCourses: _refreshCourseData, // Use new refresh method
                  primaryColor: _primaryColor,
                  secondaryTextColor: _secondaryTextColor,
                  cardBackgroundColor: _cardBackgroundColor,
                  shadowColor: _shadowColor,
                  borderColor: _borderColor,
                );
              case 2:
                return ModulesTab(
                  primaryColor: _primaryColor,
                  secondaryTextColor: _secondaryTextColor,
                  cardBackgroundColor: _cardBackgroundColor,
                  shadowColor: _shadowColor,
                  borderColor: _borderColor,
                );
              case 3:
                return VideosTab(
                  primaryColor: _primaryColor,
                  secondaryTextColor: _secondaryTextColor,
                  cardBackgroundColor: _cardBackgroundColor,
                  shadowColor: _shadowColor,
                  borderColor: _borderColor,
                );
              case 4:
                return ReviewsTab(
                  secondaryTextColor: _secondaryTextColor,
                  cardBackgroundColor: _cardBackgroundColor,
                  shadowColor: _shadowColor,
                  borderColor: _borderColor,
                );
              default:
                return Container();
            }
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 80.0,
        right: 80.0,
        top: 10.0,
        bottom: MediaQuery.of(context).padding.bottom + 10.0,
      ),
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
        if (_bottomNavIndex == index && index == 2) {
          return;
        }
        if (_bottomNavIndex == index && index != 2) {
          return;
        }
        setState(() {
          _bottomNavIndex = index;
        });

        if (index == 0) {
          // Home
        } else if (index == 1) {
          // Video/TutokFeed - Placeholder
        } else if (index == 2) {
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