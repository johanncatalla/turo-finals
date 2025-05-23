// edit_course_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/directus_service.dart'; // Ensure this path is correct

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
  bool _isLoadingPage = true; // For initial page load (course + subjects)
  bool _isSaving = false; // For the save button
  String? _errorMessage;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Set<String> _selectedDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime _calendarFocusedDay = DateTime.now();
  DateTime? _calendarSelectedDay;

  String? _initialRecurringAvailabilityId;
  String? _initialSpecificDateAvailabilityId;
  String? _courseTutorProfileId;

  final Map<String, String> _dayMapping = {
    'Mo': 'Monday', 'Tu': 'Tuesday', 'We': 'Wednesday', 'Th': 'Thursday',
    'Fr': 'Friday', 'Sa': 'Saturday', 'Su': 'Sunday',
  };

  XFile? _newCourseImageFile;
  final ImagePicker _picker = ImagePicker();
  String? _existingCourseImageId;
  String? _existingCourseImageUrl;

  // --- NEW: For Subjects Dropdown ---
  List<Map<String, dynamic>> _subjectsList = [];
  String? _selectedSubjectId; // This will be loaded and can be changed
  bool _isLoadingSubjects = true; // Specific loading for subjects dropdown
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    _loadAllInitialData();
  }

  Future<void> _loadAllInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPage = true;
      _errorMessage = null;
    });

    // Fetch subjects first or in parallel
    await _fetchSubjects(); // Wait for subjects to load for the dropdown

    // Then load course details (which might depend on subjects being available for display)
    await _loadCourseDetailsAndAvailabilities();

    if (mounted) {
      setState(() {
        _isLoadingPage = false; // Page is ready once both are done
      });
    }
  }

  // --- NEW: Method to fetch subjects (similar to CreateCourseScreen) ---
  Future<void> _fetchSubjects() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSubjects = true;
      // _subjectsList.clear(); // No need to clear if fetched once
      // _selectedSubjectId = null; // Don't reset here, it will be set by _loadCourseDetails
    });

    final response = await _directusService.fetchSubjects();

    if (!mounted) return;

    if (response['success'] == true && response['data'] != null) {
      final List<dynamic> fetchedData = response['data'];
      setState(() {
        _subjectsList = List<Map<String, dynamic>>.from(fetchedData);
        // _isLoadingSubjects = false; // Moved to _loadAllInitialData completion
      });
      if (_subjectsList.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subjects available to select.'), backgroundColor: Colors.orange),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to fetch subjects: ${response['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red),
        );
      }
    }
    // Final state update for subjects loading is handled by _loadAllInitialData
    setState(() { _isLoadingSubjects = false; });
  }
  // --- END NEW ---

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      print("Error parsing time: $timeStr, Error: $e");
      return TimeOfDay.now();
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      print("Error parsing date: $dateStr, Error: $e");
      return DateTime.now();
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
    // setState specific to this part of loading if needed, or rely on _isLoadingPage
    final response = await _directusService.getCourseDetailsForEdit(widget.courseId);
    if (!mounted) return;

    if (response['success'] && response['data'] != null) {
      final courseData = response['data'] as Map<String, dynamic>;
      _titleController.text = courseData['title'] ?? '';
      _descriptionController.text = courseData['description'] ?? '';

      // --- MODIFIED: Set _selectedSubjectId from course data ---
      if (courseData['subject_id'] != null) {
        // Directus might return the related item as an object or just its ID
        if (courseData['subject_id'] is Map) {
          _selectedSubjectId = courseData['subject_id']['id']?.toString();
        } else {
          _selectedSubjectId = courseData['subject_id']?.toString();
        }
        // Ensure the loaded subject ID is valid among fetched subjects
        if (_selectedSubjectId != null && !_subjectsList.any((s) => s['id'].toString() == _selectedSubjectId)) {
          print("Warning: Course's subject_id ('$_selectedSubjectId') not found in fetched subjects list. It might have been deleted.");
          // Optionally, nullify _selectedSubjectId or show a specific warning
          // _selectedSubjectId = null;
        }

      } else {
        print("Warning: Course details do not contain a subject_id.");
        // _selectedSubjectId = null; // or a default/fallback if absolutely necessary
      }
      // --- END MODIFIED ---

      if (courseData['course_image'] != null && courseData['course_image'] is Map) {
        _existingCourseImageId = courseData['course_image']['id']?.toString();
        if (_existingCourseImageId != null) {
          _existingCourseImageUrl = _directusService.getAssetUrl(_existingCourseImageId!);
        }
      }

      if (courseData['tutor_id'] != null) {
        _courseTutorProfileId = (courseData['tutor_id'] is Map)
            ? courseData['tutor_id']['id']?.toString()
            : courseData['tutor_id']?.toString();
        if (_courseTutorProfileId != null) {
          await _loadAvailabilities(_courseTutorProfileId!);
        } else {
          print("Course Tutor Profile ID not found, cannot load availabilities.");
        }
      }
    } else {
      _errorMessage = response['message'] ?? "Failed to load course details.";
    }
    // No individual setState for isLoading here, handled by _loadAllInitialData
  }


  Future<void> _loadAvailabilities(String tutorProfileIdForAvailabilities) async {
    final availabilityResponse = await _directusService.fetchTutorAvailabilities(tutorProfileIdForAvailabilities);
    if (!mounted || !availabilityResponse['success'] || availabilityResponse['data'] == null) {
      print("Failed to load availabilities or no data: ${availabilityResponse['message']}");
      return;
    }

    final List<dynamic> availabilities = availabilityResponse['data'];
    bool timeSet = false;

    _initialRecurringAvailabilityId = null;
    _initialSpecificDateAvailabilityId = null;
    _selectedDays.clear();
    _startTime = null;
    _endTime = null;
    _calendarSelectedDay = null;


    final recurringAvail = availabilities.firstWhere(
            (a) => a['recurring'] == true && a['day_of_week'] != null && (a['day_of_week'] as List).isNotEmpty,
        orElse: () => null
    );
    if (recurringAvail != null) {
      _initialRecurringAvailabilityId = recurringAvail['id']?.toString();
      if (recurringAvail['day_of_week'] is List) {
        for (String fullDayName in recurringAvail['day_of_week']) {
          final shortDay = _getShortDayName(fullDayName);
          if (shortDay.isNotEmpty) _selectedDays.add(shortDay);
        }
      }
      if (recurringAvail['start_time'] != null) _startTime = _parseTimeOfDay(recurringAvail['start_time']);
      if (recurringAvail['end_time'] != null) _endTime = _parseTimeOfDay(recurringAvail['end_time']);
      timeSet = true;
    }

    final specificAvail = availabilities.firstWhere(
            (a) => a['recurring'] == false && a['specific_date'] != null,
        orElse: () => null
    );
    if (specificAvail != null) {
      _initialSpecificDateAvailabilityId = specificAvail['id']?.toString();
      if (specificAvail['specific_date'] != null) {
        _calendarSelectedDay = _parseDate(specificAvail['specific_date']);
      }
      if (!timeSet) {
        if (specificAvail['start_time'] != null) _startTime = _parseTimeOfDay(specificAvail['start_time']);
        if (specificAvail['end_time'] != null) _endTime = _parseTimeOfDay(specificAvail['end_time']);
      }
    }
    if (_calendarSelectedDay != null) {
      _calendarFocusedDay = _calendarSelectedDay!;
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
          _existingCourseImageUrl = null; // Clear existing image URL if new one is picked
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
            onError: (exception, stackTrace) {
              print("Error loading image for preview: $exception");
              if (mounted) {
                setState(() {
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

  String _formatTimeOfDayForDisplay(TimeOfDay? tod) {
    if (tod == null) return 'Set Time';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat.jm().format(dt);
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
            _endTime = null;
          }
        } else {
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
          firstDay: DateTime.utc(2020, 1, 1),
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
                _calendarSelectedDay = null;
              }
            });
          },
          onPageChanged: (focusedDay) {
            if (!mounted) return;
            _calendarFocusedDay = focusedDay; // Update internal focus day
            // No setState needed for onPageChanged if TableCalendar handles its own redraw
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

  // --- NEW: Widget for Subjects Dropdown (similar to CreateCourseScreen) ---
  Widget _buildSubjectsDropdown() {
    if (_isLoadingSubjects && _subjectsList.isEmpty) { // Show loader only if subjects list is still empty
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    if (_subjectsList.isEmpty && !_isLoadingSubjects) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No subjects found. Please add subjects first.',
                style: TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blueGrey[600]),
              onPressed: _isLoadingSubjects ? null : _fetchSubjects, // Disable while loading
              tooltip: 'Refresh Subjects',
            )
          ],
        ),
      );
    }

    // Ensure _selectedSubjectId is valid or nullify
    // This check is important if the previously selected subject was deleted
    String? currentValidSubjectId = _selectedSubjectId;
    if (currentValidSubjectId != null && !_subjectsList.any((s) => s['id'].toString() == currentValidSubjectId)) {
      print("Previously selected subject ID '$currentValidSubjectId' is no longer valid. Clearing selection.");
      currentValidSubjectId = null;
      // Optionally, update _selectedSubjectId in setState if you want the UI to immediately reflect this
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   if (mounted) setState(() => _selectedSubjectId = null);
      // });
    }


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Select a Subject',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primaryTeal),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
            ),
            value: currentValidSubjectId, // Use the validated subject ID
            isExpanded: true,
            items: _subjectsList.map((subject) {
              final String subjectId = subject['id']?.toString() ?? '';
              final String subjectName = subject['subject_name']?.toString() ?? 'Unnamed Subject ($subjectId)';
              return DropdownMenuItem<String>(
                value: subjectId,
                child: Text(subjectName),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (mounted) {
                setState(() {
                  _selectedSubjectId = newValue;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a subject';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  // --- END NEW ---

  Future<void> _handleUpdateCourse() async {
    if (_isSaving) return;

    final String courseTitle = _titleController.text.trim();
    final String courseDescription = _descriptionController.text.trim();

    if (courseTitle.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a course title.'), backgroundColor: Colors.orange));
      return;
    }
    // --- MODIFIED: Use _selectedSubjectId for validation ---
    if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject.'), backgroundColor: Colors.orange));
      return;
    }
    // --- END MODIFIED ---
    if ((_selectedDays.isNotEmpty || _calendarSelectedDay != null) && (_startTime == null || _endTime == null)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end times for availability.'), backgroundColor: Colors.orange));
      return;
    }

    if (mounted) setState(() { _isSaving = true; _errorMessage = null; });

    String? finalImageIdToSave = _existingCourseImageId; // Start with existing, may change
    bool courseUpdateSuccess = false;
    bool availabilityUpdateSuccess = true;
    List<String> availabilityErrors = [];
    Map<String, dynamic>? updatedCourseData;

    try {
      if (_newCourseImageFile != null) {
        final imageUploadResponse = await _directusService.uploadFile(_newCourseImageFile!);
        if (imageUploadResponse['success'] && imageUploadResponse['data'] != null) {
          finalImageIdToSave = imageUploadResponse['data']['id']?.toString();
        } else {
          _errorMessage = 'Failed to upload new image: ${imageUploadResponse['message']}';
          throw Exception(_errorMessage);
        }
      } // If _newCourseImageFile is null, finalImageIdToSave remains _existingCourseImageId or becomes null if that was also null.
      // The updateCourse service method should handle `null` for courseImageId to mean "do not change image" or "remove image" based on your service logic.
      // For Directus PATCH, not sending the 'course_image' field leaves it unchanged.
      // Sending 'course_image': null would clear it.
      // Here, we ensure `updateCourse` receives either a new ID or the existing ID (or null if it was never set/cleared).
      // To explicitly remove: you might need another UI action and pass `null` for `finalImageIdToSave`
      // when `_existingCourseImageId` was present but user wants to remove.
      // For now, if _newCourseImageFile is null, we assume we keep the existing or what `updateCourse` does with null.


      final courseResponse = await _directusService.updateCourse(
        courseId: widget.courseId,
        title: courseTitle,
        description: courseDescription,
        subjectId: _selectedSubjectId!, // Use the dynamic subject ID
        courseImageId: finalImageIdToSave,
      );

      if (courseResponse['success']) {
        courseUpdateSuccess = true;
        updatedCourseData = courseResponse['data'];

        if (_courseTutorProfileId != null) {
          if (_initialRecurringAvailabilityId != null) {
            final delRes = await _directusService.deleteTutorAvailability(_initialRecurringAvailabilityId!);
            if (!delRes['success']) { availabilityUpdateSuccess = false; availabilityErrors.add('Old recurring: ${delRes['message']}'); }
          }
          if (_initialSpecificDateAvailabilityId != null) {
            final delRes = await _directusService.deleteTutorAvailability(_initialSpecificDateAvailabilityId!);
            if (!delRes['success']) { availabilityUpdateSuccess = false; availabilityErrors.add('Old specific: ${delRes['message']}'); }
          }

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
        }
      } else {
        _errorMessage = courseResponse['message'] ?? 'Failed to update course details.';
      }
    } catch (e) {
      _errorMessage = _errorMessage ?? "An error occurred: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
        if (_errorMessage != null && !courseUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
        } else if (courseUpdateSuccess && availabilityUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course "${updatedCourseData?['title'] ?? courseTitle}" and availability updated!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true); // Indicate success
        } else if (courseUpdateSuccess && !availabilityUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course updated. Availability issues: ${availabilityErrors.join("; ")}'), backgroundColor: Colors.orange, duration: const Duration(seconds: 7)));
          Navigator.of(context).pop(true); // Indicate success for course part
        } else {
          if(_errorMessage != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
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
      body: _isLoadingPage
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null && !_isSaving) // Show error if not saving and error exists
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal)),
                    ),
                  ),
                  // --- MODIFIED: Add the subjects dropdown ---
                  _buildSubjectsDropdown(),
                  // --- END MODIFIED ---
                ],
              ),
            ),
            // const SizedBox(height: 16), // Adjusted spacing due to dropdown adding its own padding
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryTeal)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_courseTutorProfileId != null) ...[
              _buildClassSchedule(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCalendarSection(),
              ),
            ] else if (!_isLoadingPage)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    "Availability section cannot be loaded: Course tutor information is missing or could not be loaded.",
                    style: TextStyle(color: Colors.grey[600])
                ),
              ),
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
            onPressed: _isLoadingPage || _isSaving ? null : _handleUpdateCourse, // Disable if page is loading or saving
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}