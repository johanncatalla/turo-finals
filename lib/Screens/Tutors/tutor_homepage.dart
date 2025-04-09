import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/role_select.dart';
import 'package:turo/Screens/Tutors/tutor_profileui_test.dart';
//import 'package:turo/Screens/Tutors/tutor_createcourse.dart'; // Import Create Course screen
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadUserData();
    _bottomNavIndex = 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        setState(() {
          _tutorName = authProvider.user!.fullName ?? "Tutor";
        });
      } else {
        print("User data not available in TutorHomepage");
        setState(() {
          _tutorName = "Tutor";
        });
      }
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorProfileScreen()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _bottomNavIndex = 0;
        });
      }
    });
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(/* ... dialog content ... */),
        ) ??
        false;

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
                    height: 260,
                  ), //Change back to 80 after putting calendar back
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
          // Make the name clickable by wrapping in GestureDetector
          GestureDetector(
            onTap: _navigateToProfile, // Still allow navigation from name
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
                    // Apply new primary color to name
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor, // UPDATED COLOR FOR NAME
                  ),
                ),
              ],
            ),
          ),
          // Notification Button - Styled like Figma
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              // Use the new primary color with opacity for background
              color: _primaryColor.withOpacity(
                0.15,
              ), // Adjusted opacity slightly
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: _primaryColor,
              ), // Icon uses new primary color
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
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _primaryColor, // Base color if image fails
        image: const DecorationImage(
          // Use the correct image path provided by the user
          image: AssetImage('assets/tutor-home.png'), // UPDATED IMAGE PATH
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Tab Bar (Dashboard, Courses, Modules, Videos, Reviews)
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
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildCoursesTab();
      case 2:
        return _buildModulesTab();
      case 3:
        return _buildVideosTab();
      case 4:
        return _buildReviewsTab();
      default:
        return Container();
    }
  }

  // To include images of dashboard PNGS (fake dashboard)
  Widget _buildDashboardTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Example showing how primary color might be used in charts
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

  Widget _buildCoursesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCourseCard(
            imageAsset: 'assets/English.png',
            title: "Conversational English",
            time: "1hr/day",
            instructor: "Mr. J Perez",
            description:
                "A practical course designed to build confidence and fluency in conversational...",
          ),
          const SizedBox(height: 16),

          _buildCourseCard(
            imageAsset: 'assets/Journal.png',
            title: "Journalism",
            time: "1hr/day",
            instructor: "Mr. J Perez",
            description:
                "A practical course designed to build confidence and fluency in journalistic storytelling. This course goes beyond j...",
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              /*
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCourseScreen(),
                ),
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
              'Create Course',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard({
    required String imageAsset,
    required String title,
    required String time,
    required String instructor,
    required String description,
  }) {
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
          // Left Side: Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.asset(
              imageAsset,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.school_outlined,
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 12), // Space between image and text
          // Right Side: Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, // Title font size
                    fontWeight: FontWeight.bold, // Bold title
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6), // Space below title
                // Metadata Row (Time & Instructor)
                Row(
                  children: [
                    // Time Icon and Text
                    Icon(
                      Icons.access_time_outlined, // Clock icon
                      size: 14,
                      color: _secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ), // Space between time and instructor
                    // Instructor Icon and Text
                    Icon(
                      Icons.person_outline, // Person icon
                      size: 14,
                      color: _secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      instructor,
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Space below metadata
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12, // Description font size
                    color: _secondaryTextColor.withOpacity(0.9),
                    height: 1.4, // Line height for readability
                  ),
                  maxLines: 2, // Limit description to 2 lines
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
            tags: "Science | Biology | Highschool", // Match tags format
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

  //Module Card Helper
  Widget _buildModuleCard({required String title, required String tags}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ), // Adjust padding
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _borderColor.withOpacity(0.3),
        ), // Match course card border
        boxShadow: [
          // Match course card shadow
          BoxShadow(
            color: _shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Push content and icon apart
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center items vertically
        children: [
          // Left Side: Text Content
          Expanded(
            // Allow text to take available space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, // Match title size from image
                    fontWeight:
                        FontWeight
                            .w600, // Slightly less bold than course title? Check image
                    color: Colors.black87,
                  ),
                  maxLines: 2, // Allow wrapping if title is long
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5), // Space between title and tags
                // Tags
                Text(
                  tags,
                  style: TextStyle(
                    fontSize: 12, // Smaller font for tags
                    color: _secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10), // Add space before the icon
          // Right Side: Lock Icon
          Icon(
            Icons.lock_outline_rounded, // Use a standard lock icon
            color: Colors.grey.shade600, // Match icon color in image
            size: 24, // Match icon size
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
          // Thumbnail unchanged
          Stack(/* ... */),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text details unchanged
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
                    // Use updated primary color for Boost button
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
          // Use updated primary color
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
        borderRadius: BorderRadius.circular(15.0), // Match rounding from image
        border: Border.all(
          color: _borderColor.withOpacity(0.3),
        ), // Consistent border
        boxShadow: [
          // Consistent shadow
          BoxShadow(
            color: _shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
        children: [
          // Left Side: Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0), // Rounded image corners
            child: Image.asset(
              imageAsset, // Use the passed asset path
              width: 80, // Adjust size to match screenshot (~80 seems right)
              height: 80,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    // Fallback
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
          const SizedBox(width: 12), // Space between image and text
          // Right Side: Text Details and Stars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reviewer Name
                Text(
                  reviewerName,
                  style: const TextStyle(
                    fontSize: 15, // Name font size
                    fontWeight: FontWeight.bold, // Bold name
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3), // Smaller space below name
                // Date
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11, // Smaller font for date
                    color: _secondaryTextColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8), // Space below date
                // Review Text
                Text(
                  reviewText,
                  style: TextStyle(
                    fontSize: 12, // Review text font size
                    color: Colors.black87.withOpacity(
                      0.85,
                    ), // Slightly muted black
                    height: 1.4, // Line height
                  ),
                  // Let text wrap naturally, adjust maxLines if needed later
                ),
                const SizedBox(height: 10), // Space before stars
                // Star Rating - Aligned to the end of the column
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded, // Use rounded stars
                      color: Colors.amber.shade600, // Standard star color
                      size: 18, // Adjust star size
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

  //Placeholder card
  Widget _buildPlaceholderCard({
    required double height,
    required String label,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(8), // Add padding
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
          // Use column if icon exists
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

  // Navbar
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

  // Helper for Floating Nav Items
  Widget _buildNavItem({required int index, required IconData icon}) {
    bool isSelected = _bottomNavIndex == index;
    return InkWell(
      onTap: () {
        // Update the visual state immediately
        setState(() {
          _bottomNavIndex = index;
        });

        // --- Navigation Logic ---
        if (index == 0) {
          print("Home Nav Tapped");
        } else if (index == 1) {
          print("Video/TutokFeed Nav Tapped - Navigation Commented Out");
          /*
          // UNCOMMENT WHEN TutokFeed page is created: (or remove)
          Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const TutokFeed()),
           ).then((_) {
               if (mounted) {
                 setState(() {
                   _bottomNavIndex = 0;
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
              // Indicator line
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
