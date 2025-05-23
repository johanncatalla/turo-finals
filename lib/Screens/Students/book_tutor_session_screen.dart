import 'package:flutter/material.dart';
import 'package:turo/Widgets/tutor_booking_widget.dart';
import 'package:turo/Widgets/navbar.dart';
import 'package:turo/services/directus_service.dart';

class BookTutorSessionScreen extends StatefulWidget {
  final String tutorUserId;
  final String tutorName;
  final String? tutorProfileId;
  final double? hourlyRate;
  final String? preSelectedCourseId;

  const BookTutorSessionScreen({
    super.key,
    required this.tutorUserId,
    required this.tutorName,
    this.tutorProfileId,
    this.hourlyRate,
    this.preSelectedCourseId,
  });

  @override
  State<BookTutorSessionScreen> createState() => _BookTutorSessionScreenState();
}

class _BookTutorSessionScreenState extends State<BookTutorSessionScreen> {
  final DirectusService _directusService = DirectusService();
  final int _bottomNavIndex = 2; // Bookings/Schedule is index 2
  
  List<Map<String, dynamic>> _availableCourses = [];
  bool _isLoadingCourses = false;
  String? _coursesError;

  @override
  void initState() {
    super.initState();
    _loadTutorCourses();
  }

  Future<void> _loadTutorCourses() async {
    print('🔍 Loading courses for tutorProfileId: ${widget.tutorProfileId}');
    
    if (widget.tutorProfileId == null) {
      print('⚠️ No tutorProfileId provided, cannot load courses');
      return;
    }
    
    setState(() {
      _isLoadingCourses = true;
      _coursesError = null;
    });

    try {
      final response = await _directusService.fetchCoursesByTutorId(widget.tutorProfileId!);
      
      print('📋 Course loading response: ${response.toString()}');
      
      if (response['success']) {
        final coursesList = List<Map<String, dynamic>>.from(response['data'] ?? []);
        print('✅ Successfully loaded ${coursesList.length} courses for tutor');
        
        setState(() {
          _availableCourses = coursesList;
          _isLoadingCourses = false;
        });
      } else {
        print('❌ Failed to load courses: ${response['message']}');
        setState(() {
          _coursesError = response['message'] ?? 'Failed to load courses';
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      print('💥 Exception loading courses: ${e.toString()}');
      setState(() {
        _coursesError = 'Error loading courses: ${e.toString()}';
        _isLoadingCourses = false;
      });
    }
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
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF303030)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book Session with ${widget.tutorName}',
          style: const TextStyle(
            color: Color(0xFF303030),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      bottomNavigationBar: NavBar(
        items: bottomNavItems,
        selectedIndex: _bottomNavIndex,
        onItemSelected: (index) {
          if (index == _bottomNavIndex) {
            print("Already on Book Session Screen.");
            return;
          }

          switch (index) {
            case 0: // Home
              print("Navigate to Home from Book Session");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Home... (Not Implemented)'),
                  duration: Duration(seconds: 1),
                ),
              );
              break;

            case 1: // Search
              print("Navigate to Search from Book Session");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Search... (Not Implemented)'),
                  duration: Duration(seconds: 1),
                ),
              );
              break;

            case 3: // Profile
              print("Navigate to Profile from Book Session");
              Navigator.pop(context);
              break;
          }
        },
        selectedColor: const Color(0xFFF9A825), // primaryOrange
        unselectedColor: Colors.white60,
        backgroundColor: const Color(0xFF303030), // darkCharcoal
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutor Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tutorName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF303030),
                          ),
                        ),
                        if (widget.hourlyRate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₱${widget.hourlyRate!.toStringAsFixed(0)}/hour',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF9A825),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Course Loading State
            if (_isLoadingCourses) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_coursesError != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Error loading courses: $_coursesError',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadTutorCourses,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Booking Widget
            TutorBookingWidget(
              tutorUserId: widget.tutorUserId,
              tutorProfileId: widget.tutorProfileId,
              tutorName: widget.tutorName,
              hourlyRate: widget.hourlyRate,
              preSelectedCourseId: widget.preSelectedCourseId,
              availableCourses: _availableCourses,
              primaryColor: const Color(0xFFF9A825), // primaryOrange
              secondaryTextColor: const Color(0xFF616161), // greyText
              cardBackgroundColor: Colors.white,
              shadowColor: Colors.grey,
              borderColor: const Color(0xFFEEEEEE),
              onBookingComplete: () {
                // Navigate back or to bookings page
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking created! Check your bookings to manage it.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 