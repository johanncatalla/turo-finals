import 'package:flutter/material.dart';
import '../../Widgets/module_card.dart';
import '../../Widgets/navbar.dart';
import '../../Widgets/filter_dialog.dart';
import '../../Widgets/tutor_card.dart';
import '../../Widgets/course_card.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  int selectedMode = 0; // 0 = Tutor, 1 = Course, 2 = Module
  int selectedIndex = 1; // Navigation currently at 1
  final List<String> _searchModeLabels = ['Tutor', 'Course', 'Module'];
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
  ];

  // Dummy data for list of courses
  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Introduction to Python',
      'image': 'assets/courses/python.png',
      'schedule': '1hr/day',
      'instructor': 'Mr. Catalla',
      'description': 'An engaging beginner-friendly course that introduces the fundamentals of Python...',
      'tags': ['Programming', 'Computer Science'],
      'rating': 4.7,
    },
    {
      'title': 'Conversational English',
      'image': 'assets/courses/python.png',
      'schedule': '1hr/day',
      'instructor': 'Mr. Echevaria',
      'description': 'A practical course designed to build confidence and fluency in conversational...',
      'tags': ['English', 'Language'],
      'rating': 4.9,
    },
    {
      'title': 'Foundational Algebra',
      'image': 'assets/courses/python.png',
      'schedule': '1hr/day',
      'instructor': 'Ms. Oriola',
      'description': 'A foundational course that explores the core principles of algebra, including solving...',
      'tags': ['Math', 'Algebra'],
      'rating': 4.6,
    },
    {
      'title': 'Basic Chemistry',
      'image': 'assets/courses/python.png',
      'schedule': '1hr/day',
      'instructor': 'Ms. Erika',
      'description': 'A practical course designed to build confidence and fluency in understanding and applying chemistry...',
      'tags': ['Science', 'Chemistry'],
      'rating': 4.8,
    },
    {
      'title': 'Journalism',
      'image': 'assets/courses/python.png',
      'schedule': '1hr/day',
      'instructor': 'Mr. Santos',
      'description': 'Learn the fundamentals of journalism and develop essential writing and reporting skills...',
      'tags': ['Journalism', 'Writing'],
      'rating': 4.5,
    },
  ];

  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Basics of Journalism',
      'publisher': 'Mr. J Perez',
      'price': '₱100/hr',
      'priceValue': 100,
      'tags': ['English', 'Filipino'],
      'experience': '2+',
      'rating': 4.8,
      'description': 'Description of the module goes here. We\'ll be showing two lines of description only...',
    },
    {
      'title': 'Introduction to Calculus',
      'publisher': 'Dr. Ricardo Dalisay',
      'price': '₱85/hr',
      'priceValue': 85,
      'tags': ['Math', 'Advanced'],
      'experience': '3+',
      'rating': 4.9,
      'description': 'Learn the fundamentals of calculus including limits, derivatives, and integrals with practical examples and exercises.',
    },
    {
      'title': 'English Grammar Essentials',
      'publisher': 'Prof. Elena Santos',
      'price': '₱75/hr',
      'priceValue': 75,
      'tags': ['English', 'Grammar'],
      'experience': '5+',
      'rating': 4.7,
      'description': 'Master essential grammar rules and improve your writing skills with this comprehensive module covering parts of speech, sentence structure, and more.',
    },
    {
      'title': 'Chemical Reactions and Equations',
      'publisher': 'Prof. Maria Reyes',
      'price': '₱90/hr',
      'priceValue': 90,
      'tags': ['Science', 'Chemistry'],
      'experience': '4+',
      'rating': 4.8,
      'description': 'Explore the world of chemical reactions, learn to balance equations, and understand reaction types with interactive examples.',
    },
    {
      'title': 'Python Data Structures',
      'publisher': 'Engr. Juan Dela Cruz',
      'price': '₱120/hr',
      'priceValue': 120,
      'tags': ['Programming', 'Computer Science'],
      'experience': '3+',
      'rating': 4.9,
      'description': 'Dive deep into Python data structures including lists, dictionaries, sets, and tuples with practical coding exercises and projects.',
    },
    {
      'title': 'Filipino Literature Classics',
      'publisher': 'Dr. Jose Rizal',
      'price': '₱65/hr',
      'priceValue': 65,
      'tags': ['Filipino', 'Literature'],
      'experience': '6+',
      'rating': 4.6,
      'description': 'Explore the rich tradition of Filipino literature through classic works, understanding cultural context and literary elements.',
    },
  ];

  // Filtered lists
  List<Map<String, dynamic>> _filteredTutors = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  List<Map<String, dynamic>> _filteredModules = [];

  @override
  void initState() {
    super.initState();
    // Initialize filtered lists
    _filteredTutors = List.from(_tutors);
    _filteredCourses = List.from(_courses);
    _filteredModules = List.from(_modules);
  }

  // Handle filter application
  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _activeFilters = filters;

      // Update selected mode if it changed
      if (filters.containsKey('mode')) {
        selectedMode = filters['mode'] as int;
      }

      // Apply filters based on selected mode
      if (selectedMode == 0) {
        // Filter tutors
        _filteredTutors = List.from(_tutors);

        // Apply category filter
        if (filters.containsKey('categories') &&
            filters['categories'] is List &&
            (filters['categories'] as List).isNotEmpty) {
          _filteredTutors = _filteredTutors.where((tutor) {
            return tutor['tags'].any((tag) =>
                (filters['categories'] as List).contains(tag));
          }).toList();
        }

        // Apply price range filter
        if (filters.containsKey('priceRange') && filters['priceRange'] is Map) {
          int minPrice = filters['priceRange']['min'] as int;
          int maxPrice = filters['priceRange']['max'] as int;

          _filteredTutors = _filteredTutors.where((tutor) {
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

        // Clear search field to avoid confusion
        _searchController.clear();
      } else if (selectedMode == 1) {
        // Filter courses
        _filteredCourses = List.from(_courses);

        // Apply category filter
        if (filters.containsKey('categories') &&
            filters['categories'] is List &&
            (filters['categories'] as List).isNotEmpty) {
          _filteredCourses = _filteredCourses.where((course) {
            return course['tags'].any((tag) =>
                (filters['categories'] as List).contains(tag));
          }).toList();
        }

        // Apply rating filter
        if (filters.containsKey('rating') && filters['rating'] is int) {
          int minRating = filters['rating'] as int;

          _filteredCourses = _filteredCourses.where((course) {
            double rating = course['rating'] as double;
            return rating >= minRating;
          }).toList();
        }

        // Clear search field to avoid confusion
        _searchController.clear();
      }
      // Module filtering can be added for mode 2
      else if (selectedMode == 2) {
        // Filter modules
        _filteredModules = List.from(_modules);

        // Apply category filter
        if (filters.containsKey('categories') &&
            filters['categories'] is List &&
            (filters['categories'] as List).isNotEmpty) {
          _filteredModules = _filteredModules.where((module) {
            return module['tags'].any((tag) =>
                (filters['categories'] as List).contains(tag));
          }).toList();
        }

        // Apply price range filter if available
        if (filters.containsKey('priceRange') && filters['priceRange'] is Map) {
          int minPrice = filters['priceRange']['min'] as int;
          int maxPrice = filters['priceRange']['max'] as int;

          _filteredModules = _filteredModules.where((module) {
            int price = module['priceValue'] as int;
            return price >= minPrice && price <= maxPrice;
          }).toList();
        }

        // Apply rating filter
        if (filters.containsKey('rating') && filters['rating'] is int) {
          int minRating = filters['rating'] as int;

          _filteredModules = _filteredModules.where((module) {
            double rating = module['rating'] as double;
            return rating >= minRating;
          }).toList();
        }

        // Clear search field
        _searchController.clear();
      }
    });
  }

  // Show filter dialog as bottom sheet
  void _showFilterDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations
          .of(context)
          .modalBarrierDismissLabel,
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
            initialMode: selectedMode,
          ),
        );
      },
    );
  }

  // Navigate to tutor profile
  void _navigateToTutorProfile(Map<String, dynamic> tutor) {
    // Implement navigation to tutor profile
    print('Navigate to profile for: ${tutor['name']}');
  }

  // Navigate to course details
  void _navigateToCourseDetails(Map<String, dynamic> course) {
    // Implement navigation to course details
    print('Navigate to course: ${course['title']}');
  }

  void _navigateToModuleDetails(Map<String, dynamic> module) {
    // Implement navigation to module details
    print('Navigate to module: ${module['title']}');
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
                text: TextSpan(
                  text: 'Find the ',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: selectedMode == 0
                          ? 'best tutor'
                          : selectedMode == 1
                          ? 'best course'
                          : 'best module',
                      style: const TextStyle(
                        color: Color(0xFF4DA6A6),
                      ),
                    ),
                    const TextSpan(text: '\njust for '),
                    const TextSpan(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                selectedMode == 0
                    ? 'Customize the search filter to find a tutor that match your needs.'
                    : selectedMode == 1
                    ? 'Customize the search filter to find a course that match your needs.'
                    : 'Customize the search filter to find a module that match your needs.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search bar and filter button
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
                                setState(() {
                                  if (value.isEmpty) {
                                    // If search is empty, show filtered items based on active filters
                                    _applyFilters(_activeFilters);
                                  } else {
                                    // Apply search filter based on selected mode
                                    if (selectedMode == 0) {
                                      // Search tutors
                                      _filteredTutors = _tutors.where((tutor) {
                                        bool matchesSearch = tutor['name']
                                            .toString()
                                            .toLowerCase()
                                            .contains(value.toLowerCase());

                                        // Apply other active filters
                                        bool matchesFilters = true;

                                        // Apply category filter if active
                                        if (_activeFilters.containsKey(
                                            'categories') &&
                                            _activeFilters['categories'] is List &&
                                            (_activeFilters['categories'] as List)
                                                .isNotEmpty) {
                                          matchesFilters =
                                              tutor['tags'].any((tag) =>
                                                  (_activeFilters['categories'] as List)
                                                      .contains(tag));
                                        }

                                        // Apply price filter if active
                                        if (matchesFilters &&
                                            _activeFilters.containsKey(
                                                'priceRange') &&
                                            _activeFilters['priceRange'] is Map) {
                                          int minPrice = _activeFilters['priceRange']['min'] as int;
                                          int maxPrice = _activeFilters['priceRange']['max'] as int;
                                          int price = tutor['priceValue'] as int;
                                          matchesFilters = price >= minPrice &&
                                              price <= maxPrice;
                                        }

                                        // Apply rating filter if active
                                        if (matchesFilters &&
                                            _activeFilters.containsKey(
                                                'rating') &&
                                            _activeFilters['rating'] is int) {
                                          matchesFilters = tutor['rating'] >=
                                              _activeFilters['rating'];
                                        }

                                        return matchesSearch && matchesFilters;
                                      }).toList();
                                    } else if (selectedMode == 1) {
                                      // Search courses
                                      _filteredCourses =
                                          _courses.where((course) {
                                            bool matchesSearch = course['title']
                                                .toString()
                                                .toLowerCase()
                                                .contains(
                                                value.toLowerCase()) ||
                                                course['instructor']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains(
                                                    value.toLowerCase());

                                            // Apply other active filters
                                            bool matchesFilters = true;

                                            // Apply category filter if active
                                            if (_activeFilters.containsKey(
                                                'categories') &&
                                                _activeFilters['categories'] is List &&
                                                (_activeFilters['categories'] as List)
                                                    .isNotEmpty) {
                                              matchesFilters =
                                                  course['tags'].any((tag) =>
                                                      (_activeFilters['categories'] as List)
                                                          .contains(tag));
                                            }

                                            // Apply rating filter if active
                                            if (matchesFilters &&
                                                _activeFilters.containsKey(
                                                    'rating') &&
                                                _activeFilters['rating'] is int) {
                                              matchesFilters =
                                                  course['rating'] >=
                                                      _activeFilters['rating'];
                                            }

                                            return matchesSearch &&
                                                matchesFilters;
                                          }).toList();
                                    }
                                    // Module search can be added for mode 2
                                    else if (selectedMode == 2) {
                                      // Search modules
                                      _filteredModules =
                                          _modules.where((module) {
                                            bool matchesSearch = module['title']
                                                .toString()
                                                .toLowerCase()
                                                .contains(
                                                value.toLowerCase()) ||
                                                module['publisher']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains(
                                                    value.toLowerCase());

                                            // Apply other active filters
                                            bool matchesFilters = true;

                                            // Apply category filter if active
                                            if (_activeFilters.containsKey(
                                                'categories') &&
                                                _activeFilters['categories'] is List &&
                                                (_activeFilters['categories'] as List)
                                                    .isNotEmpty) {
                                              matchesFilters =
                                                  module['tags'].any((tag) =>
                                                      (_activeFilters['categories'] as List)
                                                          .contains(tag));
                                            }

                                            // Apply price filter if active
                                            if (matchesFilters &&
                                                _activeFilters.containsKey(
                                                    'priceRange') &&
                                                _activeFilters['priceRange'] is Map) {
                                              int minPrice = _activeFilters['priceRange']['min'] as int;
                                              int maxPrice = _activeFilters['priceRange']['max'] as int;
                                              int price = module['priceValue'] as int;
                                              matchesFilters =
                                                  price >= minPrice &&
                                                      price <= maxPrice;
                                            }

                                            // Apply rating filter if active
                                            if (matchesFilters &&
                                                _activeFilters.containsKey(
                                                    'rating') &&
                                                _activeFilters['rating'] is int) {
                                              matchesFilters =
                                                  module['rating'] >=
                                                      _activeFilters['rating'];
                                            }

                                            return matchesSearch &&
                                                matchesFilters;
                                          }).toList();
                                    }
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

            // Current mode indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F2F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Searching: ${_searchModeLabels[selectedMode]}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4DA6A6),
                  ),
                ),
              ),
            ),

            // Filter badges (only show when filters are active)
            if (_activeFilters.containsKey('categories') &&
                _activeFilters['categories'] is List &&
                (_activeFilters['categories'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_activeFilters['categories'] as List).map<Widget>((
                      category) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          // Remove this category from filters
                          List categories = List.from(
                              _activeFilters['categories']);
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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

            const SizedBox(height: 10),

            // Results List - show based on selected mode
            Expanded(
              child: selectedMode == 0
                  ? _buildTutorsList()
                  : selectedMode == 1
                  ? _buildCoursesList()
                  : _buildModulesList(),
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

          // Navigation logic
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/studenthome');
              break;
            case 1:
            // Already on Search page
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/courses');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: _navItems,
        selectedColor: const Color(0xFFF7941D),
        unselectedColor: Colors.grey,
        backgroundColor: Colors.black,
      ),
    );
  }

  // Build tutors list
  Widget _buildTutorsList() {
    return _filteredTutors.isEmpty
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
    );
  }

  // Build courses list
  Widget _buildCoursesList() {
    return _filteredCourses.isEmpty
        ? const Center(
      child: Text(
        'No courses match your filters',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return CourseCard(
          course: course,
          onViewCourse: () => _navigateToCourseDetails(course),
        );
      },
    );
  }

  Widget _buildModulesList() {
    return _filteredModules.isEmpty
        ? const Center(
      child: Text(
        'No modules match your filters',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredModules.length,
      itemBuilder: (context, index) {
        final module = _filteredModules[index];
        return ModuleCard(
          module: module,
          onPreviewModule: () => _previewModule(module),
        );
      },
    );
  }

  // Add a method to handle module preview
  void _previewModule(Map<String, dynamic> module) {
    // Implement preview functionality
    print('Preview module: ${module['title']}');

    // Show a snackbar indicating preview is in progress
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Previewing ${module['title']}...'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF4DA6A6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // You would typically navigate to a preview screen or open a modal
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ModulePreviewScreen(module: module)));
  }
}