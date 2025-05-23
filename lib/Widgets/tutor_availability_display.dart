import 'package:flutter/material.dart';
import 'package:turo/services/directus_service.dart';

class TutorAvailabilityDisplay extends StatefulWidget {
  final String tutorProfileId;
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;
  final bool compact;

  const TutorAvailabilityDisplay({
    super.key,
    required this.tutorProfileId,
    this.primaryColor = const Color(0xFF53C6D9),
    this.secondaryTextColor = Colors.grey,
    this.cardBackgroundColor = Colors.white,
    this.shadowColor = Colors.grey,
    this.borderColor = Colors.grey,
    this.compact = false,
  });

  @override
  State<TutorAvailabilityDisplay> createState() => _TutorAvailabilityDisplayState();
}

class _TutorAvailabilityDisplayState extends State<TutorAvailabilityDisplay> {
  final DirectusService _directusService = DirectusService();
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  Future<void> _loadAvailabilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _directusService.fetchTutorAvailabilities(widget.tutorProfileId);
      
      if (response['success']) {
        setState(() {
          _availabilities = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load availability';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading availability: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        if (!widget.compact) ...[
          Row(
            children: [
              Icon(Icons.schedule, color: widget.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Availability',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Content
        if (_isLoading)
          _buildLoadingWidget()
        else if (_error != null)
          _buildErrorWidget()
        else if (_availabilities.isEmpty)
          _buildEmptyWidget()
        else
          _buildAvailabilityList(),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 16 : 32),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 16 : 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: widget.compact ? 32 : 48,
              color: widget.secondaryTextColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load availability',
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: widget.compact ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 16 : 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: widget.compact ? 32 : 48,
              color: widget.secondaryTextColor,
            ),
            const SizedBox(height: 8),
            Text(
              'No availability set',
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: widget.compact ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!widget.compact) ...[
              const SizedBox(height: 4),
              Text(
                'This tutor hasn\'t set their availability yet.',
                style: TextStyle(
                  color: widget.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityList() {
    // Group availabilities by recurring vs specific dates
    final recurringAvailabilities = _availabilities.where((a) => a['recurring'] == true).toList();
    final specificDateAvailabilities = _availabilities.where((a) => a['recurring'] == false).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recurring schedule
        if (recurringAvailabilities.isNotEmpty) ...[
          if (!widget.compact) ...[
            Text(
              'Weekly Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.compact)
            _buildCompactSchedule(recurringAvailabilities)
          else
            _buildDetailedSchedule(recurringAvailabilities),
          
          if (specificDateAvailabilities.isNotEmpty && !widget.compact)
            const SizedBox(height: 24),
        ],

        // Specific dates
        if (specificDateAvailabilities.isNotEmpty && !widget.compact) ...[
          Text(
            'Special Dates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecificDates(specificDateAvailabilities),
        ],
      ],
    );
  }

  Widget _buildCompactSchedule(List<Map<String, dynamic>> availabilities) {
    // Group by time slots
    Map<String, List<String>> timeSlots = {};
    
    for (var availability in availabilities) {
      final startTime = availability['start_time']?.substring(0, 5) ?? '';
      final endTime = availability['end_time']?.substring(0, 5) ?? '';
      final timeSlot = '$startTime - $endTime';
      
      if (availability['day_of_week'] is List) {
        final days = List<String>.from(availability['day_of_week']);
        if (!timeSlots.containsKey(timeSlot)) {
          timeSlots[timeSlot] = [];
        }
        timeSlots[timeSlot]!.addAll(days);
      }
    }

    return Column(
      children: timeSlots.entries.map((entry) {
        final timeSlot = entry.key;
        final days = entry.value.toSet().toList(); // Remove duplicates
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.borderColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16, color: widget.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeSlot,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days.map((day) => day.substring(0, 3)).join(', '),
                      style: TextStyle(
                        color: widget.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedSchedule(List<Map<String, dynamic>> availabilities) {
    return Column(
      children: availabilities.map((availability) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Days
              if (availability['day_of_week'] is List)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (availability['day_of_week'] as List)
                      .map((day) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.primaryColor,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 12),
              
              // Time
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: widget.secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    '${availability['start_time']?.substring(0, 5) ?? ''} - ${availability['end_time']?.substring(0, 5) ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Recurring indicator
              Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: widget.secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly recurring',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecificDates(List<Map<String, dynamic>> availabilities) {
    return Column(
      children: availabilities.map((availability) {
        final specificDate = availability['specific_date'];
        DateTime? date;
        if (specificDate != null) {
          try {
            date = DateTime.parse(specificDate);
          } catch (e) {
            // Handle parsing error
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: widget.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    date != null 
                      ? '${date.day}/${date.month}/${date.year}'
                      : specificDate ?? 'Date not specified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Time
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: widget.secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    '${availability['start_time']?.substring(0, 5) ?? ''} - ${availability['end_time']?.substring(0, 5) ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // One-time indicator
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: widget.secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    'One-time availability',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 