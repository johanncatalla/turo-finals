import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;

  const DashboardTab({
    super.key,
    required this.primaryColor,
    required this.secondaryTextColor,
    required this.cardBackgroundColor,
    required this.shadowColor,
    required this.borderColor,
  });

  Widget _buildPlaceholderCard({
    required double height,
    required String label,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 30, color: iconColor ?? secondaryTextColor),
            if (icon != null) const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPlaceholderCard(
                  height: 150,
                  label: "Scheduled Classes\n(Placeholder)",
                  icon: Icons.calendar_today,
                  iconColor: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlaceholderCard(
                  height: 150,
                  label: "Overall Performance\n(Placeholder)",
                  icon: Icons.show_chart,
                  iconColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPlaceholderCard(
                  height: 180,
                  label: "Earnings Chart\n(Placeholder)",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlaceholderCard(
                  height: 180,
                  label: "Time Spent Chart\n(Placeholder)",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}