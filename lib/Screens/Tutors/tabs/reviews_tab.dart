import 'package:flutter/material.dart';

class ReviewsTab extends StatelessWidget {
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;

  const ReviewsTab({
    super.key,
    required this.secondaryTextColor,
    required this.cardBackgroundColor,
    required this.shadowColor,
    required this.borderColor,
  });

  Widget _buildReviewCard({
    required String imageAsset, // Ensure this asset exists
    required String reviewerName,
    required String date,
    required String reviewText,
    required int rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(15.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.asset(
              imageAsset,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.person_pin_circle_outlined,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reviewerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reviewText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87.withOpacity(
                      0.85,
                    ),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    5,
                        (index) => Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber.shade600,
                      size: 18,
                    ),
                  ),
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
    // Wrap the Column with SingleChildScrollView
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // Optional: for a nice scroll effect
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Apply padding to the scrollable area
      child: Column(
        // mainAxisSize: MainAxisSize.min, // Can be useful for columns in scroll views
        children: [
          _buildReviewCard(
            imageAsset: 'assets/English.png', // Make sure this asset exists
            reviewerName: "John Leo Echevarria",
            date: "September 10, 2023",
            reviewText:
            "Excellent tutor! Adjusts his lesson to my level of understanding and provides a comfortable learning atmosphere in his class. 10/10 would recommend!",
            rating: 5,
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            imageAsset: 'assets/English.png', // Make sure this asset exists
            reviewerName: "Jane Doe",
            date: "August 25, 2023",
            reviewText:
            "Very knowledgeable and patient. The course material was well-structured. Looking forward to more sessions!",
            rating: 4,
          ),
          // If you add more reviews or a button, they will also be scrollable
        ],
      ),
    );
  }
}
