import 'package:flutter/material.dart';

class TutorCard extends StatelessWidget {
  final Map<String, dynamic> tutor;
  final VoidCallback? onViewProfile;

  const TutorCard({
    Key? key,
    required this.tutor,
    this.onViewProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tutor Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(tutor['image']),
                backgroundColor: Colors.grey.shade300,
                child: tutor['image'].startsWith('assets/')
                    ? null
                    : Icon(Icons.person, size: 30, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 15),

              // Tutor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tutor Name and Price
                    _buildNamePriceRow(),

                    // Tags, Experience, and Rating
                    _buildTagsRow(),

                    const SizedBox(height: 8),

                    // Bio
                    Text(
                      tutor['bio'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // View Profile Button
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: const Color(0xFFD8F2F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      onPressed: onViewProfile,
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          color: Color(0xFF4DA6A6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tutor name and price row
  Widget _buildNamePriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                tutor['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 5),
              if (tutor['verified'] == true)
                const Icon(
                  Icons.verified,
                  color: Color(0xFF4DA6A6),
                  size: 15,
                ),
            ],
          ),
        ),
        Text(
          tutor['price'],
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF7941D),
          ),
        ),
      ],
    );
  }

  // Tags, experience, and rating row
  Widget _buildTagsRow() {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        // Subject Tags
        ...List.generate(
          tutor['tags'].length,
              (i) => _buildTag(
            text: tutor['tags'][i],
            backgroundColor: const Color(0xFFD8F2F6),
            textColor: const Color(0xFF3F8E9B),
          ),
        ),

        // Experience Tag
        _buildTag(
          text: tutor['experience'],
          backgroundColor: const Color(0xFFD8F2F6),
          textColor: const Color(0xFF3F8E9B),
        ),

        // Rating Tag
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFAE6CC),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFFF7941D),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                tutor['rating'].toString(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build a tag
  Widget _buildTag({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}