import 'package:flutter/material.dart';

class VideosTab extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;

  const VideosTab({
    super.key,
    required this.primaryColor,
    required this.secondaryTextColor,
    required this.cardBackgroundColor,
    required this.shadowColor,
    required this.borderColor,
  });

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor:
          isPrimary ? primaryColor.withOpacity(0.1) : Colors.grey.shade200,
          foregroundColor: isPrimary ? primaryColor : Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildVideoCard({
    required String thumbnailAsset, // Ensure this asset exists
    required String title,
    required String views,
    required String comments,
    required String earnings,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(
                  thumbnailAsset,
                  width: 100,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100, height: 75, color: Colors.grey.shade300,
                    child: Icon(Icons.videocam_off_outlined, color: Colors.grey.shade600),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Icon(Icons.play_circle_outline_rounded, color: Colors.white.withOpacity(0.8), size: 30),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$views   $comments",
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
                Text(
                  earnings,
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildActionButton(label: "Edit", onPressed: () {}),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: "Boost",
                      onPressed: () {},
                      isPrimary: true,
                    ),
                  ],
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildVideoCard(
            thumbnailAsset: 'assets/journalism_video.png', // Make sure this asset exists
            title: "What is Journalism",
            views: "20.6k Views",
            comments: "5000 Comments",
            earnings: "12.3k Pesos",
          ),
          const SizedBox(height: 16),
          _buildVideoCard(
            thumbnailAsset: 'assets/journalism_video.png', // Make sure this asset exists
            title: "The Art of Storytelling",
            views: "15.2k Views",
            comments: "3200 Comments",
            earnings: "9.8k Pesos",
          ),
        ],
      ),
    );
  }
}