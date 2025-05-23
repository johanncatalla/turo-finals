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

// ... (Keep your Course, Review, NavBarItem models, App Colors, globalImageErrorBuilder) ...
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

const Color primaryTeal = Color(0xFF3F8E9B);
const Color darkCharcoal = Color(0xFF303030); // Used for old NavBar, can be removed if not used elsewhere
const Color lightGreyBg = Color(0xFFF5F5F5);

Widget globalImageErrorBuilder(context, error, stackTrace) {
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

  // Colors for the new BottomNavBar from TutorHomepage
  final Color _floatingNavBackground = Colors.black87;
  final Color _floatingNavIconColor = Colors.grey.shade400;

  // NavBar Items for the new BottomNavBar (consistent with TutorHomepage)
  // The labels are not directly shown on TutorHomepage's nav bar but icons are key.
  // We'll use icons directly in _buildBottomNavBar.
  // This _navBarItems list might not be strictly needed if we directly use icons.
  // For now, let's keep it as it was used for determining labels previously.
  // List<NavBarItem> get _navBarItems {
  //   return [
  //     NavBarItem(icon: Icons.home_outlined, label: 'Home'),
  //     NavBarItem(icon: Icons.video_library_outlined, label: 'Library'),
  //     NavBarItem(icon: Icons.person_outline, label: 'Profile'),
  //   ];
  // }
  // We'll use these icons directly:
  final List<IconData> _bottomNavIcons = [
    Icons.home_filled, // As per TutorHomepage
    Icons.video_library, // As per TutorHomepage
    Icons.person_outline, // As per TutorHomepage
  ];


  final _imageErrorBuilder = globalImageErrorBuilder;

  @override
  void initState() {
    super.initState();
    _bottomNavIndex = 2; // Initialize to Profile tab selected
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

  // ... ( _loadInitialData, _refreshCourseProviderData methods remain the same as previous good version)
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
      final profileResult = await _directusService.fetchTutorProfileByUserId(userID);

      if (mounted) {
        if (profileResult['success']) {
          userData = profileResult['data'];
          if (userData != null) {
            var tutorProfileField = userData!['tutor_profile'];
            if (tutorProfileField != null && tutorProfileField is List && tutorProfileField.isNotEmpty) {
              if (tutorProfileField[0] is Map<String, dynamic>){
                tutorProfileData = tutorProfileField[0];
                if (tutorProfileData!.containsKey('subjects')) {
                  subjectsData = tutorProfileData!['subjects'];
                }
              } else {
                tutorProfileData = {};
                subjectsData = [];
              }
            } else if (tutorProfileField is Map<String, dynamic>) {
              tutorProfileData = tutorProfileField;
              if (tutorProfileData!.containsKey('subjects')) {
                subjectsData = tutorProfileData!['subjects'];
              }
            }
            else {
              tutorProfileData = {};
              subjectsData = [];
            }
          }
        } else {
          errorMessage = profileResult['message'] ?? "Failed to load profile details.";
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
    // ... (isLoading, errorMessage checks for main profile data remain the same)
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Profile'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            onPressed: () { /* Settings action */ },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        // ... (headerSliverBuilder remains the same)
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
      // MODIFICATION: Use the new bottom navigation bar
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ... (_buildCoursesTabContent, _buildProfileHeader, _buildTutorInfoSection, etc. remain the same)
  Widget _buildCoursesTabContent(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context);

    if (authProvider.user == null) {
      return const Center(child: Text("User not logged in."));
    }

    final String tutorName = authProvider.user!.fullName ?? "Tutor";
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
    final firstName = userData?['first_name'] ?? 'User';
    final lastName = userData?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final bio = tutorProfileData?['bio'] ?? 'A dedicated tutor with a passion for teaching.';
    final isVerified = tutorProfileData?['verified'] == true;
    final avatarId = userData?['avatar'] as String?;

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
              bottom: -30,
              left: 20,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (avatarId != null && avatarId.isNotEmpty)
                      ? NetworkImage(_directusService.getAssetUrl(avatarId)) as ImageProvider
                      : const AssetImage('assets/profile.png'),
                  onBackgroundImageError: (exception, stackTrace) {
                    // print('Error loading profile image: $exception');
                  },
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
            right: 20.0,
            bottom: 0,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Handle Edit Profile action
              },
              child: const Text('Edit'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(width: 6),
                    if (isVerified)
                      Icon(Icons.verified, color: _primaryColor, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
                ),
              ]
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTutorInfoSection(BuildContext context) {
    if (tutorProfileData == null) {
      return const SizedBox.shrink();
    }
    final education = tutorProfileData?['education_background'] ?? 'Not specified';
    final hourRateValue = tutorProfileData?['hour_rate'];
    final hourRate = hourRateValue != null ? '₱${hourRateValue.toString()}' : 'Not specified';

    String teachLevels = 'Not specified';
    if (tutorProfileData?['teach_levels'] != null) {
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
              color: darkCharcoal, // Re-using darkCharcoal constant
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
    final certifications = [
      {
        'title': 'English Proficiency for Customer Service Workers',
        'description': '${userData?['first_name'] ?? 'User'} just earned a TESDA certification! At Turo, we support our tutors in getting certified to ensure quality education for our students.',
        'imagePath': 'assets/certificate.png',
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


  // --- New Bottom Navigation Bar methods (copied and adapted from TutorHomepage) ---
  Widget _buildBottomNavBar() {
    return Container(
      color: Colors.transparent, // Ensures the floating effect if background is transparent
      padding: EdgeInsets.only(
        left: 80.0, // Adjust padding as needed for aesthetics
        right: 80.0,
        top: 10.0,
        bottom: MediaQuery.of(context).padding.bottom + 10.0, // Safe area padding
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
            _buildNavItem(index: 0, icon: _bottomNavIcons[0]), // Home
            _buildNavItem(index: 1, icon: _bottomNavIcons[1]), // Library/Videos
            _buildNavItem(index: 2, icon: _bottomNavIcons[2]), // Profile
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon}) {
    bool isSelected = _bottomNavIndex == index;
    return InkWell(
      onTap: () {
        if (_bottomNavIndex == index) return; // Do nothing if already selected

        if (mounted) {
          setState(() {
            _bottomNavIndex = index;
          });
        }

        // Handle navigation based on index
        if (index == 0) { // Home
          // Navigate back to TutorHomepage.
          // If TutorHomepage is always the screen before profile:
          if (Navigator.canPop(context)) {
            // Pop until TutorHomepage, or just pop if it's the immediate previous.
            // For robust navigation, consider named routes or ensuring TutorHomepage is on stack.
            // Navigator.popUntil(context, ModalRoute.withName('/tutorHomepage')); // If named
            Navigator.of(context).popUntil((route) => route.isFirst); // Go to the very first screen
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TutorHomepage())); // Or replace current stack
          } else {
            // Fallback if cannot pop (e.g. profile is the first screen)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TutorHomepage()), // Ensure TutorHomepage is imported
            );
          }
        } else if (index == 1) { // Library/Videos
          // TODO: Implement navigation to Library/Videos screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Library/Videos placeholder tapped')),
          );
        } else if (index == 2) { // Profile
          // Already on the profile screen, do nothing.
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
            AnimatedContainer( // Indicator line
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

// ... (Keep CourseDetailsScreen, ReviewDetailsScreen, _SliverAppBarDelegate, MyCustomScrollBehavior) ...
// Ensure CourseDetailsScreen and ReviewDetailsScreen are updated if their data models change
// or if they need to fetch data dynamically instead of using passed-in example data.

class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  const CourseDetailsScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _imageErrorBuilder = globalImageErrorBuilder;

  final List<Map<String, dynamic>> _courseModules = [
    { 'title': 'Module 1: Introduction to Conversational Flow', 'tags': 'Speaking | Listening | Beginner', 'locked': false, },
    { 'title': 'Module 2: Common Phrases & Idioms', 'tags': 'Vocabulary | Speaking | Intermediate', 'locked': true, },
    { 'title': 'Module 3: Role-playing Scenarios', 'tags': 'Practice | Speaking | Intermediate', 'locked': true, },
  ];

  final List<Review> _courseReviews = [
    Review(name: 'Student A', date: 'Oct 1, 2023', reviewText: 'Great introductory course!', rating: 5, imagePath: 'assets/image2.png'),
    Review(name: 'Student B', date: 'Sep 28, 2023', reviewText: 'Helped improve my confidence.', rating: 4, imagePath: 'assets/image4.png'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Course Details'),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            tooltip: 'Edit Course',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit action placeholder'))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Course',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: const Text("Are you sure you want to delete this course?"),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delete action placeholder'))
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildCourseHeader(),
          _buildCourseTabBar(),
          Expanded(
            child: _buildCourseTabBarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          widget.course.imagePath,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: _imageErrorBuilder,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.course.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (widget.course.rate != null && widget.course.rate!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.course.rate!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_outlined, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    widget.course.duration,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.course.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseTabBar() {
    return Container(
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)),
          color: Colors.white
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: primaryTeal,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryTeal,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3.0,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Materials'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildCourseTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCourseMaterialsList(),
        _buildCourseReviewsList(),
      ],
    );
  }

  Widget _buildCourseMaterialsList() {
    if (_courseModules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No materials available for this course yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _courseModules.length,
      itemBuilder: (context, index) {
        final module = _courseModules[index];
        return _buildModuleListItem(
          context,
          module['title'] as String,
          module['tags'] as String,
          module['locked'] as bool,
        );
      },
    );
  }

  Widget _buildCourseReviewsList() {
    if (_courseReviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No reviews available for this course yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _courseReviews.length,
      itemBuilder: (context, index) {
        final review = _courseReviews[index];
        return _buildReviewCardForCourseDetails(context, review);
      },
    );
  }

  Widget _buildReviewCardForCourseDetails(BuildContext context, Review review) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              review.imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: _imageErrorBuilder,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  review.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  review.reviewText,
                  style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleListItem(BuildContext context, String title, String tags, bool isLocked) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  tags,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Icon(Icons.lock_outline, color: Colors.grey[600], size: 24),
            ),
        ],
      ),
    );
  }
}


class ReviewDetailsScreen extends StatelessWidget {
  final Review review;

  const ReviewDetailsScreen({Key? key, required this.review}) : super(key: key);
  final _imageErrorBuilder = globalImageErrorBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Review Details'),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    review.imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: _imageErrorBuilder,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        review.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.date,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 22,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Review:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              review.reviewText,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey[850],
              ),
              softWrap: true,
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
          color: Theme.of(context).scaffoldBackgroundColor,
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.mouse,
  };
}