// edit_course_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // << NEW: Import table_calendar
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/directus_service.dart';
// import '../Students/student_CourseSectionUI.dart'; // Keep if used, commented out for now

// Define primary color, similar to CreateCourseScreen for consistency
const Color primaryTeal = Color(0xFF4DB6AC);

class EditCourseScreen extends StatefulWidget {
  final String courseId;

  const EditCourseScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final DirectusService _directusService = DirectusService();
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // --- Availability State Variables (from CreateCourseScreen) ---
  final Set<String> _selectedDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime _calendarFocusedDay = DateTime.now();
  DateTime? _calendarSelectedDay;

  // To store IDs of availabilities loaded for editing
  String? _initialRecurringAvailabilityId;
  String? _initialSpecificDateAvailabilityId;
  String? _courseTutorProfileId; // Tutor profile ID associated with the course

  final Map<String, String> _dayMapping = {
    'Mo': 'Monday',
    'Tu': 'Tuesday',
    'We': 'Wednesday',
    'Th': 'Thursday',
    'Fr': 'Friday',
    'Sa': 'Saturday',
    'Su': 'Sunday',
  };
  // --- End Availability State Variables ---

  XFile? _newCourseImageFile;
  final ImagePicker _picker = ImagePicker();
  String? _existingCourseImageId;
  String? _existingCourseImageUrl;

  String? _selectedSubjectId; // Will be loaded

  @override
  void initState() {
    super.initState();
    _loadAllCourseData();
  }

  Future<void> _loadAllCourseData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    // No need to fetch _currentTutorProfileId separately if course has tutor_id
    await _loadCourseDetailsAndAvailabilities();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) { // "HH:mm:ss"
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      print("Error parsing time: $timeStr, Error: $e");
      return TimeOfDay.now(); // Fallback
    }
  }

  DateTime _parseDate(String dateStr) { // "yyyy-MM-dd"
    try {
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      print("Error parsing date: $dateStr, Error: $e");
      return DateTime.now(); // Fallback
    }
  }

  String _getShortDayName(String fullDayName) {
    for (var entry in _dayMapping.entries) {
      if (entry.value.toLowerCase() == fullDayName.toLowerCase()) {
        return entry.key;
      }
    }
    return '';
  }

  Future<void> _loadCourseDetailsAndAvailabilities() async {
    final response = await _directusService.getCourseDetailsForEdit(widget.courseId);
    if (!mounted) return;

    if (response['success'] && response['data'] != null) {
      final courseData = response['data'] as Map<String, dynamic>;
      _titleController.text = courseData['title'] ?? '';
      _descriptionController.text = courseData['description'] ?? '';

      if (courseData['subject_id'] != null) {
        _selectedSubjectId = (courseData['subject_id'] is Map)
            ? courseData['subject_id']['id']?.toString()
            : courseData['subject_id']?.toString();
      } else {
        _selectedSubjectId = "3"; // Fallback if really needed, but ideally UI shows error
      }


      if (courseData['course_image'] != null && courseData['course_image'] is Map) {
        _existingCourseImageId = courseData['course_image']['id']?.toString();
        if (_existingCourseImageId != null) {
          _existingCourseImageUrl = _directusService.getAssetUrl(_existingCourseImageId!);
        }
      }

      // Extract tutor profile ID from course data
      if (courseData['tutor_id'] != null) {
        _courseTutorProfileId = (courseData['tutor_id'] is Map)
            ? courseData['tutor_id']['id']?.toString()
            : courseData['tutor_id']?.toString();
      }

      // Load availabilities if tutor profile ID is found
      if (_courseTutorProfileId != null) {
        await _loadAvailabilities(_courseTutorProfileId!);
      } else {
        print("Course Tutor Profile ID not found, cannot load availabilities.");
        // Optionally set an error message or handle UI accordingly
      }

    } else {
      _errorMessage = response['message'] ?? "Failed to load course details.";
    }
  }

  Future<void> _loadAvailabilities(String tutorProfileIdForAvailabilities) async {
    final availabilityResponse = await _directusService.fetchTutorAvailabilities(tutorProfileIdForAvailabilities);
    if (!mounted || !availabilityResponse['success'] || availabilityResponse['data'] == null) {
      print("Failed to load availabilities or no data: ${availabilityResponse['message']}");
      return;
    }

    final List<dynamic> availabilities = availabilityResponse['data'];
    bool timeSet = false;

    // Find first recurring availability
    final recurringAvail = availabilities.firstWhere(
            (a) => a['recurring'] == true && a['day_of_week'] != null && (a['day_of_week'] as List).isNotEmpty,
        orElse: () => null
    );
    if (recurringAvail != null) {
      _initialRecurringAvailabilityId = recurringAvail['id']?.toString();
      if (recurringAvail['day_of_week'] is List) {
        _selectedDays.clear();
        for (String fullDayName in recurringAvail['day_of_week']) {
          final shortDay = _getShortDayName(fullDayName);
          if (shortDay.isNotEmpty) _selectedDays.add(shortDay);
        }
      }
      if (recurringAvail['start_time'] != null) _startTime = _parseTimeOfDay(recurringAvail['start_time']);
      if (recurringAvail['end_time'] != null) _endTime = _parseTimeOfDay(recurringAvail['end_time']);
      timeSet = true;
    }

    // Find first specific date availability
    final specificAvail = availabilities.firstWhere(
            (a) => a['recurring'] == false && a['specific_date'] != null,
        orElse: () => null
    );
    if (specificAvail != null) {
      _initialSpecificDateAvailabilityId = specificAvail['id']?.toString();
      if (specificAvail['specific_date'] != null) {
        _calendarSelectedDay = _parseDate(specificAvail['specific_date']);
        _calendarFocusedDay = _calendarSelectedDay!; // Focus on the selected day
      }
      if (!timeSet) { // Only set time if not already set by recurring
        if (specificAvail['start_time'] != null) _startTime = _parseTimeOfDay(specificAvail['start_time']);
        if (specificAvail['end_time'] != null) _endTime = _parseTimeOfDay(specificAvail['end_time']);
      }
    }
    // Update focused day if a specific day is selected
    if (_calendarSelectedDay != null) {
      _calendarFocusedDay = _calendarSelectedDay!;
      // Ensure TableCalendar's firstDay allows this selected day
      // For simplicity, we'll set a wide range for firstDay/lastDay in TableCalendar
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCourseImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null && mounted) {
        setState(() {
          _newCourseImageFile = pickedFile;
          _existingCourseImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Widget _buildCourseImageSection() {
    ImageProvider? imagePreview;
    if (_newCourseImageFile != null) {
      imagePreview = kIsWeb ? NetworkImage(_newCourseImageFile!.path) : FileImage(File(_newCourseImageFile!.path));
    } else if (_existingCourseImageUrl != null && _existingCourseImageUrl!.isNotEmpty) {
      imagePreview = NetworkImage(_existingCourseImageUrl!);
    }

    return GestureDetector(
      onTap: _pickCourseImage,
      child: Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[350]!, width: 1.5),
          image: imagePreview != null
              ? DecorationImage(image: imagePreview, fit: BoxFit.cover,
            onError: (exception, stackTrace) { // Handle image load error
              print("Error loading image for preview: $exception");
              if (mounted) {
                setState(() {
                  // Clear the problematic URL to revert to placeholder
                  if (_newCourseImageFile == null) _existingCourseImageUrl = null;
                });
              }
            },
          )
              : null,
        ),
        child: imagePreview == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_rounded, size: 60, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text('Tap to change course image', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ],
        )
            : null,
      ),
    );
  }

  // --- Availability Helper Methods (from CreateCourseScreen) ---
  String _formatTimeOfDayForDisplay(TimeOfDay? tod) {
    if (tod == null) return 'Set Time';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat.jm().format(dt); // Using AM/PM format
  }

  String _formatTimeOfDayForApi(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _getDayNameFromWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return '';
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? _startTime ?? TimeOfDay.now());

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          if (_endTime != null &&
              (_endTime!.hour < picked.hour ||
                  (_endTime!.hour == picked.hour && _endTime!.minute < picked.minute))) {
            _endTime = null; // Reset end time if it's before new start time
          }
        } else { // isEndTime
          if (_startTime != null &&
              (picked.hour < _startTime!.hour ||
                  (picked.hour == _startTime!.hour && picked.minute < _startTime!.minute))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("End time cannot be before start time."), backgroundColor: Colors.red),
            );
          } else {
            _endTime = picked;
          }
        }
      });
    }
  }
  // --- End Availability Helper Methods ---

  // --- Availability UI Widgets (from CreateCourseScreen) ---
  Widget _buildDayToggle(String day) {
    final isSelected = _selectedDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(day);
          } else {
            _selectedDays.add(day);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          day,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildClassSchedule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Class Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Time', style: TextStyle(fontSize: 15, color: Colors.black54)),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _selectTime(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                  child: Text(_formatTimeOfDayForDisplay(_startTime), style: const TextStyle(color: Colors.black54)),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('-', style: TextStyle(color: Colors.black54))),
              InkWell(
                onTap: () => _selectTime(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                  child: Text(_formatTimeOfDayForDisplay(_endTime), style: const TextStyle(color: Colors.black54)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Day ', style: TextStyle(fontSize: 15, color: Colors.black54)),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _dayMapping.keys.map((day) => _buildDayToggle(day)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(8)),
          child: const Center(
            child: Text('Specific Available Date (Optional)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1), // Allow past dates for editing
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _calendarFocusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(_calendarSelectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!mounted) return;
            setState(() {
              if (!isSameDay(_calendarSelectedDay, selectedDay)) {
                _calendarSelectedDay = selectedDay;
                _calendarFocusedDay = focusedDay;
              } else {
                _calendarSelectedDay = null; // Deselect if tapped again
              }
            });
          },
          onPageChanged: (focusedDay) {
            if (!mounted) return;
            _calendarFocusedDay = focusedDay; // No setState needed, calendar handles internal focus
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.grey),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.teal[100], shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
            selectedTextStyle: const TextStyle(color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekendStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            weekdayStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
  // --- End Availability UI Widgets ---


  Future<void> _handleUpdateCourse() async {
    if (_isLoading) return;

    final String courseTitle = _titleController.text.trim();
    final String courseDescription = _descriptionController.text.trim();

    if (courseTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a course title.'), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject ID is missing or invalid.'), backgroundColor: Colors.orange));
      return;
    }
    // Validate availability times if days or date are selected
    if ((_selectedDays.isNotEmpty || _calendarSelectedDay != null) && (_startTime == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end times for availability.'), backgroundColor: Colors.orange));
      return;
    }


    setState(() { _isLoading = true; _errorMessage = null; });

    String? finalImageIdToSave; // This will be null if no new image, or new image ID
    bool courseUpdateSuccess = false;
    bool availabilityUpdateSuccess = true; // Assume success unless an error occurs
    List<String> availabilityErrors = [];
    Map<String, dynamic>? updatedCourseData;


    try {
      // 1. Handle Image Upload (if new image picked)
      if (_newCourseImageFile != null) {
        final imageUploadResponse = await _directusService.uploadFile(_newCourseImageFile!);
        if (imageUploadResponse['success'] && imageUploadResponse['data'] != null) {
          finalImageIdToSave = imageUploadResponse['data']['id']?.toString();
        } else {
          _errorMessage = 'Failed to upload new image: ${imageUploadResponse['message']}';
          throw Exception(_errorMessage); // Stop execution
        }
      }
      // If no new image, finalImageIdToSave remains null.
      // The service's updateCourse method handles not changing the image if this is null.

      // 2. Update Course Core Details
      final courseResponse = await _directusService.updateCourse(
        courseId: widget.courseId,
        title: courseTitle,
        description: courseDescription,
        subjectId: _selectedSubjectId!,
        courseImageId: finalImageIdToSave, // Pass new ID or null (service handles 'no change')
      );

      if (courseResponse['success']) {
        courseUpdateSuccess = true;
        updatedCourseData = courseResponse['data'];

        // 3. Handle Availability (Delete old, Create new)
        if (_courseTutorProfileId != null) {
          // Delete old recurring availability
          if (_initialRecurringAvailabilityId != null) {
            final delRes = await _directusService.deleteTutorAvailability(_initialRecurringAvailabilityId!);
            if (!delRes['success']) {
              availabilityUpdateSuccess = false;
              availabilityErrors.add('Old recurring: ${delRes['message']}');
            }
          }
          // Delete old specific date availability
          if (_initialSpecificDateAvailabilityId != null) {
            final delRes = await _directusService.deleteTutorAvailability(_initialSpecificDateAvailabilityId!);
            if (!delRes['success']) {
              availabilityUpdateSuccess = false;
              availabilityErrors.add('Old specific: ${delRes['message']}');
            }
          }

          // Create new availabilities if times are set
          if (_startTime != null && _endTime != null) {
            if (_selectedDays.isNotEmpty) {
              List<String> recurringDaysList = _selectedDays.map((shortDay) => _dayMapping[shortDay]!).where((day) => day.isNotEmpty).toList();
              if (recurringDaysList.isNotEmpty) {
                final createRes = await _directusService.createTutorAvailability(
                  tutorId: _courseTutorProfileId!, daysOfWeek: recurringDaysList,
                  startTime: _formatTimeOfDayForApi(_startTime!), endTime: _formatTimeOfDayForApi(_endTime!),
                  recurring: true,
                );
                if (!createRes['success']) { availabilityUpdateSuccess = false; availabilityErrors.add('New recurring: ${createRes['message']}'); }
              }
            }
            if (_calendarSelectedDay != null) {
              final createRes = await _directusService.createTutorAvailability(
                tutorId: _courseTutorProfileId!, daysOfWeek: [_getDayNameFromWeekday(_calendarSelectedDay!.weekday)],
                startTime: _formatTimeOfDayForApi(_startTime!), endTime: _formatTimeOfDayForApi(_endTime!),
                recurring: false, specificDate: _formatDateForApi(_calendarSelectedDay!),
              );
              if (!createRes['success']) { availabilityUpdateSuccess = false; availabilityErrors.add('New specific: ${createRes['message']}');}
            }
          }
        } else {
          availabilityErrors.add("Tutor profile ID missing, can't update availability.");
          availabilityUpdateSuccess = false; // Technically true as nothing was attempted.
        }
      } else {
        _errorMessage = courseResponse['message'] ?? 'Failed to update course details.';
      }
    } catch (e) {
      _errorMessage = _errorMessage ?? "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
        if (_errorMessage != null && !courseUpdateSuccess) { // Major failure
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
        } else if (courseUpdateSuccess && availabilityUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course "${updatedCourseData?['title'] ?? courseTitle}" and availability updated!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        } else if (courseUpdateSuccess && !availabilityUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course updated. Availability issues: ${availabilityErrors.join("; ")}'), backgroundColor: Colors.orange, duration: const Duration(seconds: 7)));
          Navigator.of(context).pop(true); // Still pop, course was saved
        } else {
          // Catch all for other unhandled _errorMessage states
          if(_errorMessage != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // final Color primaryColor = Theme.of(context).primaryColor; // Using defined primaryTeal

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Course', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
      ),
      body: _isLoading && _titleController.text.isEmpty // Initial full page loader
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Space for bottom sheet
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null && !_isLoading) // Show error if not loading and error exists
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16))
              ),
            _buildCourseImageSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Course Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'E.g., Introduction to Algebra',
                      filled: true, fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subject ID: ${_selectedSubjectId ?? "Not set"} (Implement dynamic subject selection/display)',
                    style: TextStyle(color: _selectedSubjectId == null ? Colors.red : Colors.orange[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Course Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Course description...',
                      filled: true, fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // --- Add Availability UI Sections ---
            if (_courseTutorProfileId != null) ...[ // Only show if tutor ID is available
              _buildClassSchedule(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCalendarSection(),
              ),
            ] else if (!_isLoading) // If not loading and no tutor ID, show a message
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    "Availability section cannot be loaded: Course tutor information is missing.",
                    style: TextStyle(color: Colors.grey[600])
                ),
              ),

            // const SizedBox(height: 120), // Already handled by SingleChildScrollView padding
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _handleUpdateCourse,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}