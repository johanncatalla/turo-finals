import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import '../../services/directus_service.dart';

// Reuse your existing class definitions
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

// Define App Colors
const Color primaryTeal = Color(0xFF3F8E9B);
const Color darkCharcoal = Color(0xFF303030);
const Color lightGreyBg = Color(0xFFF5F5F5);

// Placeholder widget for image
Widget globalImageErrorBuilder(context, error, stackTrace) {
  print('Error loading image: $error');
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

// Main TutorProfileScreen class
class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 2;

  // User data storage
  Map<String, dynamic>? userData;
  Map<String, dynamic>? tutorProfileData;
  List<dynamic>? subjectsData;
  bool isLoading = true;
  String? errorMessage;

  // DirectusService instance
  final DirectusService _directusService = DirectusService();

  // NavBar Items
  List<NavBarItem> get _navBarItems {
    return [
      NavBarItem(icon: Icons.home_outlined, label: 'Home'),
      NavBarItem(icon: Icons.video_library_outlined, label: 'Library'),
      NavBarItem(icon: Icons.person_outline, label: 'Profile'),
    ];
  }

  // Image error builder
  final _imageErrorBuilder = globalImageErrorBuilder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging ||
          _tabController.index != _tabController.previousIndex) {
        setState(() {});
      }
    });

    // Load user data when screen initializes
    _loadUserData();
  }

  // Method to load user data from DirectusService
  Future<void> _loadUserData() async {
    try {
      // First check if token needs refreshing
      bool isValid = await _directusService.refreshTokenIfNeeded();
      if (!isValid) {
        setState(() {
          isLoading = false;
          errorMessage = 'Session expired. Please login again.';
        });
        return;
      }

      // Get user data with all related fields
      final result = await _directusService.fetchTutorProfile();

      setState(() {
        isLoading = false;
        if (result['success']) {
          // Store the user data
          userData = result['data'];

          // Handle tutor_profile field based on the returned structure
          if (userData != null) {
            var tutorProfileField = userData!['tutor_profile'];

            // If tutor_profile is a Map, use it directly
            if (tutorProfileField[0] is Map<String, dynamic>) {
              tutorProfileData = tutorProfileField[0];

              // Handle subjects field
              if (tutorProfileData!.containsKey('subjects')) {
                subjectsData = tutorProfileData!['subjects'];
              }
            }
            // If tutor_profile is null or not a Map, create default empty values
            else {
              tutorProfileData = {};
              subjectsData = [];
            }
          }
        } else {
          errorMessage = result['message'];
        }
      });

      // Debug output to help diagnose data structure issues
      print('User data: ${userData?.runtimeType}');
      print('Tutor profile: ${tutorProfileData}');
      print('Subjects: ${subjectsData?.runtimeType}');

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load user data: ${e.toString()}';
      });
      print('Error in _loadUserData: $e');
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
    // Show loading indicator while fetching data
    if (isLoading) {
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

    // Show error message if any
    if (errorMessage != null) {
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
                onPressed: _loadUserData,
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
            onPressed: () {
              // Settings action
            },
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
            _buildCoursesList(context),
            _buildModulesList(context),
            _buildReviewsList(context),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(
        selectedIndex: _bottomNavIndex,
        items: _navBarItems,
        backgroundColor: darkCharcoal,
        selectedColor: primaryTeal,
        unselectedColor: Colors.white70,
        onItemSelected: (index) {
          setState(() {
            if (index < _navBarItems.length) {
              var selectedLabel = _navBarItems[index].label;
              int originalIndex = [
                NavBarItem(icon: Icons.home_outlined, label: 'Home'),
                NavBarItem(icon: Icons.video_library_outlined, label: 'Library'),
                NavBarItem(icon: Icons.person_outline, label: 'Profile'),
              ].indexWhere((item) => item.label == selectedLabel);

              _bottomNavIndex = originalIndex >= 0 ? originalIndex : index;
            } else {
              _bottomNavIndex = index;
            }
          });
        },
      ),
    );
  }

  // Profile header section with user data
  Widget _buildProfileHeader(BuildContext context) {
    // Get user's name from userData
    final firstName = userData?['first_name'] ?? 'User';
    final lastName = userData?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Get bio from tutor profile
    final bio = tutorProfileData?['bio'] ?? 'A dedicated tutor with a passion for teaching.';

    // Check if tutor is verified
    final isVerified = tutorProfileData?['verified'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            // Cover Photo
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.asset(
                'assets/cover.png',
                fit: BoxFit.cover,
                errorBuilder: _imageErrorBuilder,
              ),
            ),
            // Profile Picture
            Positioned(
              bottom: -30,
              left: 20,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: const AssetImage('assets/profile.png'),
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading profile image: $exception');
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
                // Handle Edit Profile action
              },
              child: const Text('Edit'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Profile Name and Details
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
                      const Icon(Icons.verified, color: primaryTeal, size: 20),
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

  // Tutor information section
  Widget _buildTutorInfoSection(BuildContext context) {
    // If no tutor profile data, don't show anything
    if (tutorProfileData == null) {
      return const SizedBox.shrink();
    }

    // Extract tutor information
    final education = tutorProfileData?['education_background'] ?? 'Not specified';
    final hourRate = tutorProfileData?['hour_rate']?.toString() ?? 'Not specified';

    // Get teaching levels with the specific format from Directus
    String teachLevels = 'Not specified';
    if (tutorProfileData?['teach_levels'] != null) {
      if (tutorProfileData!['teach_levels'] is List) {
        List<dynamic> levelsList = tutorProfileData!['teach_levels'];
        if (levelsList.isNotEmpty) {
          // Handle the specific format: [{TeachLevels_id: {name: College}}, {TeachLevels_id: {name: High School}}]
          List<String> levelNames = [];

          for (var levelItem in levelsList) {
            if (levelItem is Map<String, dynamic>) {
              // Extract the first key (which could be "TeachLevels_id" or similar)
              String? firstKey = levelItem.keys.isNotEmpty ? levelItem.keys.first : null;

              if (firstKey != null && levelItem[firstKey] is Map<String, dynamic>) {
                Map<String, dynamic> levelData = levelItem[firstKey];
                if (levelData.containsKey('name')) {
                  levelNames.add(levelData['name'].toString());
                }
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
          _buildInfoItem(Icons.attach_money_outlined, 'Hourly Rate', '₱$hourRate'),
          const SizedBox(height: 8),
          _buildInfoItem(Icons.groups_outlined, 'Teaching Levels', teachLevels),
        ],
      ),
    );
  }

  // Subjects section
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
              subjectsData!.length,
                  (index) {
                final subject = subjectsData![index];
                String subjectName = 'Subject';

                // Extract subject name based on your data structure
                if (subject is Map<String, dynamic>) {
                  subjectName = subject['name'] ?? 'Subject';
                } else if (subject is String) {
                  subjectName = subject;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: primaryTeal.withOpacity(0.3)),
                  ),
                  child: Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryTeal,
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

  // Helper for consistent info items
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryTeal),
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

  // Certifications section
  Widget _buildCertificationsSection(BuildContext context) {
    // Example data - ideally fetch from your Directus backend
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

  // Certificate card builder
  Widget _buildCertificationCard(String title, String description, String imagePath) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Color
            Container(
              color: primaryTeal,
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
            //Image and Description
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
                    // Description Text
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

  // Courses list builder
  Widget _buildCoursesList(BuildContext context) {
    // Example courses - ideally fetch from your backend
    final courses = [
      Course(
        title: 'Conversational English',
        details: '1hr/day • ${userData?['first_name'] ?? 'Mr.'} ${userData?['last_name'] ?? 'Tutor'}',
        description: 'A practical course designed to build confidence and fluency in everyday conversations. Through interactive exercises, real-life scenarios, and guided practice, learners will improve their speaking skills, pronunciation, and ability to express ideas naturally in English.',
        imagePath: 'assets/English.png',
        rate: tutorProfileData?['hour_rate'] != null ? '₱${tutorProfileData!['hour_rate']}/hr' : null,
      ),
      Course(
        title: 'Journalism Fundamentals',
        details: '1hr/day • ${userData?['first_name'] ?? 'Mr.'} ${userData?['last_name'] ?? 'Tutor'}',
        description: 'Learn the essentials of journalism including research, interviewing, writing, and ethical reporting. This course covers news writing, feature articles, and multimedia journalism techniques.',
        imagePath: 'assets/Journal.png',
        rate: tutorProfileData?['hour_rate'] != null ? '₱${tutorProfileData!['hour_rate']}/hr' : null,
      ),
    ];

    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No courses available yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(context, course);
      },
    );
  }

  // Course card builder
  Widget _buildCourseCard(BuildContext context, Course course) {
    final duration = course.duration;
    final tutor = course.tutor;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsScreen(course: course),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        color: lightGreyBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(
                  course.imagePath,
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: _imageErrorBuilder,
                ),
              ),
              const SizedBox(width: 12),
              // Course Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(duration, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(tutor, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.description,
                      style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.rate != null && course.rate!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        course.rate!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modules list builder
  Widget _buildModulesList(BuildContext context) {
    // Example modules
    final modules = [
      { 'title': 'Photosynthetic Process In Plants', 'tags': 'Science | Biology | High school', 'locked': true, },
      { 'title': 'Grammar Essentials for Beginners', 'tags': 'English | Grammar | Elementary', 'locked': true, },
    ];

    if (modules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No modules available yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleListItem(
          context,
          module['title'] as String,
          module['tags'] as String,
          module['locked'] as bool,
        );
      },
    );
  }

  // Module list item builder
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

  // Reviews list builder
  Widget _buildReviewsList(BuildContext context) {
    // Example reviews
    final reviews = [
      Review(
          name: 'John Leo Echevaria',
          date: 'September 10, 2023',
          reviewText: 'Excellent tutor! Adjusts his lesson to my level of understanding and provides a comfortable learning atmosphere in his class. 10/10 would recommend!',
          rating: 5,
          imagePath: 'assets/image4.png'
      ),
      Review(
          name: 'Maria Santos',
          date: 'October 5, 2023',
          reviewText: 'Very knowledgeable and patient. Explains complex topics in a simple way. Highly recommended!',
          rating: 4,
          imagePath: 'assets/image2.png'
      ),
    ];

    if (reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No reviews yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _buildReviewCard(context, review);
      },
    );
  }

  // Review card builder
  Widget _buildReviewCard(BuildContext context, Review review) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewDetailsScreen(review: review),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                review.imagePath,
                width: 70,
                height: 70,
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.date,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.reviewText,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Course Details Screen
class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  const CourseDetailsScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _imageErrorBuilder = globalImageErrorBuilder;

  // Example Module Data
  final List<Map<String, dynamic>> _courseModules = [
    { 'title': 'Module 1: Introduction to Conversational Flow', 'tags': 'Speaking | Listening | Beginner', 'locked': false, },
    { 'title': 'Module 2: Common Phrases & Idioms', 'tags': 'Vocabulary | Speaking | Intermediate', 'locked': true, },
    { 'title': 'Module 3: Role-playing Scenarios', 'tags': 'Practice | Speaking | Intermediate', 'locked': true, },
  ];

  // Example Review Data
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
              // Placeholder for Edit action
              print('Edit course tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit action placeholder'))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Course',
            onPressed: () {
              // Placeholder for Delete action
              print('Delete course tapped');
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
                          Navigator.of(context).pop(); // Close the popup dialog
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

  // The top section of the Course Details screen
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
        // Course Info Padding
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Rate Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
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
                  // Rate
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
                    widget.course.duration, // Use getter
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Full Course Description
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

  // TabBar for Materials and Reviews
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

  // Builds the content area for the tabs
  Widget _buildCourseTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Content for 'Materials' Tab
        _buildCourseMaterialsList(),
        // Content for 'Reviews' Tab
        _buildCourseReviewsList(),
      ],
    );
  }

  // Builds the list for the 'Materials' tab
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

  // Builds the list for the 'Reviews' tab within Course Details
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

  // Specific Review Card for Course Details
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

  // Reusable Module List Item Builder
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

// Review Details Screen
class ReviewDetailsScreen extends StatelessWidget {
  final Review review;

  const ReviewDetailsScreen({Key? key, required this.review}) : super(key: key);

  // Use the global error builder
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
            // Reviewer Info
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
                      // Display rating stars
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
            // Full Review Text Section
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

// NavBar class
class NavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavBarItem> items;
  final Color selectedColor;
  final Color unselectedColor;
  final Color backgroundColor;

  const NavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.selectedColor = primaryTeal,
    this.unselectedColor = Colors.white60,
    this.backgroundColor = darkCharcoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
          bottom: bottomPadding + 8.0,
          top: 8.0
      ),
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          items.length,
              (index) => _buildNavItem(context, index, items[index].icon, items[index].label),
        ),
      ),
    );
  }

  // NavItems
  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    bool isSelected = selectedIndex == index;
    int currentlyDisplayedIndex = -1;
    if (selectedIndex >= 0 && selectedIndex < 3) {
      String? targetLabel;
      if (selectedIndex == 0) targetLabel = 'Home';
      else if (selectedIndex == 1) targetLabel = 'Library';
      else if (selectedIndex == 2) targetLabel = 'Profile';
      if(targetLabel != null) {
        currentlyDisplayedIndex = items.indexWhere((item) => item.label == targetLabel);
      }
    }
    isSelected = (currentlyDisplayedIndex == index);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onItemSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 25,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Scrolling Effect
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
    // Rebuild if the TabBar instance changes
    return _tabBar != oldDelegate._tabBar;
  }
}

// Custom ScrollBehavior class for drag support
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.mouse,
  };
}