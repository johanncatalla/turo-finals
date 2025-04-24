import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:turo/Screens/Students/student_view_tutor_profile.dart';

// --- Define Custom Colors ---
const Color primaryTeal = Color(0xFF26A69A);
const Color lightTealBackground = Color(0xFFE0F2F1);
const Color darkText = Color(0xFF37474F);
const Color greyText = Color(0xFFBDBDBD);
const Color lightGreyText = Color(0xFFE0E0E0);
const Color lockIconColor = Color(0xFF5F6368);


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Details',
      theme: ThemeData(
          primarySwatch: Colors.teal,
          colorScheme:
              ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(
            primary: primaryTeal,
            secondary: Colors.amber[600],
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: darkText,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: darkText,
            elevation: 1,
            iconTheme: IconThemeData(color: darkText),
            titleTextStyle: TextStyle(
                color: darkText, fontSize: 18, fontWeight: FontWeight.w500),
             surfaceTintColor: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Roboto',
          cardTheme: CardTheme(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: primaryTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          tabBarTheme: TabBarTheme(
            labelColor: primaryTeal,
            unselectedLabelColor: Colors.grey[600],
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 2.5,
                color: primaryTeal,
              ),
            ),
          ),
          listTileTheme: ListTileThemeData(
            iconColor: darkText,
            textColor: darkText,
            subtitleTextStyle:
                TextStyle(color: Colors.grey[600]),
          )),
      home: const CourseDetailsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Data Models ---
class Course {
  final String title;
  final String details; // Contains duration and tutor like "1hr/day • Tutor Name"
  final String description;
  final String imagePath;
  final String? rate; // Optional rate like "₱100/hr"

  Course({
    required this.title,
    required this.details,
    required this.description,
    required this.imagePath,
    this.rate,
  });

  // Helper getters to extract info from 'details' string
  String get duration {
    final parts = details.split('•');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  String get tutor {
    final parts = details.split('•');
    return parts.length > 1 ? parts[1].trim() : '';
  }
}

class Lecturer {
  final String name;
  final String description;
  final String imageUrl;
  final bool isVerified;

  Lecturer({
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isVerified = true,
  });
}

class CourseMaterial {
  final String title;
  final String category;
  final bool isLocked;

  CourseMaterial({
    required this.title,
    required this.category,
    this.isLocked = true,
  });
}

class CourseReview {
  final String reviewerName;
  final String date;
  final String reviewText;
  final String imageUrl;
  final double rating;

  CourseReview({
    required this.reviewerName,
    required this.date,
    required this.reviewText,
    required this.imageUrl,
    required this.rating,
  });
}

// --- Course Details Screen Widget ---
class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final DateTime _firstDay = DateTime.utc(2024, 1, 1);
  final DateTime _lastDay = DateTime.utc(2024, 12, 31);
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  final List<Lecturer> lecturers = [
    Lecturer(
      name: "Joshua Garcia",
      description:
          "A dedicated college student with a passion for language and education. Currently pursuing a degree in Psychology at Manuel S. Enverga University Foundation, I spend my free time tutoring high school students in both English and Filipino. ",
      imageUrl: "assets/profile.png", 
      isVerified: true,
    ),
    Lecturer(
      name: "Andres Muhlach",
      description:
          "A dedicated college student with a passion for language and education. Currently pursuing a degree in Psychology at Manuel S. Enverga University Foundation, I spend my free time tutoring high school students in both English and Filipino. ",
      imageUrl: "assets/tutor2.png",
      isVerified: true,
    ),
  ];
  final List<CourseMaterial> materials = [
     CourseMaterial(
        title: "Photosynthetic Process In Plants",
        category: "Science | Biology | Highschool",
        isLocked: true),
    CourseMaterial(
        title: "Introduction to Conversational Phrases",
        category: "English | Speaking | Beginner",
        isLocked: true),
  ];
  final List<CourseReview> reviews = [
     CourseReview(
      reviewerName: "John Leo Echevaria",
      date: "September 10, 2023",
      reviewText: "Excellent tutor! Adjusts his lesson...",
      imageUrl: "assets/homecard.png",
      rating: 5.0,
    ),
    CourseReview(
      reviewerName: "Maria Dela Cruz",
      date: "August 25, 2023",
      reviewText: "The materials were very helpful...",
      imageUrl: "assets/homecard.png", 
      rating: 5.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    final now = DateTime.now();
    final utcNow = DateTime.utc(now.year, now.month, now.day);
    _focusedDay = utcNow.isBefore(_firstDay) ? _firstDay : utcNow.isAfter(_lastDay) ? _lastDay : utcNow;
    _selectedDay = _focusedDay;
  }

  void _handleTabSelection() {
    if (mounted && !_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: innerBoxIsScrolled ? Colors.white : Colors.transparent,
              foregroundColor: innerBoxIsScrolled ? darkText : Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: innerBoxIsScrolled ? theme.appBarTheme.elevation ?? 1 : 0,
              automaticallyImplyLeading: true,
              leading: innerBoxIsScrolled ? IconButton(
                 icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor ?? darkText),
                 onPressed: () => Navigator.maybePop(context),
              ) : Container(),
              title: innerBoxIsScrolled ? Text(
                'Course Details',
                 style: theme.appBarTheme.titleTextStyle,
              ) : null,
              centerTitle: false,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/English.png', 
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                         height: statusBarHeight + kToolbarHeight,
                         color: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: statusBarHeight, left: 0, right: 0, height: kToolbarHeight,
                      child: Row(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.arrow_back, color: darkText),
                             onPressed: () => Navigator.maybePop(context),
                             tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                           ),
                           Padding(
                             padding: const EdgeInsets.only(left: 0),
                             child: Text(
                               'Course Details',
                               style: theme.appBarTheme.titleTextStyle?.copyWith(color: darkText),
                             ),
                           ),
                         ],
                       ),
                    ),
                  ],
                ),
              ),
            ),
            // --- Course Title Section ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversational English', // Example Title
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row( children: [
                            Icon(Icons.timer_outlined, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('1hr/day', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                          ],
                        ),
                        Text('₱100/hr', style: textTheme.titleMedium?.copyWith( color: Colors.orange[700], fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A practical course designed to build confidence and fluency in everyday conversations...', // Example Desc
                      style: textTheme.bodyMedium?.copyWith( color: Colors.grey[800], height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
             SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                 TabBar(
                   controller: _tabController,
                   tabs: const [
                     Tab(text: 'Lecturer'), Tab(text: 'Materials'), Tab(text: 'Reviews'),
                   ],
                 ),
               ),
              pinned: true,
             ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            children: [
              _buildCurrentTabContent(context),
              const SizedBox(height: 24),
              _buildAvailableDatesHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCalendarCard(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(BuildContext context) {
    switch (_tabController.index) {
      case 0: return _buildLecturersTab(context);
      case 1: return _buildMaterialsTab(context);
      case 2: return _buildReviewsTab(context);
      default: return const SizedBox.shrink();
    }
  }

  // --- Lecturers Tab ---
  Widget _buildLecturersTab(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lecturers.length,
      itemBuilder: (context, index) {
        return _buildLecturerProfile(context, lecturers[index]); // Pass lecturer
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  // --- Materials Tab ---
  Widget _buildMaterialsTab(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: materials.length,
        itemBuilder: (context, index) {
          final material = materials[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text( material.title, style: textTheme.titleMedium?.copyWith( color: darkText, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Text( material.category, style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon( material.isLocked ? Icons.lock : Icons.lock_open, color: lockIconColor, size: 22),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(material.isLocked ? 'Material is locked' : 'Accessing ${material.title}...'), duration: const Duration(seconds: 1)),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- Reviews Tab ---
  Widget _buildReviewsTab(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: reviews.length,
      itemBuilder: (context, index) => _buildReviewItem(context, reviews[index]),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  Widget _buildLecturerProfile(BuildContext context, Lecturer lecturer) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero, elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30, backgroundImage: AssetImage(lecturer.imageUrl),
              onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 30, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row( crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Flexible( child: Text( lecturer.name, style: textTheme.titleMedium?.copyWith( fontWeight: FontWeight.bold, color: darkText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (lecturer.isVerified) Padding( padding: const EdgeInsets.only(left: 4.0), child: Icon(Icons.verified, color: primaryTeal, size: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text( lecturer.description, style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row( children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentViewTutorProfileScreen(lecturer: lecturer),
                              ),
                            );
                          },
                          style: TextButton.styleFrom( backgroundColor: lightTealBackground, foregroundColor: primaryTeal),
                          child: const Text('View Profile'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () { /* TODO: Implement Hire action */ print('Hire: ${lecturer.name}'); },
                          child: const Text('Hire'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, CourseReview review) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 1, margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset( review.imageUrl, width: 60, height: 60, fit: BoxFit.cover, filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Container( width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.0)), child: const Icon(Icons.person_outline, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text( review.reviewerName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: darkText)),
                  const SizedBox(height: 2),
                  Text( review.date, style: textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text( review.reviewText, style: textTheme.bodyMedium?.copyWith(color: darkText.withOpacity(0.9), height: 1.4)),
                  const SizedBox(height: 8),
                  Row( mainAxisAlignment: MainAxisAlignment.end, children: [ _buildStarRating(review.rating) ],),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData iconData;
        if (index >= rating) { iconData = Icons.star_border; }
        else if (index > rating - 1 && index < rating) { iconData = Icons.star_half; }
        else { iconData = Icons.star; }
        return Icon(iconData, color: Colors.amber[600], size: 18.0);
      }),
    );
  }

  Widget _buildAvailableDatesHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration( color: primaryTeal, borderRadius: BorderRadius.only( topLeft: Radius.circular(8), topRight: Radius.circular(8))),
        child: Center( child: Text( 'Available Dates', style: textTheme.titleMedium?.copyWith( color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Card(
      margin: EdgeInsets.zero, elevation: 0, clipBehavior: Clip.antiAlias, color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only( bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
        side: BorderSide(color: Color(0xFFEEEEEE), width: 1)
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: TableCalendar(
          firstDay: _firstDay, lastDay: _lastDay, focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            DateTime newFocus = focusedDay.isBefore(_firstDay) ? _firstDay : focusedDay;
            newFocus = newFocus.isAfter(_lastDay) ? _lastDay : newFocus;
            if (!isSameDay(_selectedDay, selectedDay) || !isSameDay(_focusedDay, newFocus)) {
              setState(() { _selectedDay = selectedDay; _focusedDay = newFocus; });
            }
          },
          onFormatChanged: (format) { if (_calendarFormat != format) { setState(() { _calendarFormat = format; }); } },
          onPageChanged: (focusedDay) {
             DateTime newFocus = focusedDay.isBefore(_firstDay) ? _firstDay : focusedDay;
             newFocus = newFocus.isAfter(_lastDay) ? _lastDay : newFocus;
             if (!isSameDay(_focusedDay, newFocus)) { setState(() { _focusedDay = newFocus; }); }
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false, titleCentered: true,
            titleTextStyle: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: darkText),
            leftChevronIcon: const Icon(Icons.chevron_left, color: greyText, size: 24),
            rightChevronIcon: const Icon(Icons.chevron_right, color: greyText, size: 24),
            headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w500),
            weekendStyle: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: TextStyle(color: darkText, fontWeight: FontWeight.w500),
            weekendTextStyle: TextStyle(color: darkText, fontWeight: FontWeight.w500),
            todayDecoration: const BoxDecoration(color: lightTealBackground, shape: BoxShape.circle),
            todayTextStyle: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold),
            selectedDecoration: const BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
            selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            outsideTextStyle: const TextStyle(color: lightGreyText),
            disabledTextStyle: const TextStyle(color: lightGreyText),
          ),
          enabledDayPredicate: (day) {
             final dayUtc = DateTime.utc(day.year, day.month, day.day);
             return !dayUtc.isBefore(_firstDay) && !dayUtc.isAfter(_lastDay);
          },
        ),
      ),
    );
  }
}
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material( color: Theme.of(context).colorScheme.surface, elevation: overlapsContent ? 0.5 : 0.0, child: _tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}