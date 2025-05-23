import 'package:flutter/material.dart';
// Import CreateModuleScreen if/when it exists
// import 'package:turo/Screens/Tutors/tutor_createmodule.dart';

class ModulesTab extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;

  const ModulesTab({
    super.key,
    required this.primaryColor,
    required this.secondaryTextColor,
    required this.cardBackgroundColor,
    required this.shadowColor,
    required this.borderColor,
  });

  Widget _buildModuleCard({required String title, required String tags}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  tags,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.grey.shade600,
            size: 24,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: [
          _buildModuleCard(
            title: "Photosynthetic Process In Plants",
            tags: "Science | Biology | Highschool",
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            title: "Advanced Algebra Techniques",
            tags: "Math | Algebra | University",
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement navigation to CreateModuleScreen
              /*
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateModuleScreen(), // Ensure this screen exists
                ),
              );
              */
              // print("Create Module button tapped");
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
              'Create Module',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}