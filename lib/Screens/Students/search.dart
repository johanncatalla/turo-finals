import 'package:flutter/material.dart';
import 'package:turo/Screens/Students/student_homepage.dart';

import '../../Widgets/navbar.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  int selectedMode = 0;
  int selectedIndex = 1; // Navigation currently at 1
  final List<String> _searchMode = ['Tutor', 'Course', 'Module'];
  final TextEditingController _searchController = TextEditingController();

  // Define nav items for your custom navbar
  final List<NavBarItem> _navItems = [
    NavBarItem(icon: Icons.home, label: 'Home'),
    NavBarItem(icon: Icons.search, label: 'Search'),
    NavBarItem(icon: Icons.description_outlined, label: 'Courses'),
    NavBarItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  // Dummy data for list of tutors
  final List<Map<String, dynamic>> _tutors = [
    {
      'name': 'Joshua Garcia',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱100/hr',
      'tags': ['English', 'Filipino'],
      'experience': '2+',
      'rating': 4.8,
      'bio': 'A dedicated college student with a passion for language and education. Currently pursuing a degree in Psychology at Manu...',
    },
    {
      'name': 'Donny Pangilinan',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱100/hr',
      'tags': ['Math', 'Programming'],
      'experience': '2+',
      'rating': 4.8,
      'bio': 'I\'m Juan De La Cruz, a passionate IT student with a deep fascination for computers and technology. Currently wor...',
    },
    {
      'name': 'Andres Muhlach',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱100/hr',
      'tags': ['Math', 'Programming'],
      'experience': '2+',
      'rating': 4.8,
      'bio': 'I\'m Juan De La Cruz, a passionate IT student with a deep fascination for computers and technology. Currently wor...',
    },
    {
      'name': 'Brent Manalo',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱100/hr',
      'tags': ['English', 'Programming'],
      'experience': '2+',
      'rating': 4.8,
      'bio': 'I\'m Juan De La Cruz, a multi-passionate CS student with a deep fascination for computers and technology. Currently wor...',
    },
  ];

  // Dummy Data for Courses (can be added later)
  // Dummy data for modules (can be added later)

  // Add a method to handle navigation
  void _handleNavigation(int index) {
    // Update your state
    print(index);
    // Add any navigation logic here
    if (index == 0) {
      // Navigate to search page
      Navigator.push(context, MaterialPageRoute(builder: (context) => StudentHomepage()));
    } else if (index == 2) {
      // Navigate to my courses
      // For example: Navigator.push(context, MaterialPageRoute(builder: (context) => MyCoursesScreen()));
    } else if (index == 3) {
      // Navigate to profile
      // For example: Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                text: const TextSpan(
                  text: 'Find the ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: 'best tutor',
                      style: TextStyle(
                        color: Color(0xFF4DA6A6),
                      ),
                    ),
                    TextSpan(text: '\njust for '),
                    TextSpan(
                      text: 'you',
                      style: TextStyle(
                        color: Color(0xFFF7941D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Customize the search filter to find a tutor that match your needs.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DA6A6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.filter_alt_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tutors.length,
                itemBuilder: (context, index) {
                  final tutor = _tutors[index];
                  return TutorCard(tutor: tutor);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          setState(() {
            selectedIndex = index;
          });

          // Add navigation logic here
          switch (index) {
            case 0:
            // Navigate to Home
              Navigator.pushReplacementNamed(context, '/studenthome');
              break;
            case 1:
            // Already on Search page, do nothing
              break;
            case 2:
            // Navigate to Courses
              Navigator.pushReplacementNamed(context, '/courses');
              break;
            case 3:
            // Navigate to Profile
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: _navItems,
        selectedColor: const Color(0xFFF7941D), // Orange color from your theme
        unselectedColor: Colors.grey,
        backgroundColor: Colors.black,
      ),
    );
  }
}

class TutorCard extends StatelessWidget {
  final Map<String, dynamic> tutor;

  const TutorCard({
    super.key,
    required this.tutor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(tutor['image']),
                backgroundColor: Colors.grey.shade300,
                child: tutor['image'].startsWith('assets/')
                    ? null
                    : Icon(Icons.person, size: 30, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                tutor['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 5),
                              if (tutor['verified'])
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF4DA6A6),
                                  size: 15,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          tutor['price'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF7941D),
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        ...List.generate(
                          tutor['tags'].length,
                              (i) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8F2F6),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              tutor['tags'][i],
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3F8E9B),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8F2F6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            tutor['experience'],
                            style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3F8E9B)
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAE6CC),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFF7941D),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tutor['rating'].toString(),
                                style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tutor['bio'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: const Color(0xFFD8F2F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          color: Color(0xFF4DA6A6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}