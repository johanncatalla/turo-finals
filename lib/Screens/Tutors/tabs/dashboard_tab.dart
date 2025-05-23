import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/services/directus_service.dart';
import 'package:turo/Widgets/tutor_availability_manager.dart';

class DashboardTab extends StatefulWidget {
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

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final DirectusService _directusService = DirectusService();
  String? _tutorProfileId;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _fetchTutorProfileId();
  }

  Future<void> _fetchTutorProfileId() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null && user.isTutor) {
        // Fetch the tutor profile using the user's ID
        final response = await _directusService.fetchTutorProfileByUserId(user.id);
        
        if (response['success']) {
          final userData = response['data'];
          final tutorProfile = userData['tutor_profile'];
          
          if (tutorProfile != null) {
            String? profileId;
            
            // Handle different data structures - tutor_profile could be an object or a list
            if (tutorProfile is List && tutorProfile.isNotEmpty) {
              profileId = tutorProfile[0]['id']?.toString();
            } else if (tutorProfile is Map) {
              profileId = tutorProfile['id']?.toString();
            }
            
            if (profileId != null) {
              setState(() {
                _tutorProfileId = profileId;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching tutor profile ID: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

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
        color: widget.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: widget.shadowColor.withOpacity(0.05),
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
              Icon(icon, size: 30, color: iconColor ?? widget.secondaryTextColor),
            if (icon != null) const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.secondaryTextColor,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats section
          Row(
            children: [
              Expanded(
                child: _buildPlaceholderCard(
                  height: 120,
                  label: "Scheduled Classes\n(Placeholder)",
                  icon: Icons.calendar_today,
                  iconColor: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlaceholderCard(
                  height: 120,
                  label: "Overall Performance\n(Placeholder)",
                  icon: Icons.show_chart,
                  iconColor: widget.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Availability Management Section
          if (_isLoadingProfile) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.cardBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: widget.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Loading availability management...',
                      style: TextStyle(
                        color: widget.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else if (_tutorProfileId != null) ...[
            TutorAvailabilityManager(
              tutorProfileId: _tutorProfileId!,
              primaryColor: widget.primaryColor,
              secondaryTextColor: widget.secondaryTextColor,
              cardBackgroundColor: widget.cardBackgroundColor,
              shadowColor: widget.shadowColor,
              borderColor: widget.borderColor,
              onAvailabilityChanged: () {
                // Optional: Refresh any related data when availability changes
                print('Availability updated from dashboard');
              },
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Show message if tutor profile is not available
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.cardBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 48,
                    color: widget.secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Availability Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your tutor profile to set your availability.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchTutorProfileId,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Charts section (moved to bottom)
          Row(
            children: [
              Expanded(
                child: _buildPlaceholderCard(
                  height: 160,
                  label: "Earnings Chart\n(Placeholder)",
                  icon: Icons.monetization_on,
                  iconColor: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlaceholderCard(
                  height: 160,
                  label: "Time Spent Chart\n(Placeholder)",
                  icon: Icons.schedule,
                  iconColor: widget.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}