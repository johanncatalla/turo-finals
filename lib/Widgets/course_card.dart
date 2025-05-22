import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/course_provider.dart';

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback? onViewCourse;

  const CourseCard({
    Key? key,
    required this.course,
    this.onViewCourse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    
    return GestureDetector(
      onTap: onViewCourse,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: course['image'] != null && !course['image'].toString().startsWith('assets/')
                    ? Image.network(
                        courseProvider.getAssetUrl(course['image']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset('assets/courses/python.png', fit: BoxFit.cover);
                        },
                      )
                    : Image.asset(
                        'assets/courses/python.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 15),

            // Course details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course title
                  Text(
                    course['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // Course schedule and instructor
                  Row(
                    children: [
                      _buildScheduleInfo(),
                      const SizedBox(width: 10),
                      _buildInstructorInfo(),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Course description
                  Text(
                    course['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Schedule info (clock icon + hours per day)
  Widget _buildScheduleInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.schedule,
          color: Color(0xFF4DA6A6),
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          course['duration'] ?? '1hr/day',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Instructor info (person icon + instructor name)
  Widget _buildInstructorInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person_outline,
          color: Color(0xFF4DA6A6),
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          course['instructorName'] ?? 'Instructor',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}