import 'package:flutter/gestures.dart'; // Required for Gesture or drag click screen
import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind; 


//Class
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

// Added Review Class
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

//Global Variables

// Define App Colors
const Color primaryTeal = Color(0xFF3F8E9B);
const Color darkCharcoal = Color(0xFF303030);
const Color lightGreyBg = Color(0xFFF5F5F5); 

//Scroll and dragable to hover
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.mouse,
      };
}

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

// Main Application

void main() {
  runApp(const MyApp());
}

//Main App UI
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
          primaryColor: primaryTeal,
          hintColor: primaryTeal,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          tabBarTheme: const TabBarTheme(
            labelColor: primaryTeal,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: primaryTeal,
                  width: 3.0,
                ),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            color: Colors.white,
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
            foregroundColor: primaryTeal,
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: primaryTeal, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          )),
          iconTheme: const IconThemeData(
            color: Colors.grey,
            size: 18,
          )),
      home: const TutorProfileScreen(),
    );
  }
}

//Tutor Profile Screen 

class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 2;
  bool isLecturer = false;

  //Navbar Items Getter
  List<NavBarItem> get _navBarItems {
    final allItems = [
      NavBarItem(icon: Icons.home_outlined, label: 'Home'),
      NavBarItem(icon: Icons.video_library_outlined, label: 'Library'),
      NavBarItem(icon: Icons.person_outline, label: 'Profile'),
    ];

    if (isLecturer) {
      return allItems.where((item) => item.label != 'Library').toList();
    } else {
      return allItems;
    }
  }

  // Use the global error builder
  final _imageErrorBuilder = globalImageErrorBuilder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging ||
          _tabController.index != _tabController.previousIndex) {
        setState(() {
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {}); 
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(child: _buildProfileHeader(context)),
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
        items: _navBarItems, // Use the getter for conditional items
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
             print("Selected original index: $_bottomNavIndex");
          });
        },
      ),
    );
  }

  // Tutor Profile Screen Sections

  Widget _buildProfileHeader(BuildContext context) {
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
                  children: const [
                    Text(
                      'Joshua Garcia', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified, color: primaryTeal, size: 20), 
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'A dedicated college student with a passion for language and education. Currently pursuing a degree in Psychology at Manuel S. Enverga University Foundation, I spend my free time tutoring high school students in both English and Filipino.', 
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
                ),
             ]
          ),
        ),
        const SizedBox(height: 16), 
      ],
    );
  }

  Widget _buildCertificationsSection(BuildContext context) {
    // Example Data 
    final certifications = [
      {
        'title': 'English Proficiency for Customer Service Workers',
        'description': 'Joshua just earned his TESDA certification! At Turo, we support our tutors in getting certified to ensure quality education for our students.',
        'imagePath': 'assets/certificate.png', 
      },
      {
        'title': 'English Proficiency for Customer Service Workers',
        'description': 'Joshua just earned his TESDA certification! At Turo, we support our tutors in getting certified to ensure quality education for our students.',
        'imagePath': 'assets/certificate.png', 
      },
      {
        'title': 'English Proficiency for Customer Service Workers',
        'description': 'Joshua just earned his TESDA certification! At Turo, we support our tutors in getting certified to ensure quality education for our students.',
        'imagePath': 'assets/certificate.png', 
      },
    ];

    // If no certifications, show a placeholder
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
                        fit: BoxFit.contain, // Use contain to show the whole image
                        errorBuilder: _imageErrorBuilder, // Use global error builder
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

  Widget _buildCoursesList(BuildContext context) {
    // Example Data 
    final courses = [
      Course(
        title: 'Conversational English',
        details: '1hr/day • Mr. J Perez',
        description: 'A practical course designed to build confidence and fluency in everyday conversations. Through interactive exercises, real-life scenarios, and guided practice, learners will improve their speaking skills, pronunciation, and ability to express ideas naturally in English. Perfect for students, professionals, and anyone looking to communicate effectively in various social and work settings.',
        imagePath: 'assets/English.png',
      ),
      Course(
        title: 'Journalism Fundamentals',
        details: '1hr/day • Mr. J Perez',
        description: 'A practical course designed to build confidence and fluency in everyday conversations. Through interactive exercises, real-life scenarios, and guided practice, learners will improve their speaking skills, pronunciation, and ability to express ideas naturally in English. Perfect for students, professionals, and anyone looking to communicate effectively in various social and work settings.',
        imagePath: 'assets/Journal.png', 
      ),
    ];

    // Handle empty state
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

  Widget _buildCourseCard(BuildContext context, Course course) {
    final duration = course.duration; // Use getter
    final tutor = course.tutor; // Use getter

    return InkWell(
      onTap: () {
        // Navigate to CourseDetailsScreen when the section is tapped
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
                  errorBuilder: _imageErrorBuilder, // Use global error builder
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
                         const SizedBox(width: 10), // Spacer
                         const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                         const SizedBox(width: 4),
                         Text(tutor, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                       ],
                    ),
                    const SizedBox(height: 6),
                    // Course Description 
                    Text(
                      course.description,
                      style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black),
                       maxLines: 2, 
                       overflow: TextOverflow.ellipsis, 
                    ),
                    // Rate Display
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
  Widget _buildModulesList(BuildContext context) {
     // Example Data
     final modules = [
       { 'title': 'Photosynthetic Process In Plants', 'tags': 'Science | Biology | High school', 'locked': true, },
       { 'title': 'Photosynthetic Process In Plants', 'tags': 'Science | Biology | High school', 'locked': true, },
     ];

     // Handle empty state
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

   // Reusable widget for displaying a single module item
   Widget _buildModuleListItem(BuildContext context, String title, String tags, bool isLocked) {
     return Container(
       padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
       decoration: BoxDecoration(
         border: Border(
           // Add a bottom border to separate items
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

  // Updated Reviews Section to use Review Class and navigate
  Widget _buildReviewsList(BuildContext context) {
    // Sample Review Data using the Review class
    final reviews = [
      Review(
        name: 'John Leo Echevaria',
        date: 'September 10, 2023',
        reviewText: 'Excellent tutor! Adjusts his lesson to my level of understanding and provides a comfortable learning atmosphere in his class. 10/10 would recommend!',
        rating: 5,
        imagePath: 'assets/image4.png' 
      ),
      Review(
        name: 'John Leo Echevaria',
        date: 'September 10, 2023',
        reviewText: 'Excellent tutor! Adjusts his lesson to my level of understanding and provides a comfortable learning atmosphere in his class. 10/10 would recommend!',
        rating: 5,
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

    Widget _buildReviewCard(BuildContext context, Review review) { 
     return InkWell(
       onTap: () {
         // Navigate to ReviewDetailsScreen when the card is tapped
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
                 errorBuilder: _imageErrorBuilder, // Use global error builder
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
//Course Details Screen 

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
                          child: Text("Delete", style: TextStyle(color: Colors.red)),
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

 //The top section of the Course Details screen
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

  //TabBar for Materials and Reviews
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

//Review Details Screen (NEW)

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
                        review.date, // Display date
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


//Navbar

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

//effects
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

//NavItems
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

//Scrolling
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