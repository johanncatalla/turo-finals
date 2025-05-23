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
import '../../screens/Tutors/tutor_homepage.dart'; // Assuming this is the path

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

// Global Image Error Builder
Widget globalImageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
  // print("Error loading image: $error"); // You can uncomment for debugging
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
  int _bottomNavIndex = 2; // Profile is the 3rd item (index 2)

  Map<String, dynamic>? userData;
  Map<String, dynamic>? tutorProfileData;
  List<dynamic>? subjectsData;
  bool isLoading = true;
  String? errorMessage;

  final DirectusService _directusService = DirectusService();

  // Styling colors for tabs and new NavBar
  final Color _primaryColor = primaryTeal;
  final Color _secondaryTextColor = Colors.grey.shade600;
  final Color _cardBackgroundColor = Colors.white;
  final Color _shadowColor = Colors.grey.withOpacity(0.1);
  final Color _borderColor = Colors.grey.shade300;

  // Colors for the new BottomNavBar
  final Color _floatingNavBackground = Colors.black87;
  final Color _floatingNavIconColor = Colors.grey.shade400;

  final List<IconData> _bottomNavIcons = [
    Icons.home_filled,
    Icons.video_library,
    Icons.person_outline,
  ];

  // Use the global error builder
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
      // Fetch full user profile which should include 'avatar'
      // Assuming AuthProvider might have a method like getFullUserProfile or
      // _directusService.fetchUserById(userID) if directus_service handles fetching generic user data
      final userProfileResponse = await authProvider.getFullUserProfile(); // ADAPT THIS LINE

      if (mounted) {
        if (userProfileResponse['success']) {
          userData = userProfileResponse['data']; // This should contain 'avatar' and other user fields

          // Now fetch the tutor-specific profile part
          // This might be redundant if getFullUserProfile already includes expanded tutor_profile
          final tutorSpecificProfileResult = await _directusService.fetchTutorProfileByUserId(userID);
          if (tutorSpecificProfileResult['success']) {
            final tutorData = tutorSpecificProfileResult['data'];
            // The 'tutorData' might be the direct user object with 'tutor_profile' nested,
            // or it might be the 'tutor_profile' item itself. Adjust based on your Directus setup.
            // For now, let's assume 'tutorData' is the user object and we need to extract 'tutor_profile'.

            // If userData from getFullUserProfile is more comprehensive, prefer it for 'avatar'
            // and merge/extract tutor_profile details.
            // For simplicity, let's assume fetchTutorProfileByUserId gives us the user object with tutor_profile
            // and also includes the 'avatar' at the root level of the user object.
            // If not, ensure `userData` is populated from a source that includes 'avatar'.

            // Let's assume `userProfileResponse['data']` (now `userData`) contains the direct user fields
            // like first_name, last_name, avatar.
            // And `tutorSpecificProfileResult['data']` might be the user object again, or just the tutor_profile.
            // We need to be careful not to overwrite `userData` if `tutorSpecificProfileResult` is less complete for root fields.

            // Let's refine:
            // 1. Get full user data (including avatar)
            // 2. Extract/get tutor specific profile data

            // Assuming userData is already populated from getFullUserProfile
            if (userData != null) {
              var tutorProfileField = userData!['tutor_profile']; // Assuming tutor_profile is a field in the main user data
              if (tutorProfileField != null && tutorProfileField is List && tutorProfileField.isNotEmpty) {
                if (tutorProfileField[0] is Map<String, dynamic>){
                  tutorProfileData = tutorProfileField[0];
                  if (tutorProfileData!.containsKey('subjects')) {
                    subjectsData = tutorProfileData!['subjects'];
                  }
                } else {
                  tutorProfileData = {}; // Handle case where it's not a map
                  subjectsData = [];
                }
              } else if (tutorProfileField is Map<String, dynamic>) { // If it's a direct object (to-one relation)
                tutorProfileData = tutorProfileField;
                if (tutorProfileData!.containsKey('subjects')) {
                  subjectsData = tutorProfileData!['subjects'];
                }
              }
              else { // No tutor profile data or unexpected format
                tutorProfileData = {};
                subjectsData = [];
              }
            } else { // userData itself is null after getFullUserProfile
              errorMessage = userProfileResponse['message'] ?? "Failed to load user profile.";
            }

          } else { // Failed to get tutor-specific details
            // We might still have basic user data from getFullUserProfile
            if (userData == null) { // If even basic user data failed
              errorMessage = tutorSpecificProfileResult['message'] ?? "Failed to load tutor profile details.";
            }
          }
        } else { // getFullUserProfile failed
          errorMessage = userProfileResponse['message'] ?? "Failed to load primary user profile.";
        }
      }


      if (courseProvider.courses.isEmpty && !courseProvider.isLoading) {
        await courseProvider.initialize();
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load data: ${e.toString()}';
        });
        // print("Error in _loadInitialData: $e");
      }
    }
  }


  Future<void> _refreshCourseProviderData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.fetchCourses();
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
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: primaryTeal),
        ),
      );
    }

    if (errorMessage != null && userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: false,
        ),
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
    // If userData is null but not loading and no error (should not happen with current logic, but safe check)
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: false,
        ),
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
        backgroundColor: Colors.white, // Added for consistency
        elevation: 0, // Added for consistency
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24, color: darkCharcoal), // Added color
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: darkCharcoal, fontSize: 18, fontWeight: FontWeight.w500), // Style like student profile
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24, color: primaryTeal), // Example color
            onPressed: () { /* TODO: Settings action */ },
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
            SliverToBoxAdapter(child: _buildCertificationsSection(context)), // This is static example data
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
    // userData is checked for null in the main build method
    final firstName = userData!['first_name'] ?? 'User';
    final lastName = userData!['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Bio and verified status from tutorProfileData, which might be null or empty
    final bio = tutorProfileData?['bio'] ?? 'A dedicated tutor with a passion for teaching.';
    final isVerified = tutorProfileData?['verified'] == true;

    // Get avatarId from userData (root user object)
    final String? avatarId = userData!['avatar'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            // Cover Image (Static)
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.asset(
                'assets/cover.png', // Ensure this asset exists
                fit: BoxFit.cover,
                errorBuilder: _imageErrorBuilder,
              ),
            ),
            // Profile Image (Avatar)
            Positioned(
              bottom: -35, // Adjusted to match student profile's visual
              left: 20,
              child: CircleAvatar(
                radius: 47, // Outer radius for border (student profile style)
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 45, // Inner radius for image (student profile style)
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (avatarId != null && avatarId.isNotEmpty)
                      ? NetworkImage(_directusService.getAssetUrl(avatarId))
                  as ImageProvider
                      : const AssetImage('assets/profile.png'), // Your fallback asset
                  onBackgroundImageError: (exception, stackTrace) {
                    // print('Error loading profile image in TutorProfile: $avatarId, $exception');
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 55), // Spacing to clear the positioned avatar (student profile style)
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
                            color: darkCharcoal, // Consistent with student profile
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isVerified) // Verified icon from tutorProfileData
                          Icon(Icons.verified, color: _primaryColor, size: 20),
                        // If you want the orange verified icon like student:
                        // Icon(Icons.verified, color: primaryTeal, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio, // Bio from tutorProfileData
                      style: const TextStyle(color: Colors.grey /*greyText from student*/, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to an EditTutorProfileScreen
                  // This screen would need its own state management for editing fields,
                  // picking images, and saving, similar to StudentProfileScreen's _isEditing logic.
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Profile (Tutor) - Not Implemented Yet'))
                  );
                },
                style: OutlinedButton.styleFrom( // Style like student profile
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
        const Divider(color: Color(0xFFEEEEEE), height: 1), // Consistent with student profile
      ],
    );
  }


  Widget _buildTutorInfoSection(BuildContext context) {
    // tutorProfileData can be null or empty
    final education = tutorProfileData?['education_background'] ?? 'Not specified';
    final hourRateValue = tutorProfileData?['hour_rate'];
    final hourRate = hourRateValue != null ? '₱${hourRateValue.toString()}' : 'Not specified';

    String teachLevels = 'Not specified';
    // Ensure tutorProfileData and 'teach_levels' are not null before accessing
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkCharcoal,
            ),
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
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subjects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkCharcoal,
            ),
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
              } else if (subjectItem is Map<String, dynamic> && subjectItem.containsKey('name')) { // Fallback if structure is simpler
                subjectName = subjectItem['name'] ?? 'Subject';
              } else if (subjectItem is String) { // Fallback for plain string list
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
                  style: TextStyle(
                    fontSize: 12,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
            ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: darkCharcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection(BuildContext context) {
    // This is example data. In a real app, fetch this from tutorProfileData or similar
    final certifications = [
      {
        'title': 'English Proficiency for Customer Service Workers',
        'description': '${userData!['first_name'] ?? 'User'} just earned a TESDA certification! At Turo, we support our tutors in getting certified to ensure quality education for our students.',
        'imagePath': 'assets/certificate.png', // Ensure this asset exists
      },
    ];

    if (certifications.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 125,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: certifications.length,
        itemBuilder: (context, index) {
          final cert = certifications[index];
          return _buildCertificationCard(
            cert['title']!,
            cert['description']!,
            cert['imagePath']!,
          );
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
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
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
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: _imageErrorBuilder,
                      ),
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

        if (mounted) {
          setState(() {
            _bottomNavIndex = index;
          });
        }

        if (index == 0) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).popUntil((route) {
              // Pop until we find TutorHomepage or we are at the first route
              return route.settings.name == '/tutorHomepage' || route.isFirst;
            });
            // If TutorHomepage was not found and we popped to first, or if it was found and popped to it,
            // ensure TutorHomepage is the current route.
            if (ModalRoute.of(context)?.settings.name != '/tutorHomepage') {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const TutorHomepage(),
                  settings: const RouteSettings(name: '/tutorHomepage') // Good to set name
              ));
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TutorHomepage(), settings: const RouteSettings(name: '/tutorHomepage')),
            );
          }
        } else if (index == 1) {
          // TODO: Navigate to Library/Videos screen
          // Example: Navigator.pushNamed(context, '/library');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Library/Videos placeholder tapped')),
          );
        }
        // Index 2 is profile, already on it.
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // Use theme background
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1.0))
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar;
  }
}

// MyCustomScrollBehavior, CourseDetailsScreen, ReviewDetailsScreen - KEEP AS IS (they were not part of the direct request for avatar/cover)
// Ensure they are present in your file if needed.
// For brevity, I'm omitting them here, but you should have them from your original code.


// --- Stubs for CourseDetailsScreen and ReviewDetailsScreen if you need them temporarily ---
// --- Remove these and use your actual implementations ---

class CourseDetailsScreen extends StatefulWidget {
  final Course course; // Assuming Course model is defined
  const CourseDetailsScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _imageErrorBuilder = globalImageErrorBuilder; // Use your global error builder

  // Example data (replace with actual data handling)
  final List<Map<String, dynamic>> _courseModules = [
    { 'title': 'Module 1: Introduction', 'tags': 'Beginner', 'locked': false, },
    { 'title': 'Module 2: Advanced Topics', 'tags': 'Intermediate', 'locked': true, },
  ];
  final List<Review> _courseReviews = [ // Assuming Review model is defined
    Review(name: 'Student Alpha', date: 'Jan 1, 2024', reviewText: 'Very good.', rating: 5, imagePath: 'assets/profile.png'),
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Example: 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: Column(
        children: [
          // Simplified header
          Image.asset(widget.course.imagePath, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.course.description, style: TextStyle(fontSize: 16)),
          ),
          TabBar(
            controller: _tabController,
            labelColor: primaryTeal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryTeal,
            tabs: const [
              Tab(text: "Materials"),
              Tab(text: "Reviews"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Materials Tab
                ListView.builder(
                  itemCount: _courseModules.length,
                  itemBuilder: (context, index) {
                    final module = _courseModules[index];
                    return ListTile(
                      title: Text(module['title']!),
                      subtitle: Text(module['tags']!),
                      trailing: module['locked']! ? Icon(Icons.lock) : null,
                    );
                  },
                ),
                // Reviews Tab
                ListView.builder(
                  itemCount: _courseReviews.length,
                  itemBuilder: (context, index) {
                    final review = _courseReviews[index];
                    return ListTile(
                      leading: Image.asset(review.imagePath, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder),
                      title: Text(review.name),
                      subtitle: Text(review.reviewText),
                      trailing: Text("${review.rating} ★"),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewDetailsScreen extends StatelessWidget {
  final Review review; // Assuming Review model is defined
  const ReviewDetailsScreen({Key? key, required this.review}) : super(key: key);
  final _imageErrorBuilder = globalImageErrorBuilder;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review by ${review.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Image.asset(review.imagePath, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder),
              SizedBox(width: 10),
              Text(review.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            SizedBox(height: 10),
            Text("Rating: ${review.rating} ★"),
            SizedBox(height: 10),
            Text(review.reviewText),
          ],
        ),
      ),
    );
  }
}


class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.mouse,
  };
}