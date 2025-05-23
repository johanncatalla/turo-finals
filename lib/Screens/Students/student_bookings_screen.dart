import 'package:flutter/material.dart';
import 'package:turo/Widgets/booking_management_widget.dart';
import 'package:turo/Widgets/navbar.dart';

class StudentBookingsScreen extends StatefulWidget {
  const StudentBookingsScreen({super.key});

  @override
  State<StudentBookingsScreen> createState() => _StudentBookingsScreenState();
}

class _StudentBookingsScreenState extends State<StudentBookingsScreen> {
  final int _bottomNavIndex = 2; // Bookings/Schedule is index 2

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
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Color(0xFF303030),
            fontSize: 18,
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
            print("Already on Bookings Screen.");
            return;
          }

          switch (index) {
            case 0: // Home
              print("Navigate to Home from Bookings");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Home... (Not Implemented)'),
                  duration: Duration(seconds: 1),
                ),
              );
              break;

            case 1: // Search
              print("Navigate to Search from Bookings");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Search... (Not Implemented)'),
                  duration: Duration(seconds: 1),
                ),
              );
              break;

            case 3: // Profile
              print("Navigate to Profile from Bookings");
              Navigator.pop(context); // Go back to profile
              break;
          }
        },
        selectedColor: const Color(0xFFF9A825), // primaryOrange
        unselectedColor: Colors.white60,
        backgroundColor: const Color(0xFF303030), // darkCharcoal
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: BookingManagementWidget(
          userRole: 'student',
          primaryColor: Color(0xFFF9A825), // primaryOrange
          secondaryTextColor: Color(0xFF616161), // greyText
          cardBackgroundColor: Colors.white,
          shadowColor: Colors.grey,
          borderColor: Color(0xFFEEEEEE),
        ),
      ),
    );
  }
} 