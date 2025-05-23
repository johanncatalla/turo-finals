import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/role_select.dart';
import 'package:turo/Screens/Tutors/tutor_profileui_test.dart';

// Import DirectusService and dotenv
import 'package:turo/services/directus_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import the new tab widgets
import 'package:turo/screens/Tutors/tabs/dashboard_tab.dart';
import 'package:turo/screens/Tutors/tabs/courses_tab.dart';
import 'package:turo/screens/Tutors/tabs/modules_tab.dart';
import 'package:turo/screens/Tutors/tabs/videos_tab.dart';
import 'package:turo/screens/Tutors/tabs/reviews_tab.dart';

// import 'package:turo/Screens/Tutors/tutokfeed.dart'; // Placeholder

class TutorHomepage extends StatefulWidget {
  const TutorHomepage({super.key});

  @override
  State<TutorHomepage> createState() => _TutorHomepageState();
}

class _TutorHomepageState extends State<TutorHomepage>
    with TickerProviderStateMixin {
  String _tutorName = "Tutor";
  String? _tutorId;
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

  late DirectusService _directusService;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;
  String? _coursesError;
  String? _directusBaseUrl;

  @override
  void initState() {
    super.initState();
    _directusService = DirectusService();
    _directusBaseUrl = dotenv.env['BASE_URL'];

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        if (_currentTabIndex == 1 && (_courses.isEmpty || _coursesError != null) && !_isLoadingCourses) {
          _fetchTutorCourses();
        }
      }
    });
    _loadUserDataAndFetchInitialCourses();
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
      if (authProvider.user == null) {
        print("User data not available in AuthProvider (not logged in).");
        if (mounted) {
          setState(() {
            _tutorName = "Tutor";
            _isLoadingCourses = false;
            _coursesError = "User not logged in. Please log in to view courses.";
            _tutorId = null;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _tutorName = authProvider.user!.fullName ?? "Tutor";
        });
      }

      print("Fetching tutor profile...");
      final profileResponse = await _directusService.fetchTutorProfile();
      String? newTutorId;

      if (profileResponse['success'] == true && profileResponse['data'] != null) {
        final userData = profileResponse['data'];
        try {
          if (userData['tutor_profile'] != null &&
              userData['tutor_profile'] is List &&
              (userData['tutor_profile'] as List).isNotEmpty) {
            final tutorProfileData = userData['tutor_profile'][0];
            if (tutorProfileData != null && tutorProfileData['id'] != null) {
              newTutorId = tutorProfileData['id'].toString();
              print("Successfully fetched Tutor ID from profile: $newTutorId");
            }
          }
        } catch (e) {
          print("Error parsing tutor profile data: $e");
        }
      } else {
        print("Failed to fetch tutor profile: ${profileResponse['message'] ?? 'Unknown error'}");
        if (mounted) {
          setState(() {
            _isLoadingCourses = false;
            _coursesError = "Could not load tutor profile details. ${profileResponse['message'] ?? ''}";
            _tutorId = null;
          });
        }
        return;
      }

      if (newTutorId == null) {
        print("Tutor ID could not be determined from profile. Cannot load courses.");
        if (mounted) {
          setState(() {
            _isLoadingCourses = false;
            _coursesError = "Tutor ID not found in profile data. Cannot load courses.";
            _tutorId = null;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _tutorId = newTutorId;
          print('This is the tutor ID in use now: $_tutorId');
        });
      }

      if (_tutorId != null) {
        if (_currentTabIndex == 1 || _courses.isEmpty) {
          _fetchTutorCourses();
        } else {
          if (mounted) setState(() => _isLoadingCourses = false);
        }
      }
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
        _coursesError = null;
      });
    }

    final result = await _directusService.fetchCoursesByTutorId(_tutorId!);

    if (mounted) {
      setState(() {
        if (result['success']) {
          _courses = List<Map<String, dynamic>>.from(result['data']);
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
        // Reset to home icon on nav bar or handle as needed
        if (_bottomNavIndex != 0) {
          setState(() => _bottomNavIndex = 0);
        }
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea( // SafeArea now wraps the body
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              _buildHeroBanner(),
              _buildTabBar(),
              _buildTabContent(),
              // No SizedBox needed here for nav bar space, Scaffold handles it
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(), // Assigning the new nav bar here
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

  Widget _buildTabContent() {
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
                  isLoading: _isLoadingCourses,
                  coursesError: _coursesError,
                  courses: _courses,
                  directusBaseUrl: _directusBaseUrl,
                  tutorName: _tutorName,
                  onRetryFetchCourses: _fetchTutorCourses,
                  onRefreshCourses: _fetchTutorCourses,
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

  // MODIFIED: This is now the bottom navigation bar builder
  Widget _buildBottomNavBar() {
    // This outer Container provides padding for the "floating" effect and safe area adjustment
    return Container(
      color: Colors.transparent, // Allows scaffold background to show through the "margins"
      padding: EdgeInsets.only(
        left: 80.0,
        right: 80.0,
        top: 10.0, // Space above the nav bar
        bottom: MediaQuery.of(context).padding.bottom + 10.0, // Space below, respecting safe area + a little gap
      ),
      child: Container(
        // This is the actual visible navigation bar
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
            _buildNavItem(index: 1, icon: Icons.video_library), // Placeholder for Tutok
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
          // If already on profile and profile icon is tapped again, do nothing or refresh
          print("Profile Nav Tapped again, already on profile or navigated from it.");
          return;
        }

        // If tapping the current active icon (excluding profile which is handled above)
        // and it's not the profile nav that leads to a new page
        if (_bottomNavIndex == index && index != 2) {
          print("Nav item $index tapped, already selected.");
          // You might want to scroll to top or perform another action
          return;
        }

        setState(() {
          _bottomNavIndex = index;
        });

        if (index == 0) {
          print("Home Nav Tapped");
          // If "Home" should also reset the top tabs to Dashboard:
          // if (_tabController.index != 0) {
          //   _tabController.animateTo(0);
          // }
        } else if (index == 1) {
          print("Video/TutokFeed Nav Tapped - Placeholder");
          // TODO: Navigate to TutokFeed screen when available
          /*
          Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const TutokFeed()), // Ensure TutokFeed exists
           ).then((_) {
               if (mounted) {
                  // When returning from TutokFeed, set Home as active or last active tab
                  setState(() => _bottomNavIndex = 0);
               }
           });
           */
        } else if (index == 2) {
          print("Profile Nav Tapped");
          _navigateToProfile(); // This will navigate and then reset _bottomNavIndex to 0 on return via .then()
        }
      },
      borderRadius: BorderRadius.circular(20), // For ink splash effect
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