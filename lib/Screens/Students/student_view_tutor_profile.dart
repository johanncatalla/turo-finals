import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:turo/Widgets/navbar.dart';
import 'package:turo/Screens/Students/student_CourseSectionUI.dart';
import 'package:turo/Screens/Students/studentprofileUI.dart' hide Course, CourseDetailsScreen; // Hide potential duplicates

// --- Define Custom Colors (Ensure consistency or move to a theme file) ---
const Color primaryTeal = Color(0xFF3F8E9B); // Used for verified icon, tab indicator
const Color primaryOrange = Color(0xFFF9A825); // Used for buttons, selected nav item
const Color darkCharcoal = Color(0xFF303030); // Used for nav bar background
const Color lightGreyBg = Color(0xFFF5F5F5); // Used for course card background
const Color searchBarBg = Color(0xFFF0F0F0); // Used for app bar search lookalike
const Color darkText = Color(0xFF37474F); // Used for app bar back icon, etc.
const Color greyText = Color(0xFF616161); // Used for descriptions, subtitles


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

// --- Local Scroll Behavior ---
class _MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch, PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus, PointerDeviceKind.mouse,
      };
}

// --- Student's View of Tutor Profile Screen ---
class StudentViewTutorProfileScreen extends StatefulWidget {
  final Lecturer lecturer;
  const StudentViewTutorProfileScreen({ Key? key, required this.lecturer}) : super(key: key);

  @override
  State<StudentViewTutorProfileScreen> createState() => _StudentViewTutorProfileScreenState();
}

class _StudentViewTutorProfileScreenState extends State<StudentViewTutorProfileScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  Widget _imageErrorBuilder(context, error, stackTrace) {
    print("Error loading image: $error");
    return Container( color: Colors.grey[200], alignment: Alignment.center,
      child: Icon( Icons.broken_image_outlined, color: Colors.grey[400], size: 30),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        backgroundColor: Colors.white, elevation: 1,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: darkText),
            onPressed: () => Navigator.of(context).pop()),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: searchBarBg,
            borderRadius: BorderRadius.circular(20) 
          ),
          child: Row(
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                  child: Icon(Icons.search, color: Colors.grey[600], size: 20)), 
              Expanded(
                  child: Text(
                      widget.lecturer.name, 
                      style: TextStyle( color: Colors.grey[700], fontSize: 16),
                      overflow: TextOverflow.ellipsis, 
                      maxLines: 1)),
            ],
          ),
        ),
        titleSpacing: 8.0, 
        actions: const [], 
      ),
      // --- CORRECTED Bottom Navigation Bar ---
      bottomNavigationBar: NavBar(
        items: bottomNavItems,
        selectedIndex: 1, 
        onItemSelected: (index) {
          if (index == 3) {
            print("Navigating from Tutor Profile to Student Profile");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StudentProfileMainScreen()),
            );
          } else if (index == 1) {
            print("Already on Tutor Profile (Search context) - Tapped Search Icon");
          } else if (index == 0) {
            // Navigate to Home Screen
            print("NavBar Tapped: Index 0 (Home)");
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Navigate to ${bottomNavItems[index].label}... (Not Implemented)'), duration: const Duration(seconds: 1))
             );
          } else if (index == 2) {
             print("NavBar Tapped: Index 2 (Schedule)");
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Navigate to ${bottomNavItems[index].label}... (Not Implemented)'), duration: const Duration(seconds: 1))
             );
          }
        },
        selectedColor: primaryOrange,
        unselectedColor: Colors.white60,
        backgroundColor: darkCharcoal,
      ),
      // --- End Corrected Bottom Navigation Bar ---
      body: ScrollConfiguration(
        behavior: _MyCustomScrollBehavior(), 
        child: NestedScrollView( 
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // Section 1: Profile Header (Not part of SliverAppBar)
              SliverToBoxAdapter(child: _buildProfileHeader(context)),
              // Section 2: Certifications (Horizontal scroll)
              SliverToBoxAdapter(child: _buildCertificationsSectionHorizontal(context)),
              // Section 3: Pinned TabBar
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate( 
                  TabBar(
                    controller: _tabController, 
                    labelColor: primaryTeal,
                    unselectedLabelColor: Colors.grey, 
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    indicatorSize: TabBarIndicatorSize.label, 
                    indicator: const BoxDecoration( 
                      border: Border( bottom: BorderSide( color: primaryTeal, width: 3.0))),
                    tabs: const [ 
                       Tab(text: 'Courses'), Tab(text: 'Modules'), Tab(text: 'Reviews')],
                  ),
                ),
                pinned: true, 
              ),
            ],
          body: TabBarView(
            controller: _tabController, 
            children: [
              // Content for each tab
              _buildCoursesList(context),   // Tab 1: Courses
              _buildModulesList(context),   // Tab 2: Modules
              _buildReviewsList(context)    // Tab 3: Reviews
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builder: Profile Header ---
  Widget _buildProfileHeader(BuildContext context) {
     String coverImageUrl = 'assets/cover.png'; 

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
                coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: _imageErrorBuilder, 
              ),
            ),

            Positioned(
              bottom: -30, 
              left: 20,
              child: CircleAvatar(
                radius: 42, backgroundColor: Colors.white, 
                child: CircleAvatar(
                  radius: 40, backgroundColor: Colors.grey[200], 
                  backgroundImage: AssetImage(widget.lecturer.imageUrl), 
                  onBackgroundImageError: (e, s) { print('Error loading profile image: $e'); } 
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10), 
        Padding(
          padding: const EdgeInsets.only(top: 0, right: 16.0, bottom: 0, left: 16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  OutlinedButton(
                    onPressed: () {  print("Book tapped"); },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryOrange, // Text/icon color
                      side: const BorderSide(color: primaryOrange, width: 1.5), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      textStyle: const TextStyle( fontSize: 13, fontWeight: FontWeight.bold),
                      minimumSize: const Size(0, 32), 
                      ),
                    child: const Text('Book'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {  print("Message tapped"); },
                     style: OutlinedButton.styleFrom( 
                      foregroundColor: primaryOrange,
                      side: const BorderSide(color: primaryOrange, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      textStyle: const TextStyle( fontSize: 13, fontWeight: FontWeight.bold),
                      minimumSize: const Size(0, 32),
                      ),
                    child: const Text('Message'),
                  ),
              ],
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
                    Text( widget.lecturer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(width: 6),
                    if (widget.lecturer.isVerified) const Icon(Icons.verified, color: primaryTeal, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text( widget.lecturer.description, style: const TextStyle(color: greyText, fontSize: 14, height: 1.4)),
             ]
          ),
        ),
        const SizedBox(height: 16), 
      ],
    );
  }

  // --- Widget Builder: Certifications Section (Horizontally scrollable) ---
  Widget _buildCertificationsSectionHorizontal(BuildContext context) {
    final certifications = [
      { 'title': 'English Proficiency Cert.', 'description': '${widget.lecturer.name} earned TESDA certificate...', 'imagePath': 'assets/certificate.png', }, 
      { 'title': 'Tutoring Techniques Workshop', 'description': 'Completed workshop on student engagement.', 'imagePath': 'assets/certificate.png', },
      { 'title': 'Subject Mastery Verified', 'description': 'Verified expertise in core subject areas.', 'imagePath': 'assets/certificate.png', },
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
          return _buildCertificationCardHorizontal( cert['title']!, cert['description']!, cert['imagePath']! );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 12),
      ),
    );
  }

  // --- Helper: Certification Card (for horizontal list) ---
  Widget _buildCertificationCardHorizontal(String title, String description, String imagePath) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Card(
        clipBehavior: Clip.antiAlias, 
        elevation: 1, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: primaryTeal, 
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                  title,
                  style: const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: Container(
                color: Colors.white, 
                padding: const EdgeInsets.all(10.0),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.center,
                   children: [
                    SizedBox( width: 40, height: 40,
                        child: Image.asset( imagePath, fit: BoxFit.contain, errorBuilder: _imageErrorBuilder)), 
                    const SizedBox(width: 10), 
                    Expanded( child: Text(
                        description,
                        style: const TextStyle(fontSize: 11, color: greyText, height: 1.3),
                        maxLines: 3, overflow: TextOverflow.ellipsis)), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // --- Widget Builder: Courses List (for TabView) ---
  Widget _buildCoursesList(BuildContext context) {
    final courses = [
      Course( title: 'Conversational English', details: '1hr/day • ${widget.lecturer.name}', description: 'Build confidence and fluency in everyday English conversations.', imagePath: 'assets/English.png', rate: '₱100/hr'),
      Course( title: 'Basic Filipino Grammar', details: '45min/day • ${widget.lecturer.name}', description: 'Learn foundational grammar rules of the Filipino language.', imagePath: 'assets/Journal.png', rate: '₱90/hr') 
    ];

    if (courses.isEmpty) return const Center( child: Padding( padding: EdgeInsets.all(20.0), child: Text( 'No courses offered yet.', style: TextStyle(color: Colors.grey, fontSize: 16))));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0), 
      itemCount: courses.length,
      itemBuilder: (context, index) => _buildCourseCard(context, courses[index]), 
    );
  }

  // --- Helper: Course Card (for Courses Tab) ---
  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0), 
      color: lightGreyBg, 
      elevation: 0, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      child: InkWell( 
        onTap: () {
          print("Tapped on course: ${course.title}");
           Navigator.push( context, MaterialPageRoute(
             builder: (context) => const CourseDetailsScreen(),
             ),
            );
           ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Viewing details for ${course.title}...'), duration: const Duration(seconds: 1)));
        },
        borderRadius: BorderRadius.circular(12), 
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.asset( course.imagePath, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder)),
              const SizedBox(width: 12), 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(course.duration, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(widget.lecturer.name, style: TextStyle(fontSize: 12, color: Colors.grey[700])), 
                        ]
                    ),
                    const SizedBox(height: 6),
                    Text( course.description, style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (course.rate != null && course.rate!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text( course.rate!, style: TextStyle( fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange[800]))
                        ]
                  ]
                )
              ),
            ],
          ),
        ),
      ),
    );
  }


  // --- Widget Builder: Modules List (for TabView) ---
  Widget _buildModulesList(BuildContext context) {
     final modules = [
       { 'title': 'Module 1: Greetings & Introductions', 'tags': 'English | Speaking | Beginner', 'locked': false },
       { 'title': 'Module 2: Understanding Phrasal Verbs', 'tags': 'English | Vocabulary | Intermediate', 'locked': true },
       { 'title': 'Module 3: Past Tense Conjugation', 'tags': 'Filipino | Grammar | Beginner', 'locked': true },
     ];

     if (modules.isEmpty) return const Center( child: Padding( padding: EdgeInsets.all(20.0), child: Text( 'No modules listed yet.', style: TextStyle(color: Colors.grey, fontSize: 16))));

     return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleListItem( context, module['title'] as String, module['tags'] as String, module['locked'] as bool );
        },
    );
   }

   // --- Helper: Module List Item ---
   Widget _buildModuleListItem(BuildContext context, String title, String tags, bool isLocked) {
     return Container(
       padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0), 
       decoration: BoxDecoration( border: Border( bottom: BorderSide(color: Colors.grey[200]!, width: 1.0))),
       child: Row(
         children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text( title, style: const TextStyle( fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                 const SizedBox(height: 4),
                 Text( tags, style: const TextStyle(fontSize: 13, color: greyText))
                 ]
             )
           ),
           if (isLocked) Padding(
             padding: const EdgeInsets.only(left: 16.0), 
             child: Icon(Icons.lock_outline, color: greyText, size: 24) 
           ),
         ],
       ),
     );
   }


  // --- Widget Builder: Reviews List (for TabView) ---
  Widget _buildReviewsList(BuildContext context) {
    final reviews = [
      Review( name: 'Samantha Lee', date: 'Oct 15, 2023', reviewText: 'Excellent tutor! ${widget.lecturer.name} was very patient and helped me understand difficult concepts clearly. Highly recommend!', rating: 5, imagePath: 'assets/image4.png'), 
      Review( name: 'David Chen', date: 'Sep 30, 2023', reviewText: 'Very knowledgeable and adjusted the pace perfectly for me. Made learning enjoyable and engaging.', rating: 4, imagePath: 'assets/image2.png') 
    ];

    if (reviews.isEmpty) return const Center( child: Padding( padding: EdgeInsets.all(20.0), child: Text( 'No reviews yet.', style: TextStyle(color: Colors.grey, fontSize: 16))));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
      itemCount: reviews.length,
      itemBuilder: (context, index) => _buildReviewCard(context, reviews[index]), 
    );
  }

  // --- Helper: Review Card (for Reviews Tab) ---
  Widget _buildReviewCard(BuildContext context, Review review) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0), 
      decoration: BoxDecoration( border: Border( bottom: BorderSide(color: Colors.grey[200]!, width: 1.0)) ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0), 
            child: Image.asset( review.imagePath, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder) 
          ),
          const SizedBox(width: 16), 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text( review.name, style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                const SizedBox(height: 2),
                Text( review.date, style: const TextStyle(fontSize: 13, color: greyText)),
                const SizedBox(height: 8),
                Text( review.reviewText, style: TextStyle( fontSize: 14, height: 1.4, color: Colors.grey[700]), maxLines: 3, overflow: TextOverflow.ellipsis), 
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star_rounded : Icons.star_border_rounded, 
                          color: Colors.amber, size: 20);
                        }
                      )
                  )
                ),
              ]
            )
          ),
        ],
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1.0))
      ),
      child: _tabBar, 
    );
  }

  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => _tabBar != oldDelegate._tabBar;
}
