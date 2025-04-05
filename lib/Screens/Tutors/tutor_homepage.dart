import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/role_select.dart';

class TutorHomepage extends StatefulWidget {
  const TutorHomepage({super.key});

  @override
  State<TutorHomepage> createState() => _TutorHomepageState();
}

class _TutorHomepageState extends State<TutorHomepage> {
  // User data - to be populated from auth provider
  String _tutorName = "Tutor";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from auth provider
  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        setState(() {
          _tutorName = authProvider.user!.fullName;
        });
      }
    });
  }

  // Add logout method
  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (shouldLogout) {
      await authProvider.logout();
      
      // Navigate to role selection screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null, // Remove the app bar completely
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message and notification/logout buttons
            _buildWelcomeHeader(),
            
            // Hero Banner with search bar overlay
            _buildHeroBanner(),

            // Classes section
            _buildSectionHeader('Classes', () {}),
            _buildClassesRow(),

            // Students list
            _buildSectionHeader('Students', () {}),
            _buildStudentList(),
          ],
        ),
      ),
    );
  }

  // Modified Welcome message to include user's name and add logout button
  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good day,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                _tutorName,
                style: const TextStyle(
                  fontSize: 20,
                  height: 0,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal, // Changed to teal for tutor
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Logout button
              Container(
                height: 40,
                width: 40,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  iconSize: 20,
                  onPressed: _handleLogout,
                ),
              ),
              // Notification button
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.teal, // Changed to teal for tutor
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  iconSize: 20,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Stack(
      children: [
        // Banner with correct aspect ratio to match viewport
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          height: 220, // Adjusted height to match viewport
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage('assets/tutor-home.png'), // Keep tutor's banner image
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Overlay search bar on the banner image - positioned precisely
        Positioned(
          bottom: 16,
          left: 30,
          right: 30,
          child: _buildSearchBar(),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 5, left: 0, right: 0),
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for a student...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.search, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // Section header with "See All" button
  Widget _buildSectionHeader(String title, VoidCallback onSeeAllPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: onSeeAllPressed,
            child: const Text(
              'See All',
              style: TextStyle(
                fontSize: 18,
                color: Colors.teal, // Changed to teal for tutor
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Classes row 2x2 grids
  Widget _buildClassesRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Reduced padding
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12.0, // Reduced spacing
        mainAxisSpacing: 12.0, // Reduced spacing
        children: [
          _buildClassCard('assets/image1.png', 0.7),
          _buildClassCard('assets/image2.png', 0.7),
          _buildClassCard('assets/image3.png', 0.7),
          _buildClassCard('assets/image4.png', 0.7),
        ],
      ),
    );
  }

  Widget _buildClassCard(String imagePath, double scale) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: SizedBox(
          width: double.infinity * scale, // Scale width
          height: double.infinity * scale, // Scale height
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  //Students list
  Widget _buildStudentList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildStudentCard(
            'Student ${index + 1}',
            'assets/student${index + 1}.png',
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(String name, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50.0),
            child: Image.asset(
              imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Icon(
                    Icons.check_circle,
                    color: Colors.teal, // Changed to teal for tutor
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.teal, // Changed to teal for tutor
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            icon:
                Image.asset('assets/calendar-check.png', width: 24, height: 24),
            onPressed: () {},
          ),
          IconButton(
            icon: Image.asset('assets/message-text-outline.png',
                width: 24, height: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}