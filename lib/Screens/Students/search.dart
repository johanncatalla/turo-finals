import 'package:flutter/material.dart';
import 'package:turo/Screens/Students/student_homepage.dart';
import '../../Widgets/navbar.dart';
import '../../Widgets/filter_dialog.dart'; // Import the filter dialog
import '../../Widgets/tutor_card.dart'; // Import the reusable TutorCard

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

  // Filter parameters
  Map<String, dynamic> _activeFilters = {};

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
      'priceValue': 100,
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
      'priceValue': 100,
      'tags': ['Math', 'Programming'],
      'experience': '2+',
      'rating': 4.8,
      'bio': 'I\'m Juan De La Cruz, a passionate IT student with a deep fascination for computers and technology. Currently wor...',
    },
    {
      'name': 'Andres Muhlach',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱200/hr',
      'priceValue': 200,
      'tags': ['Math', 'Programming'],
      'experience': '2+',
      'rating': 4.8,
      'bio': 'I\'m Juan De La Cruz, a passionate IT student with a deep fascination for computers and technology. Currently wor...',
    },
    {
      'name': 'Brent Manalo',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱150/hr',
      'priceValue': 150,
      'tags': ['English', 'Programming'],
      'experience': '2+',
      'rating': 4.8,
      'bio': 'I\'m Juan De La Cruz, a multi-passionate CS student with a deep fascination for computers and technology. Currently wor...',
    },
    {
      'name': 'Carlos Santos',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱300/hr',
      'priceValue': 300,
      'tags': ['Science', 'Math'],
      'experience': '3+',
      'rating': 4.5,
      'bio': 'Experienced science and math tutor with a background in engineering. I specialize in making complex concepts accessible to students...',
    },
    {
      'name': 'Maria Reyes',
      'image': 'assets/joshua.png',
      'verified': true,
      'price': '₱250/hr',
      'priceValue': 250,
      'tags': ['Filipino', 'Journalism'],
      'experience': '4+',
      'rating': 4.9,
      'bio': 'Former journalist with a passion for teaching language and writing skills. I help students improve their communication abilities...',
    },
  ];

  // Filtered tutors list
  List<Map<String, dynamic>> _filteredTutors = [];

  @override
  void initState() {
    super.initState();
    // Initialize filtered tutors with all tutors
    _filteredTutors = List.from(_tutors);
  }

  // Handle filter application
  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _activeFilters = filters;

      // Start with all tutors
      _filteredTutors = List.from(_tutors);

      // Apply category filter
      if (filters.containsKey('categories') &&
          filters['categories'] is List &&
          (filters['categories'] as List).isNotEmpty) {

        _filteredTutors = _filteredTutors.where((tutor) {
          // Check if any of the tutor's tags match any of the selected categories
          return tutor['tags'].any((tag) =>
              (filters['categories'] as List).contains(tag));
        }).toList();
      }

      // Apply price range filter
      if (filters.containsKey('priceRange') && filters['priceRange'] is Map) {
        int minPrice = filters['priceRange']['min'] as int;
        int maxPrice = filters['priceRange']['max'] as int;

        _filteredTutors = _filteredTutors.where((tutor) {
          // Extract numeric price value
          int price = tutor['priceValue'] as int;
          return price >= minPrice && price <= maxPrice;
        }).toList();
      }

      // Apply rating filter
      if (filters.containsKey('rating') && filters['rating'] is int) {
        int minRating = filters['rating'] as int;

        _filteredTutors = _filteredTutors.where((tutor) {
          double rating = tutor['rating'] as double;
          return rating >= minRating;
        }).toList();
      }
    });
  }

  // Show filter dialog as bottom sheet
  void _showFilterDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation1,
          curve: Curves.easeInOut,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // Start from bottom
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FilterDialog(
            onApplyFilter: _applyFilters,
          ),
        );
      },
    );
  }

  // Navigate to tutor profile
  void _navigateToTutorProfile(Map<String, dynamic> tutor) {
    // Implement navigation to tutor profile
    // For example: Navigator.pushNamed(context, '/tutor-profile', arguments: tutor);
    print('Navigate to profile for: ${tutor['name']}');
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
                              onChanged: (value) {
                                // Add search functionality
                                setState(() {
                                  if (value.isEmpty) {
                                    // If search is empty, show filtered tutors based on active filters
                                    _applyFilters(_activeFilters);
                                  } else {
                                    // Filter tutors by name and apply active filters
                                    _filteredTutors = _tutors.where((tutor) {
                                      bool matchesSearch = tutor['name']
                                          .toString()
                                          .toLowerCase()
                                          .contains(value.toLowerCase());

                                      // Apply other filters
                                      bool matchesFilters = true;

                                      // Skip filtering if no active filters
                                      if (_activeFilters.isEmpty) {
                                        return matchesSearch;
                                      }

                                      // Apply category filter
                                      if (_activeFilters.containsKey('categories') &&
                                          _activeFilters['categories'] is List &&
                                          (_activeFilters['categories'] as List).isNotEmpty) {
                                        matchesFilters = tutor['tags'].any((tag) =>
                                            (_activeFilters['categories'] as List).contains(tag));
                                      }

                                      // Apply price filter
                                      if (matchesFilters && _activeFilters.containsKey('priceRange') &&
                                          _activeFilters['priceRange'] is Map) {
                                        int minPrice = _activeFilters['priceRange']['min'] as int;
                                        int maxPrice = _activeFilters['priceRange']['max'] as int;
                                        int price = tutor['priceValue'] as int;
                                        matchesFilters = price >= minPrice && price <= maxPrice;
                                      }

                                      // Apply rating filter
                                      if (matchesFilters && _activeFilters.containsKey('rating') &&
                                          _activeFilters['rating'] is int) {
                                        matchesFilters = tutor['rating'] >= _activeFilters['rating'];
                                      }

                                      return matchesSearch && matchesFilters;
                                    }).toList();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _showFilterDialog,
                    child: Container(
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
                  ),
                ],
              ),
            ),
            // Filter badges (only show when filters are active)
            if (_activeFilters.containsKey('categories') &&
                _activeFilters['categories'] is List &&
                (_activeFilters['categories'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_activeFilters['categories'] as List).map<Widget>((category) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          // Remove this category from filters
                          List categories = List.from(_activeFilters['categories']);
                          categories.remove(category);
                          _activeFilters = {
                            ..._activeFilters,
                            'categories': categories,
                          };
                          // Reapply filters
                          _applyFilters(_activeFilters);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8F2F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4DA6A6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF4DA6A6),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
            // Tutor List
            Expanded(
              child: _filteredTutors.isEmpty
                  ? const Center(
                child: Text(
                  'No tutors match your filters',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredTutors.length,
                itemBuilder: (context, index) {
                  final tutor = _filteredTutors[index];
                  return TutorCard(
                    tutor: tutor,
                    onViewProfile: () => _navigateToTutorProfile(tutor),
                  );
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