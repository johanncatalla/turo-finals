// lib/Widgets/module_card.dart

import 'package:flutter/material.dart';

class ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;
  final VoidCallback? onPreviewModule;

  const ModuleCard({
    Key? key,
    required this.module,
    this.onPreviewModule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add null safety for all fields
    final String title = module['title'] ?? 'Untitled Module';
    final String publisher = module['publisher'] ?? 'Unknown Publisher';
    final String price = module['price'] ?? '₱0';
    final List<dynamic> tags = module['tags'] ?? [];
    final String experience = module['experience'] ?? '';
    final double rating = (module['rating'] ?? 0.0).toDouble();
    final String description = module['description'] ?? 'No description available.';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Module Title
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Price
              Text(
                price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF7941D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Author Row
          Row(
            children: [
              const Icon(
                Icons.person,
                color: Color(0xFF4DA6A6),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                publisher,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tags and Rating Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Tags
                ...List.generate(
                  tags.length > 2 ? 2 : tags.length,
                      (i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tags[i].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4DA6A6),
                      ),
                    ),
                  ),
                ),

                // Experience tag (if available)
                if (experience.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      experience,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4DA6A6),
                      ),
                    ),
                  ),

                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFF7941D),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF7941D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Preview Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onPreviewModule,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE6F4F1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Preview Module',
                style: TextStyle(
                  color: Color(0xFF4DA6A6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}