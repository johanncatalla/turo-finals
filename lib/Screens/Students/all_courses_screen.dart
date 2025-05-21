import 'package:flutter/material.dart';

class AllCoursesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> courses;

  const AllCoursesScreen({Key? key, required this.courses}) : super(key: key);

  @override
  _AllCoursesScreenState createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  late List<Map<String, dynamic>> _filteredCourses;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCourses = widget.courses;
    _searchController.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCourses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = widget.courses;
      } else {
        _filteredCourses = widget.courses
            .where((course) =>
                course['title'].toLowerCase().contains(query) ||
                course['instructor'].toLowerCase().contains(query) ||
                course['description'].toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Courses',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search courses...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Category Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Hot'),
                _buildFilterChip('Programming'),
                _buildFilterChip('Language'),
                _buildFilterChip('Math'),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Courses List
          Expanded(
            child: _filteredCourses.isEmpty
                ? const Center(
                    child: Text('No courses found', style: TextStyle(fontSize: 18)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      return _buildCourseItem(course);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: label == 'All' ? Colors.orange : Colors.grey[200],
        labelStyle: TextStyle(
          color: label == 'All' ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                course['image'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Course details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.cyan[700]),
                      const SizedBox(width: 4),
                      Text(
                        course['duration'],
                        style: TextStyle(
                          color: Colors.cyan[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.person, size: 16, color: Colors.cyan[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course['instructor'],
                          style: TextStyle(
                            color: Colors.cyan[700],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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