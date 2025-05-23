import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/services/directus_service.dart';

class TutorBookingWidget extends StatefulWidget {
  final String tutorUserId;
  final String? tutorProfileId;
  final String? preSelectedCourseId;
  final String tutorName;
  final double? hourlyRate;
  final List<Map<String, dynamic>>? availableCourses;
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;
  final VoidCallback? onBookingComplete;

  const TutorBookingWidget({
    super.key,
    required this.tutorUserId,
    this.tutorProfileId,
    this.preSelectedCourseId,
    required this.tutorName,
    this.hourlyRate,
    this.availableCourses,
    this.primaryColor = const Color(0xFF53C6D9),
    this.secondaryTextColor = Colors.grey,
    this.cardBackgroundColor = Colors.white,
    this.shadowColor = Colors.grey,
    this.borderColor = Colors.grey,
    this.onBookingComplete,
  });

  @override
  State<TutorBookingWidget> createState() => _TutorBookingWidgetState();
}

class _TutorBookingWidgetState extends State<TutorBookingWidget> {
  final DirectusService _directusService = DirectusService();
  
  // Booking form state
  String? _selectedCourseId;
  String _selectedMode = 'Online';
  final List<String> _selectedScheduleDays = [];
  final List<Map<String, dynamic>> _selectedTimeSlots = [];
  int _totalHours = 1;
  
  // Calendar state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Time selection state
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  
  // Availability data
  List<Map<String, dynamic>> _tutorAvailability = [];
  bool _isLoadingAvailability = false;
  String? _availabilityError;
  
  // Booking process state
  bool _isBooking = false;
  String? _bookingError;
  
  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  final List<String> _modes = ['Online', 'In-person'];

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.preSelectedCourseId;
    if (widget.tutorProfileId != null) {
      _loadTutorAvailability();
    }
  }

  Future<void> _loadTutorAvailability() async {
    print('Loading tutor availability for tutorProfileId: ${widget.tutorProfileId}');
    setState(() {
      _isLoadingAvailability = true;
      _availabilityError = null;
    });

    try {
      final response = await _directusService.fetchTutorAvailabilities(widget.tutorProfileId!);
      print('Availability response: ${response.toString()}');
      
      if (response['success']) {
        final availabilityData = List<Map<String, dynamic>>.from(response['data'] ?? []);
        print('🎯 Loaded ${availabilityData.length} availability records for tutor ${widget.tutorProfileId}:');
        for (int i = 0; i < availabilityData.length; i++) {
          final record = availabilityData[i];
          print('   Record ${i + 1}: ${record['recurring'] == true ? 'Recurring' : 'One-time'}');
          print('     Days: ${record['day_of_week']} (${record['day_of_week'].runtimeType})');
          print('     Time: ${record['start_time']} - ${record['end_time']}');
          if (record['specific_date'] != null) {
            print('     Specific Date: ${record['specific_date']}');
          }
          print('');
        }
        
        setState(() {
          _tutorAvailability = availabilityData;
          _isLoadingAvailability = false;
        });
        
        // Force calendar rebuild by triggering a small state change
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              // Small state change to force calendar refresh
              _focusedDay = _focusedDay;
            });
          }
        });
      } else {
        print('Failed to load availability: ${response['message']}');
        setState(() {
          _availabilityError = response['message'] ?? 'Failed to load availability';
          _isLoadingAvailability = false;
        });
      }
    } catch (e) {
      print('Exception loading availability: $e');
      setState(() {
        _availabilityError = 'Error loading availability: ${e.toString()}';
        _isLoadingAvailability = false;
      });
    }
  }

  bool _isTimeSlotAvailable(DateTime date, TimeOfDay startTime, TimeOfDay endTime) {
    if (_tutorAvailability.isEmpty) return false;
    
    final dayName = _getDayName(date.weekday);
    
    for (var availability in _tutorAvailability) {
      final availableDays = availability['day_of_week'];
      final isRecurring = availability['recurring'] == true;
      
      bool isDayAvailable = false;
      
      // Check recurring availability
      if (isRecurring && availableDays != null) {
        // Handle both List and String formats
        List<String> daysList = [];
        
        if (availableDays is List) {
          daysList = List<String>.from(availableDays);
        } else if (availableDays is String) {
          // Handle comma-separated string or JSON array string
          try {
            if (availableDays.startsWith('[')) {
              // JSON array format
              final decoded = availableDays.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
              daysList = decoded.split(',').map((s) => s.trim()).toList();
            } else {
              // Comma-separated format
              daysList = availableDays.split(',').map((s) => s.trim()).toList();
            }
          } catch (e) {
            print('Error parsing day_of_week string in time slot validation: $e');
            continue;
          }
        }
        
        isDayAvailable = daysList.contains(dayName);
      }
      
      // Check specific date availability (independent of recurring check)
      if (!isRecurring && availability['specific_date'] != null) {
        try {
          final specificDate = DateTime.parse(availability['specific_date']);
          isDayAvailable = isSameDay(date, specificDate);
        } catch (e) {
          continue;
        }
      }
      
      if (isDayAvailable) {
        final availStartTime = _parseTimeFromString(availability['start_time']);
        final availEndTime = _parseTimeFromString(availability['end_time']);
        
        if (availStartTime != null && availEndTime != null) {
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;
          final availStartMinutes = availStartTime.hour * 60 + availStartTime.minute;
          final availEndMinutes = availEndTime.hour * 60 + availEndTime.minute;
          
          if (startMinutes >= availStartMinutes && endMinutes <= availEndMinutes) {
            return true;
          }
        }
      }
    }
    
    return false;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  TimeOfDay? _parseTimeFromString(String? timeString) {
    if (timeString == null) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    
    return null;
  }

  void _addTimeSlot() {
    if (_selectedDay == null || _selectedStartTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date, start time, and end time')),
      );
      return;
    }

    if (!_isTimeSlotAvailable(_selectedDay!, _selectedStartTime!, _selectedEndTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected time slot is not available')),
      );
      return;
    }

    final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final newSlot = {
      'date': _selectedDay!.toIso8601String().split('T')[0],
      'start_time': '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}:00',
      'duration': (endMinutes - startMinutes) / 60,
    };

    setState(() {
      _selectedTimeSlots.add(newSlot);
      _totalHours = _selectedTimeSlots.fold(0, (sum, slot) => sum + (slot['duration'] as double).ceil());
      _selectedStartTime = null;
      _selectedEndTime = null;
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _selectedTimeSlots.removeAt(index);
      _totalHours = _selectedTimeSlots.fold(0, (sum, slot) => sum + (slot['duration'] as double).ceil());
    });
  }

  double get _totalCost {
    final rate = widget.hourlyRate ?? 100.0;
    return _totalHours * rate;
  }

  Future<void> _createBooking() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a session')),
      );
      return;
    }

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course')),
      );
      return;
    }

    if (_selectedTimeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one time slot')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
      _bookingError = null;
    });

    try {
      // Create the booking
      final bookingResponse = await _directusService.createBooking(
        clientId: currentUser.id,
        tutorId: widget.tutorUserId,
        courseId: _selectedCourseId!,
        schedule: _selectedScheduleDays,
        mode: _selectedMode,
        totalHours: _totalHours,
        totalCost: _totalCost,
      );

      if (!bookingResponse['success']) {
        throw Exception(bookingResponse['message'] ?? 'Failed to create booking');
      }

      final bookingId = bookingResponse['data']['id'].toString();

      // Create chosen dates
      final datesResponse = await _directusService.createChosenDates(
        bookingId: bookingId,
        dateTimeSlots: _selectedTimeSlots,
      );

      if (!datesResponse['success']) {
        // If dates creation failed, we should ideally delete the booking
        await _directusService.deleteBooking(bookingId);
        throw Exception(datesResponse['message'] ?? 'Failed to create booking dates');
      }

      // Success!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _selectedTimeSlots.clear();
        _totalHours = 1;
        _selectedDay = null;
        _selectedStartTime = null;
        _selectedEndTime = null;
        _isBooking = false;
      });

      widget.onBookingComplete?.call();

    } catch (e) {
      setState(() {
        _bookingError = e.toString();
        _isBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isDayAvailable(DateTime day) {
    // Basic checks: not in the past
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    
    // If still loading, don't enable any days
    if (_isLoadingAvailability) {
      return false;
    }
    
    // If no tutorProfileId provided, enable all future days as fallback
    if (widget.tutorProfileId == null) {
      print('⚠️ No tutorProfileId provided, enabling all future days as fallback');
      return true;
    }
    
    // If no availability data and not loading, show error and enable all future days as fallback
    if (_tutorAvailability.isEmpty && !_isLoadingAvailability) {
      print('⚠️ No availability data found. Tutor availability count: ${_tutorAvailability.length}');
      print('TutorProfileId: ${widget.tutorProfileId}');
      print('Enabling all future days as fallback');
      return true; // Temporary fallback - enable all future days
    }
    
    final dayName = _getDayName(day.weekday);
    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    
    print('\n🔍 CHECKING AVAILABILITY for $dayName ($dateStr)');
    print('📊 Total availability records: ${_tutorAvailability.length}');
    
    // Check ALL availability records for this day - don't return early
    for (int i = 0; i < _tutorAvailability.length; i++) {
      final availability = _tutorAvailability[i];
      print('\n   📋 Record ${i + 1}/${_tutorAvailability.length}:');
      print('      - Type: ${availability['recurring'] == true ? 'Recurring' : 'One-time'}');
      print('      - Days: ${availability['day_of_week']} (${availability['day_of_week'].runtimeType})');
      print('      - Time: ${availability['start_time']} - ${availability['end_time']}');
      print('      - Specific Date: ${availability['specific_date']}');
      
      final availableDays = availability['day_of_week'];
      final isRecurring = availability['recurring'] == true;
      
      // Check recurring availability
      if (isRecurring && availableDays != null) {
        print('      🔄 Checking recurring availability...');
        
        // Handle both List and String formats
        List<String> daysList = [];
        
        if (availableDays is List) {
          daysList = List<String>.from(availableDays);
          print('         ✓ Parsed as List: $daysList');
        } else if (availableDays is String) {
          // Handle comma-separated string or JSON array string
          try {
            if (availableDays.startsWith('[')) {
              // JSON array format
              final decoded = availableDays.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
              daysList = decoded.split(',').map((s) => s.trim()).toList();
              print('         ✓ Parsed as JSON array string: $daysList');
            } else {
              // Comma-separated format
              daysList = availableDays.split(',').map((s) => s.trim()).toList();
              print('         ✓ Parsed as comma-separated string: $daysList');
            }
          } catch (e) {
            print('         ❌ Error parsing day_of_week string: $e');
            continue;
          }
        }
        
        print('         🎯 Looking for "$dayName" in: $daysList');
        if (daysList.contains(dayName)) {
          print('         ✅ MATCH FOUND! $dayName is available (recurring)');
          return true; // Found a match, day is available
        } else {
          print('         ❌ No match for $dayName in recurring days');
        }
      }
      
      // Check specific date availability (independent of recurring check)
      if (!isRecurring && availability['specific_date'] != null) {
        print('      📅 Checking specific date availability...');
        try {
          final specificDate = DateTime.parse(availability['specific_date']);
          final specificDateStr = '${specificDate.year}-${specificDate.month.toString().padLeft(2, '0')}-${specificDate.day.toString().padLeft(2, '0')}';
          print('         🎯 Comparing $dateStr with $specificDateStr');
          
          if (isSameDay(day, specificDate)) {
            print('         ✅ MATCH FOUND! Date is available (specific date)');
            return true; // Found a match, day is available
          } else {
            print('         ❌ No match for specific date');
          }
        } catch (e) {
          print('         ❌ Error parsing specific_date: $e');
          continue;
        }
      }
    }
    
    print('   🚫 RESULT: $dayName ($dateStr) is NOT available');
    return false;
  }

  List<Map<String, TimeOfDay>> _getAvailableTimeSlotsForDay(DateTime day) {
    final dayName = _getDayName(day.weekday);
    final availableSlots = <Map<String, TimeOfDay>>[];
    
    for (var availability in _tutorAvailability) {
      final availableDays = availability['day_of_week'];
      final isRecurring = availability['recurring'] == true;
      bool isDayAvailable = false;
      
      // Check recurring availability
      if (isRecurring && availableDays != null) {
        // Handle both List and String formats
        List<String> daysList = [];
        
        if (availableDays is List) {
          daysList = List<String>.from(availableDays);
        } else if (availableDays is String) {
          // Handle comma-separated string or JSON array string
          try {
            if (availableDays.startsWith('[')) {
              // JSON array format
              final decoded = availableDays.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
              daysList = decoded.split(',').map((s) => s.trim()).toList();
            } else {
              // Comma-separated format
              daysList = availableDays.split(',').map((s) => s.trim()).toList();
            }
          } catch (e) {
            print('Error parsing day_of_week string in time slots: $e');
            continue;
          }
        }
        
        isDayAvailable = daysList.contains(dayName);
      }
      
      // Check specific date availability
      if (!isRecurring && availability['specific_date'] != null) {
        try {
          final specificDate = DateTime.parse(availability['specific_date']);
          isDayAvailable = isSameDay(day, specificDate);
        } catch (e) {
          continue;
        }
      }
      
      // If this availability record matches the day, add the time slot
      if (isDayAvailable) {
        final startTime = _parseTimeFromString(availability['start_time']);
        final endTime = _parseTimeFromString(availability['end_time']);
        
        if (startTime != null && endTime != null) {
          availableSlots.add({
            'start': startTime,
            'end': endTime,
          });
        }
      }
    }
    
    return availableSlots;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Book a Session with ${widget.tutorName}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.primaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Course Selection
        if (widget.availableCourses != null) ...[
          Text(
            'Select Course',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          
          if (widget.availableCourses!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: widget.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCourseId,
                  hint: const Text('Choose a course'),
                  isExpanded: true,
                  items: widget.availableCourses!.map((course) {
                    return DropdownMenuItem<String>(
                      value: course['id'].toString(),
                      child: Text(course['title'] ?? 'Unknown Course'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                    });
                  },
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This tutor has no courses available for booking at the moment.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],

        // Mode Selection
        Text(
          'Session Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _modes.map((mode) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: RadioListTile<String>(
                  title: Text(mode),
                  value: mode,
                  groupValue: _selectedMode,
                  onChanged: (value) {
                    setState(() {
                      _selectedMode = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: widget.primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Calendar and Time Selection
        Text(
          'Select Dates and Times',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.secondaryTextColor,
          ),
        ),
        if (_isLoadingAvailability) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: widget.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading tutor availability...',
                  style: TextStyle(color: widget.primaryColor),
                ),
              ],
            ),
          ),
        ] else if (_availabilityError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _availabilityError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_tutorAvailability.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Only available dates are selectable in the calendar',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Calendar
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TableCalendar<String>(
            key: ValueKey('calendar_${_tutorAvailability.length}_${_isLoadingAvailability}'),
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            enabledDayPredicate: (day) => _isDayAvailable(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: widget.primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Time Selection
        if (_selectedDay != null) ...[
          Text(
            'Select Time for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          
          // Show available time slots for this day
          Builder(
            builder: (context) {
              final availableSlots = _getAvailableTimeSlotsForDay(_selectedDay!);
              if (availableSlots.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No availability found for this day',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Time Slots:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: availableSlots.map((slot) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${slot['start']!.format(context)} - ${slot['end']!.format(context)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setState(() => _selectedStartTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: widget.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedStartTime?.format(context) ?? 'Start time',
                          style: TextStyle(
                            color: _selectedStartTime != null ? Colors.black : widget.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedEndTime ?? const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (time != null) {
                      setState(() => _selectedEndTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: widget.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedEndTime?.format(context) ?? 'End time',
                          style: TextStyle(
                            color: _selectedEndTime != null ? Colors.black : widget.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addTimeSlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Selected Time Slots
        if (_selectedTimeSlots.isNotEmpty) ...[
          Text(
            'Selected Time Slots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_selectedTimeSlots.length, (index) {
            final slot = _selectedTimeSlots[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${slot['date']} | ${slot['start_time'].substring(0, 5)} - ${slot['end_time'].substring(0, 5)} (${slot['duration'].toStringAsFixed(1)}h)',
                      style: TextStyle(
                        color: widget.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTimeSlot(index),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Booking Summary
        if (_selectedTimeSlots.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.cardBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Hours:', style: TextStyle(color: widget.secondaryTextColor)),
                    Text('$_totalHours hours', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hourly Rate:', style: TextStyle(color: widget.secondaryTextColor)),
                    Text('₱${widget.hourlyRate?.toStringAsFixed(0) ?? '100'}/hr', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Cost:', style: TextStyle(fontSize: 16, color: widget.primaryColor, fontWeight: FontWeight.bold)),
                    Text('₱${_totalCost.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: widget.primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Book Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedTimeSlots.isNotEmpty && !_isBooking ? _createBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isBooking
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Book Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        // Error Message
        if (_bookingError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              _bookingError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }
} 