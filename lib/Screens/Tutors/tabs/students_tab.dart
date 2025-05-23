import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/services/directus_service.dart';

class StudentsTab extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;

  const StudentsTab({
    super.key,
    required this.primaryColor,
    required this.secondaryTextColor,
    required this.cardBackgroundColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final DirectusService _directusService = DirectusService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      if (currentUserId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await _directusService.getTutorStudents(currentUserId);

      if (response['success']) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _isLoading = false;
        });
        print('StudentsTab: Successfully loaded ${_students.length} students');
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load students';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading students: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Students',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: widget.primaryColor),
                onPressed: _loadStudents,
                tooltip: 'Refresh students list',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading students...',
                style: TextStyle(color: widget.secondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: widget.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.secondaryTextColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStudents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: widget.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No Students Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No students have enrolled in your courses yet.\nKeep creating great content to attract students!',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.secondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: widget.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Total Students: ${_students.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Students List - Fixed height container to avoid layout conflicts
        SizedBox(
          height: 400, // Fixed height for the students list
          child: ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              return _buildStudentCard(_students[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final firstName = student['first_name'] ?? '';
    final lastName = student['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = student['email'] ?? '';
    final enrolledCourses = List<Map<String, dynamic>>.from(student['enrolled_courses'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: widget.borderColor),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: widget.primaryColor.withOpacity(0.1),
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
            style: TextStyle(
              color: widget.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          fullName.isNotEmpty ? fullName : 'Student',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) ...[
              Text(
                email,
                style: TextStyle(
                  color: widget.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${enrolledCourses.length} course${enrolledCourses.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: widget.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          if (enrolledCourses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enrolled Courses:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...enrolledCourses.map((course) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.book,
                            size: 16,
                            color: widget.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course['title'] ?? 'Untitled Course',
                              style: TextStyle(
                                color: widget.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No courses enrolled',
                style: TextStyle(
                  color: widget.secondaryTextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 