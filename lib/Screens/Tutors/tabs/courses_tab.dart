import 'package:flutter/material.dart';
import 'package:turo/Screens/Tutors/tutor_createcourse.dart'; // Import Create Course screen

class CoursesTab extends StatelessWidget {
  final bool isLoading;
  final String? coursesError;
  final List<Map<String, dynamic>> courses;
  final String? directusBaseUrl;
  final String tutorName; // For fallback instructor name
  final VoidCallback onRetryFetchCourses;
  final VoidCallback onRefreshCourses; // To call after creating a course
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;

  const CoursesTab({
    super.key,
    required this.isLoading,
    this.coursesError,
    required this.courses,
    this.directusBaseUrl,
    required this.tutorName,
    required this.onRetryFetchCourses,
    required this.onRefreshCourses,
    required this.primaryColor,
    required this.secondaryTextColor,
    required this.cardBackgroundColor,
    required this.shadowColor,
    required this.borderColor,
  });

  Widget _buildCourseCard({
    required BuildContext context, // Added context for navigation if needed from card
    String? imagePath,
    bool isNetworkImage = false,
    required String fallbackImageAsset,
    required String title,
    required String time,
    required String instructor,
    required String description,
  }) {
    Widget imageWidget;

    if (isNetworkImage && imagePath != null) {
      imageWidget = Image.network(
        imagePath,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 90,
            height: 90,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                strokeWidth: 2.0,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("Network image error: $error for path $imagePath");
          return Image.asset(
            fallbackImageAsset,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          );
        },
      );
    } else if (!isNetworkImage && imagePath != null) {
      imageWidget = Image.asset(
        imagePath,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          fallbackImageAsset,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    } else {
      imageWidget = Image.asset(
        fallbackImageAsset,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: imageWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        instructor,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor.withOpacity(0.9),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createCourseButton = ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateCourseScreen(),
          ),
        ).then((result) {
          if (result == true || result == null) {
            onRefreshCourses();
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor.withOpacity(0.1),
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Create Course',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    if (isLoading) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
    }

    if (coursesError != null && courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $coursesError', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onRetryFetchCourses, child: const Text("Retry")),
              const SizedBox(height: 20),
              createCourseButton,
            ],
          ),
        ),
      );
    }

    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "You haven't created any courses yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (coursesError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Last attempt to fetch failed: $coursesError",
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            createCourseButton,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (coursesError != null && courses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Couldn't refresh courses: $coursesError",
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.refresh, size: 18, color: Colors.orange.shade700), onPressed: onRetryFetchCourses)
                  ],
                ),
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              String? imageUrl;
              String courseTitle = course['title'] as String? ?? 'Untitled Course';
              String courseDescription = course['description'] as String? ?? 'No description available.';
              String courseDuration = course['duration'] as String? ?? "N/A";

              if (course['course_image'] != null && course['course_image'] is Map) {
                final imageObject = course['course_image'] as Map<String, dynamic>;
                final imageId = imageObject['id'] as String?;
                if (imageId != null && directusBaseUrl != null) {
                  imageUrl = '$directusBaseUrl/assets/$imageId';
                }
              }

              String instructor = tutorName; // Fallback
              if (course['tutor_id'] != null && course['tutor_id'] is Map) {
                final tutorObject = course['tutor_id'] as Map<String, dynamic>;
                if (tutorObject['user_id'] != null && tutorObject['user_id'] is Map) {
                  final userObject = tutorObject['user_id'] as Map<String, dynamic>;
                  String? firstName = userObject['first_name'] as String?;
                  String? lastName = userObject['last_name'] as String?;
                  if (firstName != null && firstName.isNotEmpty && lastName != null && lastName.isNotEmpty) {
                    instructor = '$firstName $lastName';
                  } else if (firstName != null && firstName.isNotEmpty) {
                    instructor = firstName;
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildCourseCard(
                  context: context,
                  imagePath: imageUrl,
                  isNetworkImage: imageUrl != null,
                  fallbackImageAsset: 'assets/English.png', // Ensure this asset exists
                  title: courseTitle,
                  time: courseDuration,
                  instructor: instructor,
                  description: courseDescription,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          createCourseButton,
        ],
      ),
    );
  }
}