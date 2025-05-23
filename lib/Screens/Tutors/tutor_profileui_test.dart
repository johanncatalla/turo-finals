import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show PointerDeviceKind;

// Provider imports
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/directus_service.dart';

// Import your custom tab widgets
import '../../screens/Tutors/tabs/courses_tab.dart';
import '../../screens/Tutors/tabs/modules_tab.dart';
import '../../screens/Tutors/tabs/reviews_tab.dart';
// Import TutorHomepage if needed for navigation
import '../../screens/Tutors/tutor_homepage.dart';
import 'EditTutorProfileScreen.dart'; // Assuming this is the path
// --- IMPORT YOUR ROLE SELECTION SCREEN ---
// import '../../screens/Authentication/role_select.dart'; // Example path, adjust as needed


// Data Models (keep as they were)
class Course {
  final String title;
  final String details;
  final String description;
  final String imagePath;
  final String? rate;

  Course({
    required this.title,
    required this.details,
    required this.description,
    required this.imagePath,
    this.rate,
  });

  String get duration {
    final parts = details.split('•');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  String get tutor {
    final parts = details.split('•');
    return parts.length > 1 ? parts[1].trim() : '';
  }
}

class NavBarItem {
  final IconData icon;
  final String label;

  NavBarItem({required this.icon, required this.label});
}

class Review {
  final String name;
  final String date;
  final String reviewText;
  final int rating;
  final String imagePath;

  Review({
    required this.name,
    required this.date,
    required this.reviewText,
    required this.rating,
    required this.imagePath,
  });
}

// App Colors & Constants
const Color primaryTeal = Color(0xFF3F8E9B);
const Color darkCharcoal = Color(0xFF303030);
const Color lightGreyBg = Color(0xFFF5F5F5);
const Color logoutRed = Color(0xFFE57373); // Added for logout button

// Global Image Error Builder
Widget globalImageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
  return Container(
    color: Colors.grey[200],
    alignment: Alignment.center,
    child: Icon(
      Icons.broken_image_outlined,
      color: Colors.grey[400],
      size: 30,
    ),
  );
}

class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 2;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? tutorProfileData;
  List<dynamic>? subjectsData;
  bool isLoading = true;
  String? errorMessage;

  final DirectusService _directusService = DirectusService();

  final Color _primaryColor = primaryTeal;
  final Color _secondaryTextColor = Colors.grey.shade600;
  final Color _cardBackgroundColor = Colors.white;
  final Color _shadowColor = Colors.grey.withOpacity(0.1);
  final Color _borderColor = Colors.grey.shade300;

  final Color _floatingNavBackground = Colors.black87;
  final Color _floatingNavIconColor = Colors.grey.shade400;

  final List<IconData> _bottomNavIcons = [
    Icons.home_filled,
    Icons.video_library,
    Icons.person_outline,
  ];

  final _imageErrorBuilder = globalImageErrorBuilder;

  @override
  void initState() {
    super.initState();
    _bottomNavIndex = 2;
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging ||
          _tabController.index != _tabController.previousIndex) {
        if (mounted) setState(() {});
      }
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
      userData = null;
      tutorProfileData = null;
      subjectsData = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    if (authProvider.user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "User not authenticated.";
        });
      }
      return;
    }
    final userID = authProvider.user!.id;

    try {
      final authUserResponse = await authProvider.getFullUserProfile();
      if (!mounted) return;

      if (authUserResponse['success']) {
        userData = authUserResponse['data'];
      } else {
        errorMessage = authUserResponse['message'] ?? "Failed to load basic user profile.";
      }

      final expandedTutorProfileResponse = await _directusService.fetchTutorProfileByUserId(userID);
      if (!mounted) return;

      if (expandedTutorProfileResponse['success']) {
        final fetchedData = expandedTutorProfileResponse['data'];
        if (fetchedData != null) {
          if (userData == null) {
            userData = {
              'first_name': fetchedData['first_name'],
              'last_name': fetchedData['last_name'],
              'email': fetchedData['email'],
              'avatar': fetchedData['avatar'],
            };
          } else {
            if (fetchedData['avatar'] != null) {
              userData!['avatar'] = fetchedData['avatar'];
            }
          }

          final rawTutorProfile = fetchedData['tutor_profile'];
          if (rawTutorProfile is List && rawTutorProfile.isNotEmpty) {
            if (rawTutorProfile[0] is Map<String, dynamic>) {
              tutorProfileData = rawTutorProfile[0] as Map<String, dynamic>;
            }
          } else if (rawTutorProfile is Map<String, dynamic>) {
            tutorProfileData = rawTutorProfile;
          }

          if (tutorProfileData != null) {
            if (tutorProfileData!.containsKey('subjects') && tutorProfileData!['subjects'] is List) {
              subjectsData = tutorProfileData!['subjects'] as List<dynamic>;
            } else {
              subjectsData = [];
            }
          } else {
            tutorProfileData = {};
            subjectsData = [];
          }
        }
      } else {
        if (userData != null && (tutorProfileData == null || tutorProfileData!.isEmpty)) {
          errorMessage = (errorMessage == null ? "" : "$errorMessage\n") +
              (expandedTutorProfileResponse['message'] ?? "Failed to load detailed tutor profile.");
        } else if (userData == null) {
          errorMessage = expandedTutorProfileResponse['message'] ?? "Failed to load any profile data.";
        }
      }

      if (courseProvider.courses.isEmpty && !courseProvider.isLoading) {
        await courseProvider.initialize();
      }

    } catch (e) {
      if (mounted) {
        errorMessage = 'An error occurred: ${e.toString()}';
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshCourseProviderData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.fetchCourses();
  }

  // --- LOGOUT METHOD ---
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: logoutRed),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      // IMPORTANT: Replace '/role_select' with the actual named route
      // for your role selection screen in your MaterialApp.
      // If you don't use named routes, navigate directly:
      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (context) => RoleSelectScreen()), // Ensure RoleSelectScreen is imported
      //   (Route<dynamic> route) => false,
      // );
      Navigator.of(context).pushNamedAndRemoveUntil('/role_select', (Route<dynamic> route) => false);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: false),
        body: const Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    if (errorMessage != null && userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Profile data could not be loaded.", style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24, color: darkCharcoal),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: darkCharcoal, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        actions: [
          // --- MODIFIED: Replaced Settings with Logout Button ---
          IconButton(
            icon: const Icon(Icons.logout, size: 24, color: logoutRed), // Logout icon and color
            tooltip: 'Logout',
            onPressed: _handleLogout, // Call the logout handler
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(child: _buildProfileHeader(context)),
            SliverToBoxAdapter(child: _buildTutorInfoSection(context)),
            if (subjectsData != null && subjectsData!.isNotEmpty)
              SliverToBoxAdapter(child: _buildSubjectsSection(context)),
            SliverToBoxAdapter(child: _buildCertificationsSection(context)),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _primaryColor,
                  tabs: const [
                    Tab(text: 'Courses'),
                    Tab(text: 'Modules'),
                    Tab(text: 'Reviews'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCoursesTabContent(context),
            ModulesTab(
              primaryColor: _primaryColor,
              secondaryTextColor: _secondaryTextColor,
              cardBackgroundColor: _cardBackgroundColor,
              shadowColor: _shadowColor,
              borderColor: _borderColor,
            ),
            ReviewsTab(
              secondaryTextColor: _secondaryTextColor,
              cardBackgroundColor: _cardBackgroundColor,
              shadowColor: _shadowColor,
              borderColor: _borderColor,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildCoursesTabContent(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context);

    if (authProvider.user == null) {
      return const Center(child: Text("User not logged in."));
    }

    final String tutorName = userData?['first_name'] != null && userData?['last_name'] != null
        ? '${userData!['first_name']} ${userData!['last_name']}'.trim()
        : "Tutor";
    final String? currentUserId = authProvider.user!.id;

    List<Map<String, dynamic>> tutorSpecificCourses = [];
    if (currentUserId != null) {
      tutorSpecificCourses = courseProvider.courses.where((course) {
        return course['tutorUserId'] == currentUserId;
      }).toList();
    }

    bool effectiveIsLoading = courseProvider.isLoading;
    String? effectiveCoursesError = courseProvider.error;

    return CoursesTab(
      isLoading: effectiveIsLoading,
      coursesError: effectiveCoursesError,
      courses: tutorSpecificCourses,
      tutorName: tutorName,
      onRetryFetchCourses: _refreshCourseProviderData,
      onRefreshCourses: _refreshCourseProviderData,
      primaryColor: _primaryColor,
      secondaryTextColor: _secondaryTextColor,
      cardBackgroundColor: _cardBackgroundColor,
      shadowColor: _shadowColor,
      borderColor: _borderColor,
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final firstName = userData!['first_name'] ?? 'User';
    final lastName = userData!['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final bio = tutorProfileData?['bio'] ?? 'A dedicated tutor with a passion for teaching.';
    final isVerified = tutorProfileData?['verified'] == true;
    final String? avatarId = userData!['avatar'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.asset(
                'assets/cover.png',
                fit: BoxFit.cover,
                errorBuilder: _imageErrorBuilder,
              ),
            ),
            Positioned(
              bottom: -35,
              left: 20,
              child: CircleAvatar(
                radius: 47,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (avatarId != null && avatarId.isNotEmpty)
                      ? NetworkImage(_directusService.getAssetUrl(avatarId))
                  as ImageProvider
                      : const AssetImage('assets/profile.png'),
                  onBackgroundImageError: (exception, stackTrace) {},
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 55),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkCharcoal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isVerified)
                          Icon(Icons.verified, color: _primaryColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const EditTutorProfileScreen()),
                  );
                  if (result == true && mounted) {
                    _loadInitialData();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryTeal,
                  side: const BorderSide(color: primaryTeal, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 34),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFEEEEEE), height: 1),
      ],
    );
  }

  Widget _buildTutorInfoSection(BuildContext context) {
    final education = tutorProfileData?['education_background'] ?? 'Not specified';
    final hourRateValue = tutorProfileData?['hour_rate'];
    final hourRate = hourRateValue != null ? '₱${hourRateValue.toString()}' : 'Not specified';
    String teachLevels = 'Not specified';

    if (tutorProfileData != null && tutorProfileData!['teach_levels'] != null) {
      if (tutorProfileData!['teach_levels'] is List) {
        List<dynamic> levelsList = tutorProfileData!['teach_levels'];
        if (levelsList.isNotEmpty) {
          List<String> levelNames = [];
          for (var levelItem in levelsList) {
            if (levelItem is Map<String, dynamic> && levelItem.containsKey('TeachLevels_id')) {
              var teachLevelInner = levelItem['TeachLevels_id'];
              if (teachLevelInner is Map<String, dynamic> && teachLevelInner.containsKey('name')) {
                levelNames.add(teachLevelInner['name'].toString());
              }
            }
          }
          if (levelNames.isNotEmpty) {
            teachLevels = levelNames.join(', ');
          }
        }
      } else if (tutorProfileData!['teach_levels'] is String) {
        teachLevels = tutorProfileData!['teach_levels'];
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tutor Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkCharcoal),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.school_outlined, 'Education', education),
          const SizedBox(height: 8),
          _buildInfoItem(Icons.attach_money_outlined, 'Hourly Rate', hourRate),
          const SizedBox(height: 8),
          _buildInfoItem(Icons.groups_outlined, 'Teaching Levels', teachLevels),
        ],
      ),
    );
  }

  Widget _buildSubjectsSection(BuildContext context) {
    if (subjectsData == null || subjectsData!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subjects',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkCharcoal),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
                subjectsData!.length, (index) {
              final subjectItem = subjectsData![index];
              String subjectName = 'Subject';
              if (subjectItem is Map<String, dynamic> && subjectItem.containsKey('Subjects_id')) {
                var subjectDetails = subjectItem['Subjects_id'];
                if (subjectDetails is Map<String, dynamic> && subjectDetails.containsKey('subject_name')) {
                  subjectName = subjectDetails['subject_name'] ?? 'Subject';
                }
              } else if (subjectItem is Map<String, dynamic> && subjectItem.containsKey('name')) {
                subjectName = subjectItem['name'] ?? 'Subject';
              } else if (subjectItem is String) {
                subjectName = subjectItem;
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  subjectName,
                  style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w500),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: darkCharcoal)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection(BuildContext context) {
    final certifications = [
      {
        'title': 'English Proficiency for Customer Service Workers',
        'description': '${userData!['first_name'] ?? 'User'} just earned a TESDA certification! At Turo, we support our tutors in getting certified to ensure quality education for our students.',
        'imagePath': 'assets/certificate.png',
      },
    ];
    if (certifications.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 125,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: certifications.length,
        itemBuilder: (context, index) {
          final cert = certifications[index];
          return _buildCertificationCard(cert['title']!, cert['description']!, cert['imagePath']!);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 12),
      ),
    );
  }

  Widget _buildCertificationCard(String title, String description, String imagePath) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(imagePath, fit: BoxFit.contain, errorBuilder: _imageErrorBuilder),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 80.0, right: 80.0, top: 10.0,
        bottom: MediaQuery.of(context).padding.bottom + 10.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: _floatingNavBackground,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 0, icon: _bottomNavIcons[0]),
            _buildNavItem(index: 1, icon: _bottomNavIcons[1]),
            _buildNavItem(index: 2, icon: _bottomNavIcons[2]),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon}) {
    bool isSelected = _bottomNavIndex == index;
    return InkWell(
      onTap: () {
        if (_bottomNavIndex == index) return;
        if (mounted) setState(() => _bottomNavIndex = index);

        if (index == 0) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).popUntil((route) => route.settings.name == '/tutorHomepage' || route.isFirst);
            if (ModalRoute.of(context)?.settings.name != '/tutorHomepage') {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const TutorHomepage(),
                  settings: const RouteSettings(name: '/tutorHomepage')));
            }
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TutorHomepage(), settings: const RouteSettings(name: '/tutorHomepage')));
          }
        } else if (index == 1) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Library/Videos placeholder tapped')));
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? _primaryColor : _floatingNavIconColor, size: 26.0),
            const SizedBox(height: 4.0),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3.0, width: 20.0,
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1.0))),
      child: _tabBar,
    );
  }

  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => _tabBar != oldDelegate._tabBar;
}

// Stubs for CourseDetailsScreen and ReviewDetailsScreen
class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  const CourseDetailsScreen({Key? key, required this.course}) : super(key: key);
  @override State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}
class _CourseDetailsScreenState extends State<CourseDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _imageErrorBuilder = globalImageErrorBuilder;
  final List<Map<String, dynamic>> _courseModules = [{'title': 'Module 1', 'tags': 'Beginner', 'locked': false}];
  final List<Review> _courseReviews = [Review(name: 'Student Alpha', date: 'Jan 1, 2024', reviewText: 'Very good.', rating: 5, imagePath: 'assets/profile.png')];
  @override void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override void dispose() { _tabController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: Column(children: [
        Image.asset(widget.course.imagePath, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(widget.course.description, style: TextStyle(fontSize: 16))),
        TabBar(controller: _tabController, labelColor: primaryTeal, unselectedLabelColor: Colors.grey, indicatorColor: primaryTeal, tabs: const [Tab(text: "Materials"), Tab(text: "Reviews")]),
        Expanded(child: TabBarView(controller: _tabController, children: [
          ListView.builder(itemCount: _courseModules.length, itemBuilder: (context, index) => ListTile(title: Text(_courseModules[index]['title']!), subtitle: Text(_courseModules[index]['tags']!), trailing: _courseModules[index]['locked']! ? Icon(Icons.lock) : null)),
          ListView.builder(itemCount: _courseReviews.length, itemBuilder: (context, index) => ListTile(leading: Image.asset(_courseReviews[index].imagePath, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder), title: Text(_courseReviews[index].name), subtitle: Text(_courseReviews[index].reviewText), trailing: Text("${_courseReviews[index].rating} ★"))),
        ])),
      ]),
    );
  }
}

class ReviewDetailsScreen extends StatelessWidget {
  final Review review;
  const ReviewDetailsScreen({Key? key, required this.review}) : super(key: key);
  final _imageErrorBuilder = globalImageErrorBuilder;
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review by ${review.name}')),
      body: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Image.asset(review.imagePath, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder), SizedBox(width: 10), Text(review.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        SizedBox(height: 10), Text("Rating: ${review.rating} ★"), SizedBox(height: 10), Text(review.reviewText),
      ])),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus, PointerDeviceKind.mouse};
}