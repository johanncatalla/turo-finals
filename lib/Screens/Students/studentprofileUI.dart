import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:fl_chart/fl_chart.dart';
import 'package:turo/Screens/Students/student_view_tutor_profile.dart';
import 'package:turo/Screens/Students/student_CourseSectionUI.dart' show Lecturer;
import '../../Widgets/navbar.dart';


// --- Models (Consider moving to separate files) ---
class Course {
  final String title;
  final String details;
  final String description;
  final String imagePath;
  late final String duration;
  late final String tutor;

  Course({
    required this.title,
    required this.details,
    required this.description,
    required this.imagePath,
  }) {
    var parts = details.split('•');
    duration = parts.isNotEmpty ? parts[0].trim() : '';
    tutor = parts.length > 1 ? parts[1].trim() : '';
  }
}

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: const Center(child: Text('Details about the selected course would appear here.')),
    );
  }
}

class LearnerBadge {
  final String imagePath;
  LearnerBadge({required this.imagePath});
}

class ProgressReport {
  final String tutorName;
  final String tutorImageUrl;
  final bool tutorVerified;
  final List<String> subjects;
  final double overallRating;
  final String comment;
  final int progressPercent;
  final List<double> weeklyProgress;

  ProgressReport({
    required this.tutorName,
    required this.tutorImageUrl,
    this.tutorVerified = true,
    required this.subjects,
    required this.overallRating,
    required this.comment,
    required this.progressPercent,
    required this.weeklyProgress,
  }) : assert(weeklyProgress.length <= 7, 'Weekly progress should have 7 or fewer values (Mon-Sun)');
}

// --- Constants ---
const Color primaryOrange = Color(0xFFF9A825);
const Color primaryTeal = Color(0xFF3F8E9B);
const Color darkCharcoal = Color(0xFF303030);
const Color darkText = Color(0xFF303030);
const Color greyText = Color(0xFF616161);
const Color logoutRed = Color(0xFFE57373);
const Color chartBarColor = Color(0xFFF9A825);
const Color chartBarBackground = Color(0x4DF9A825);

// --- Scroll Behavior ---
class _MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch, PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus, PointerDeviceKind.mouse,
      };
}

// --- Main Widget ---
class StudentProfileMainScreen extends StatefulWidget {
  const StudentProfileMainScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileMainScreen> createState() => _StudentProfileMainScreenState();
}

// --- State Class Definition ---
class _StudentProfileMainScreenState extends State<StudentProfileMainScreen> {
  final int _bottomNavIndex = 3; // Profile is index 3

  // --- Error Builder ---
  Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    print("Error loading image: $error");
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon( Icons.broken_image_outlined, color: Colors.grey[400], size: 30),
    );
  }

  // --- Placeholder Data (Ensure Assets Exist!) ---
  final String studentName = "Juan Dela Cruz";
  final String studentBio = "Motivated high school student eager to enhance my English skills. While I have a strong interest in literature and writing, I recognize the value of having a dedicated tutor to guide me.";
  final String studentProfileImageUrl = "assets/student1.png"; // << ENSURE EXISTS
  final String studentCoverImageUrl = "assets/cover.png";  // << ENSURE EXISTS
  final bool isStudentVerified = true;

  final List<LearnerBadge> badges = [
    LearnerBadge(imagePath: 'assets/b1.png'), 
    LearnerBadge(imagePath: 'assets/b2.png'), 
    LearnerBadge(imagePath: 'assets/b3.png'),
    LearnerBadge(imagePath: 'assets/b4.png'), 
    LearnerBadge(imagePath: 'assets/b5.png'), 
  ];

  final List<Course> myCourses = [
    Course( title: "Intro to Python Programming", details: "1hr/day • Mr. J. Seb Catalla", description: "Engaging beginner-friendly course covering Python basics, data types, control flow, and functions.", imagePath: "assets/image1.png", ), 
    Course( title: "Foundational Algebra Concepts", details: "1hr/day • Ms. Nicole Oriola", description: "A foundational course exploring core algebraic principles, equations, inequalities, and graphing.", imagePath: "assets/image4.png", ), 
    Course( title: "Creative Writing Fundamentals", details: "1hr/day • Mr. J. Seb Catalla", description: "Learn the basics of crafting compelling narratives, developing characters, and structuring stories.", imagePath: "assets/English.png", ), 
  ];

   final List<ProgressReport> progressReports = [
     ProgressReport(
        tutorName: "Joshua Perez", tutorImageUrl: "assets/Joshua.png", tutorVerified: true, 
        subjects: ["English", "Filipino", "Literature"], overallRating: 4.8,
        comment: "John Leo is an exemplary student. They consistently show dedication to learning, active participation in class, and a strong work ethic. Their positive attitude sets a great example.",
        progressPercent: 85,
        weeklyProgress: [0.2, 0.25, 0.4, 0.7, 0.6, 0.85, 0.95],
     ),
     ProgressReport(
        tutorName: "Maria Santos", tutorImageUrl: "assets/student1.png", tutorVerified: false, 
        subjects: ["Math", "Science"], overallRating: 4.5,
        comment: "Shows good understanding of concepts but needs to improve consistency in submitting assignments on time. Overall progressing well.",
        progressPercent: 70,
        weeklyProgress: [0.1, 0.3, 0.5, 0.6, 0.7, 0.7, 0.65],
     ),
      ProgressReport(
        tutorName: "Andres Cruz", tutorImageUrl: "assets/student2.png", tutorVerified: true, 
        subjects: ["History"], overallRating: 5.0,
        comment: "Excellent participation and insightful contributions to discussions. Demonstrates a strong grasp of historical events and themes.",
        progressPercent: 95,
        weeklyProgress: [0.5, 0.7, 0.8, 0.9, 0.95, 0.95, 0.9],
     ),
     ProgressReport(
        tutorName: "Sofia Reyes", tutorImageUrl: "assets/Joshua.png", tutorVerified: true, 
        subjects: ["Physics"], overallRating: 4.7,
        comment: "Actively engages with complex physics problems and shows strong analytical skills. Keep up the great work!",
        progressPercent: 90,
        weeklyProgress: [0.3, 0.5, 0.6, 0.75, 0.85, 0.9, 0.88],
     ),
  ];
  // --- End Placeholder Data ---


  @override
  Widget build(BuildContext context) {
    final List<NavBarItem> bottomNavItems = [
      NavBarItem(icon: Icons.home_outlined, label: 'Home'),
      NavBarItem(icon: Icons.search_outlined, label: 'Search'),
      NavBarItem(icon: Icons.calendar_today_outlined, label: 'Schedule'),
      NavBarItem(icon: Icons.person_outline, label: 'Profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: Navigator.canPop(context) ? IconButton( icon: const Icon(Icons.arrow_back, color: darkText), onPressed: () => Navigator.pop(context) ) : null,
        title: const Text('Profile'),
        titleTextStyle: const TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w500),
        centerTitle: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings_outlined, color: darkText, size: 24),
              tooltip: 'Settings',
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        child: _buildSettingsDrawerContent(context),
      ),
      bottomNavigationBar: NavBar(
        items: bottomNavItems,
        selectedIndex: _bottomNavIndex,
        onItemSelected: (index) {
          if (index == _bottomNavIndex) {
            print("Already on Profile Screen.");
            return;
          }

          switch (index) {
            case 0: // Home
              print("Navigate to Home from Profile");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to ${bottomNavItems[index].label}... (Not Implemented)'), duration: const Duration(seconds: 1)));
              break; // Important: Add break!

            case 1: 
              print("Navigate to specific Tutor Profile from Student Profile");
              final exampleTutor = Lecturer(
                  name: "Joshua Garcia",
                  description: "A dedicated college student with a passion for language and education. Currently pursuing a degree in Psychology...",
                  imageUrl: "assets/profile.png", 
                  isVerified: true);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentViewTutorProfileScreen(lecturer: exampleTutor),
                ),
              );
              break; // Important: Add break!

            case 2: // Schedule
              print("Navigate to Schedule from Profile");
              // TODO: Implement navigation to Schedule Screen
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to ${bottomNavItems[index].label}... (Not Implemented)'), duration: const Duration(seconds: 1)));
              break; // Important: Add break!

          }
        },
        selectedColor: primaryOrange,
        unselectedColor: Colors.white60,
        backgroundColor: darkCharcoal,
      ),
      body: ScrollConfiguration(
        behavior: _MyCustomScrollBehavior(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 20),
              _buildLearnerBadgesSection(context),
              const SizedBox(height: 24),
              _buildMyCoursesSection(context),
              const SizedBox(height: 24),
              _buildProgressReportsSection(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Build Methods for UI Sections ---

  Widget _buildProfileHeader(BuildContext context) {
    return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack( clipBehavior: Clip.none, alignment: Alignment.bottomLeft, children: [
            AspectRatio( aspectRatio: 16 / 7,
                child: Image.asset( studentCoverImageUrl, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder, ),
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
                  backgroundImage: AssetImage(studentProfileImageUrl),
                  onBackgroundImageError: (exception, stackTrace) {
                     print('Error loading profile image: $exception');
                   },
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
                    Row( children: [
                        Text( studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText) ),
                        const SizedBox(width: 6),
                        if (isStudentVerified) const Icon(Icons.verified, color: primaryOrange, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text( studentBio, style: const TextStyle(color: greyText, fontSize: 14, height: 1.4) ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                    print("Edit profile tapped");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile (Not Implemented)'), duration: Duration(seconds: 1)));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryOrange,
                  side: const BorderSide(color: primaryOrange, width: 1.5),
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

  Widget _buildLearnerBadgesSection(BuildContext context) {
    const int maxBadgesToShow = 5;
    final List<LearnerBadge> badgesToShow = badges.take(maxBadgesToShow).toList();
    final bool showSeeAll = badges.length > maxBadgesToShow;
    final int hiddenBadgeCount = badges.length - maxBadgesToShow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow( color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))
        ],
        border: Border.all(color: const Color(0xFFEEEEEE))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
                color: primaryOrange,
                 borderRadius: BorderRadius.only(topLeft: Radius.circular(12.0), topRight: Radius.circular(12.0))
            ),
            child: const Center(
              child: Text( 'Learner Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ...badgesToShow.map((badge) => _buildBadgeItem(context, badge)).toList(),
                if (showSeeAll) _buildSeeAllBadge(context, hiddenBadgeCount),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBadgeItem(BuildContext context, LearnerBadge badge) {
    const double badgeSize = 45.0;
    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: Image.asset(
        badge.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading badge image: ${badge.imagePath}, $error");
          return Container(
            width: badgeSize, height: badgeSize,
            decoration: BoxDecoration( color: Colors.grey[200], borderRadius: BorderRadius.circular(badgeSize / 2) ),
            child: Icon(Icons.emoji_events_outlined, color: Colors.grey[400], size: 25),
          );
        },
      ),
    );
  }

  Widget _buildSeeAllBadge(BuildContext context, int hiddenCount) {
    const double placeholderSize = 45.0;
    return InkWell(
      onTap: (){
        print("See All Badges tapped ($hiddenCount more)");
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('See All Badges... (Not Implemented)'), duration: Duration(seconds: 1)) );
        },
      customBorder: const CircleBorder(),
      child: Container(
        width: placeholderSize, height: placeholderSize,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!)
        ),
        child: Center(
          child: Text(
            "+$hiddenCount",
            textAlign: TextAlign.center,
            style: TextStyle( fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold, ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyCoursesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text( 'My Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 12),
          if (myCourses.isEmpty)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 20.0),
               child: Center(child: Text('No courses enrolled yet.', style: TextStyle(color: greyText))),
             )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myCourses.length,
              itemBuilder: (context, index) {
                return _buildStudentCourseCard(context, myCourses[index]);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCourseCard(BuildContext context, Course course) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.grey.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          print("Tapped on course: ${course.title}");
          Navigator.push(
            context,
            MaterialPageRoute( builder: (context) => const CourseDetailsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset( course.imagePath, width: 85, height: 85, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
                    const SizedBox(height: 4),
                    Text( course.description, style: const TextStyle(fontSize: 13, color: greyText, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis, ),
                    const SizedBox(height: 8),
                    Row( children: [
                        const Icon(Icons.access_time_outlined, size: 16, color: greyText), const SizedBox(width: 4), Text(course.duration, style: const TextStyle(fontSize: 12, color: greyText)),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline, size: 16, color: greyText), const SizedBox(width: 4), Text(course.tutor, style: const TextStyle(fontSize: 12, color: greyText)),
                      ]
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProgressReportsSection(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
            child: Text( 'Learning Progress Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText) ),
          ),
          if (progressReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Center(child: Text('No progress reports available yet.', style: TextStyle(color: greyText))),
            )
          else
            SizedBox(
              height: 380,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: progressReports.length,
                itemBuilder: (context, index) {
                  return _buildProgressReportCard(context, progressReports[index]);
                },
                separatorBuilder: (context, index) => const SizedBox(width: 12),
              ),
            ),
        ]
    );
  }


  Widget _buildProgressReportCard(BuildContext context, ProgressReport report) {
    const double barWidth = 16;
    final BorderRadius barBorderRadius = const BorderRadius.vertical(top: Radius.circular(4));

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Card(
        clipBehavior: Clip.antiAlias, color: Colors.white,
        elevation: 1.5, shadowColor: Colors.grey.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(report.tutorImageUrl),
                      backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 10),
                  Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row( children: [
                          Flexible( child: Text( report.tutorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkText), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          if (report.tutorVerified) const Icon(Icons.verified, color: primaryTeal, size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                          spacing: 4.0, runSpacing: 4.0,
                          children: [
                              for (var subject in report.subjects.take(2))
                                Chip(
                                  label: Text(subject),
                                  labelStyle: TextStyle(fontSize: 9, color: primaryTeal.withOpacity(0.9)),
                                  backgroundColor: primaryTeal.withOpacity(0.08),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: 0.0, vertical: -4),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                  side: BorderSide.none,
                                ),
                              if (report.subjects.length > 2)
                                Chip(
                                  label: Text('+${report.subjects.length - 2} more'),
                                  labelStyle: const TextStyle(fontSize: 9, color: greyText),
                                  backgroundColor: Colors.grey.withOpacity(0.1),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: 0.0, vertical: -4),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                  side: BorderSide.none,
                                ),
                            ],
                         ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column( crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      Row( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                          ...List.generate(5, (i) => Icon(
                              i < report.overallRating.floor() ? Icons.star_rounded
                              : (i < report.overallRating ? Icons.star_half_rounded : Icons.star_border_rounded),
                              color: primaryOrange, size: 16 )),
                          const SizedBox(width: 4),
                          Text( report.overallRating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: greyText, fontWeight: FontWeight.w600) ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFEEEEEE)),
              const SizedBox(height: 10),

              Text( report.comment, style: const TextStyle(fontSize: 13, color: greyText, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis, ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.only(top: 10.0, left: 5, right: 10, bottom: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
                  boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2) ) ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Weekly Class Progress", style: TextStyle(fontSize: 11, color: greyText.withOpacity(0.8))),
                          const SizedBox(height: 1),
                          Text(
                            report.progressPercent >= 80 ? "Excellent!" : (report.progressPercent >= 60 ? "Good Progress" : "Needs Improvement"),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText)
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 130,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 1.0,
                          minY: 0,
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 30, getTitlesWidget: (double value, TitleMeta meta) {
                                String text = '';
                                switch (value.toInt()) {
                                  case 0: text = 'M'; break; case 1: text = 'T'; break; case 2: text = 'W'; break; case 3: text = 'Th'; break;
                                  case 4: text = 'F'; break; case 5: text = 'Sa'; break; case 6: text = 'Su'; break;
                                  default: text = '';
                                }
                                return SideTitleWidget( axisSide: meta.axisSide, space: 4, child: Text(text, style: const TextStyle(color: greyText, fontWeight: FontWeight.w500, fontSize: 10)), );
                              }, ),
                            ),
                            leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 35,
                                interval: 0.5,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  String text;
                                  if (value == 0) text = '0%';
                                  else if (value == 0.5) text = '50%';
                                  else if (value == 1) text = '100%';
                                  else return Container();
                                  return SideTitleWidget( axisSide: meta.axisSide, space: 4, child: Text(text, style: const TextStyle(color: greyText, fontWeight: FontWeight.w500, fontSize: 10)), );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey[300]!, strokeWidth: 1, dashArray: [3, 3],
                            ),
                            checkToShowHorizontalLine: (value) => value == 0.5 || value == 1.0,
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                                left: BorderSide(color: Colors.grey[300]!, width: 1),
                                top: BorderSide.none,
                                right: BorderSide.none,
                            )
                          ),
                          barGroups: List.generate(
                            report.weeklyProgress.length.clamp(0, 7),
                            (index) {
                               final double barY = report.weeklyProgress[index].clamp(0.0, 1.0);
                               return BarChartGroupData(
                                   x: index,
                                   barRods: [
                                     BarChartRodData(
                                       toY: barY,
                                       color: chartBarColor,
                                       width: barWidth,
                                       borderRadius: barBorderRadius,
                                       backDrawRodData: BackgroundBarChartRodData(
                                         show: true,
                                         toY: 1.0,
                                         color: chartBarBackground,
                                       )
                                      ),
                                    ],
                                  );
                              },
                            ),
                          barTouchData: BarTouchData(
                             enabled: true,
                             touchTooltipData: BarTouchTooltipData(
                               tooltipBgColor: const Color(0xFF2C3E50),
                               tooltipPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                               tooltipMargin: 8,
                               getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                 if (groupIndex < 0 || groupIndex >= report.weeklyProgress.length) {
                                   return null;
                                 }
                                 final dayProgressPercent = (report.weeklyProgress[groupIndex] * 100).toStringAsFixed(0);
                                 String day = '';
                                 switch (groupIndex) {
                                   case 0: day = 'Mon'; break; case 1: day = 'Tue'; break; case 2: day = 'Wed'; break;
                                   case 3: day = 'Thu'; break; case 4: day = 'Fri'; break; case 5: day = 'Sat'; break;
                                   case 6: day = 'Sun'; break;
                                   default: return null;
                                 }
                                 return BarTooltipItem(
                                   '$day: $dayProgressPercent%',
                                   const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, ),
                                 );
                               },
                             ),
                           ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSettingsDrawerContent(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),

        ListTile(
          leading: const Icon(Icons.account_circle_outlined, color: greyText),
          title: const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
              Navigator.pop(context);
              print('Account tapped');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Settings (Not Implemented)'), duration: Duration(seconds: 1)));
            },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        ListTile(
          leading: const Icon(Icons.tune_outlined, color: greyText),
          title: const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
              Navigator.pop(context);
              print('Preferences tapped');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences (Not Implemented)'), duration: Duration(seconds: 1)));
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        ListTile(
           leading: const Icon(Icons.privacy_tip_outlined, color: greyText),
          title: const Text('Privacy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
              Navigator.pop(context);
              print('Privacy tapped');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Settings (Not Implemented)'), duration: Duration(seconds: 1)));
            },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        ListTile(
           leading: const Icon(Icons.info_outline, color: greyText),
          title: const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
            Navigator.pop(context);
            print('About tapped');
             showAboutDialog(
                context: context,
                applicationName: 'Turo App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Your Company Name',
             );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 24.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: logoutRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10.0), ),
              textStyle: const TextStyle( fontSize: 16, fontWeight: FontWeight.w600, ),
              elevation: 2, shadowColor: Colors.black.withOpacity(0.2),
            ),
            onPressed: () {
                Navigator.pop(context);
                print('Logout tapped');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logging out... (Not Implemented)'), duration: Duration(seconds: 1)));
            },
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }
} 