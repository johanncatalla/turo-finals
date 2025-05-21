import 'package:flutter/material.dart';

class AllInstructorsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> instructors;

  const AllInstructorsScreen({Key? key, required this.instructors}) : super(key: key);

  @override
  _AllInstructorsScreenState createState() => _AllInstructorsScreenState();
}

class _AllInstructorsScreenState extends State<AllInstructorsScreen> {
  late List<Map<String, dynamic>> _filteredInstructors;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredInstructors = widget.instructors;
    _searchController.addListener(_filterInstructors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterInstructors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInstructors = widget.instructors;
      } else {
        _filteredInstructors = widget.instructors
            .where((instructor) => instructor['name'].toLowerCase().contains(query))
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
          'All Instructors',
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
                  hintText: 'Search instructors...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          // Instructors Grid
          Expanded(
            child: _filteredInstructors.isEmpty
                ? const Center(
                    child: Text('No instructors found', style: TextStyle(fontSize: 18)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredInstructors.length,
                    itemBuilder: (context, index) {
                      final instructor = _filteredInstructors[index];
                      return _buildInstructorCard(instructor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCard(Map<String, dynamic> instructor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                instructor['image'],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                instructor['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 