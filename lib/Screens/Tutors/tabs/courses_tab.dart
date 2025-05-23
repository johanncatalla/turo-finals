// courses_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/Screens/Tutors/tutor_createcourse.dart';
import 'package:turo/providers/course_provider.dart';
// --- IMPORT THE EDIT COURSE SCREEN ---
import 'package:turo/Screens/Tutors/EditCourseScreen.dart'; // Adjust path if necessary

class CoursesTab extends StatelessWidget {
  final bool isLoading;
  final String? coursesError;
  final List<Map<String, dynamic>> courses;
  final String tutorName; // Used as fallback for instructor name
  final VoidCallback onRetryFetchCourses;
  final VoidCallback onRefreshCourses;
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
    required BuildContext context,
    // --- ADD courseId ---
    required String courseId,
    // --- ---
    String? imagePath,
    required bool isNetworkImage,
    required bool isLocalAsset,
    required String fallbackImageAsset,
    required String title,
    required String time,
    required String instructor,
    required String description,
  }) {
    Widget imageWidget;

    if (isNetworkImage && imagePath != null && imagePath.isNotEmpty) {
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
          return Image.asset(
            fallbackImageAsset,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          );
        },
      );
    } else if (isLocalAsset && imagePath != null && imagePath.isNotEmpty) {
      imageWidget = Image.asset(
        imagePath,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            fallbackImageAsset,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      imageWidget = Image.asset(
          fallbackImageAsset,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(width: 90, height: 90, color: Colors.grey.shade300, child: Icon(Icons.broken_image, color: Colors.grey.shade600));
          }
      );
    }

    // --- WRAP WITH INKWELL FOR TAP EFFECT AND NAVIGATION ---
    return InkWell(
      onTap: () async {
        // Ensure courseId is valid before navigating
        if (courseId == "INVALID_ID" || courseId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot edit course: Invalid ID.'), backgroundColor: Colors.orange)
          );
          return;
        }
        // Navigate to EditCourseScreen, passing the courseId
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EditCourseScreen(courseId: courseId),
          ),
        );
        // If the EditCourseScreen pops with true, it means changes were saved.
        // So, refresh the course list.
        if (result == true) {
          onRefreshCourses(); // Call the callback to refresh courses
        }
      },
      borderRadius: BorderRadius.circular(15), // For ink splash effect
      child: Container(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    final createCourseButton = ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateCourseScreen(),
          ),
        ).then((result) {
          // If result is true (course created) or null (navigated back without explicit result but might have created)
          // It's generally safer to refresh if result is not explicitly false.
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
        'Create New Course',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    if (isLoading && courses.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
    }

    if (coursesError != null && courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 50),
            const SizedBox(height: 16),
            Text('Error loading courses: $coursesError', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetryFetchCourses, child: const Text("Retry")),
            const SizedBox(height: 20),
            createCourseButton,
          ],
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
            const SizedBox(height: 30),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Column(
        children: [
          if (coursesError != null && courses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Couldn't refresh courses: $coursesError",
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, size: 20, color: Colors.orange.shade700),
                      onPressed: onRetryFetchCourses,
                      tooltip: "Retry",
                    )
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

              final String? courseId = course['id']?.toString();

              String courseTitle = course['title'] as String? ?? 'Untitled Course';
              String courseDescription = course['description'] as String? ?? 'No description available.';
              String courseDuration = course['duration'] as String? ?? "N/A"; // Assuming duration is a direct field

              // Determine image path and type
              // Check for 'course_image' first, then 'image' as a fallback
              dynamic imageFieldData = course['course_image'] ?? course['image'];
              String? imageIdentifier;

              if (imageFieldData is Map && imageFieldData.containsKey('id')) {
                imageIdentifier = imageFieldData['id']?.toString();
              } else if (imageFieldData is String) {
                imageIdentifier = imageFieldData;
              }

              String? finalImagePath;
              bool isDeterminedAsNetworkImage = false;
              bool isDeterminedAsLocalAsset = false;

              if (imageIdentifier != null && imageIdentifier.isNotEmpty) {
                if (imageIdentifier.startsWith('assets/')) {
                  finalImagePath = imageIdentifier;
                  isDeterminedAsLocalAsset = true;
                } else if (Uri.tryParse(imageIdentifier)?.isAbsolute ?? false) {
                  // If it's an absolute URL already (less likely for an ID)
                  finalImagePath = imageIdentifier;
                  isDeterminedAsNetworkImage = true;
                } else {
                  // Assume it's an ID that needs to be converted to a URL by the provider/service
                  finalImagePath = courseProvider.getAssetUrl(imageIdentifier); // Uses DirectusService.getAssetUrl
                  if (finalImagePath != null && finalImagePath.isNotEmpty) {
                    isDeterminedAsNetworkImage = true;
                  }
                }
              }

              String instructor = course['instructorName'] as String? ?? tutorName;
              String fallbackAsset = 'assets/courses/python.png'; // Default fallback

              if (courseId == null || courseId.isEmpty) {
                // print("Warning: Course at index $index has no valid ID. Displaying as non-editable.");
                // Build the card but the onTap for editing might not work or show a message.
                // We pass a placeholder ID or an empty string which the onTap handler in _buildCourseCard will check.
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildCourseCard(
                    context: context,
                    courseId: "INVALID_ID", // Signifies it shouldn't navigate
                    imagePath: finalImagePath,
                    isNetworkImage: isDeterminedAsNetworkImage,
                    isLocalAsset: isDeterminedAsLocalAsset,
                    fallbackImageAsset: fallbackAsset,
                    title: "$courseTitle (Cannot Edit)",
                    time: courseDuration,
                    instructor: instructor,
                    description: courseDescription,
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildCourseCard(
                  context: context,
                  courseId: courseId,
                  imagePath: finalImagePath,
                  isNetworkImage: isDeterminedAsNetworkImage,
                  isLocalAsset: isDeterminedAsLocalAsset,
                  fallbackImageAsset: fallbackAsset,
                  title: courseTitle,
                  time: courseDuration,
                  instructor: instructor,
                  description: courseDescription,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: createCourseButton,
          ),
        ],
      ),
    );
  }
}