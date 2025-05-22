import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart'; // << NEW: Import image_picker
import 'dart:io'; // << NEW: Import for File operations

import '../../services/directus_service.dart';


enum CourseTab { lecturer, materials }

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen>
    with SingleTickerProviderStateMixin {
  final DirectusService _directusService = DirectusService();
  String? _currentTutorProfileId;
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _selectedDays = {};

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late TabController _tabController;
  DateTime _calendarFocusedDay = DateTime.now();
  DateTime? _calendarSelectedDay;

  // --- NEW: For Image Upload ---
  XFile? _courseImageFile;
  final ImagePicker _picker = ImagePicker();
  // --- END NEW ---

  final Map<String, String> _dayMapping = {
    'Mo': 'Monday',
    'Tu': 'Tuesday',
    'We': 'Wednesday',
    'Th': 'Thursday',
    'Fr': 'Friday',
    'Sa': 'Saturday',
    'Su': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCurrentTutorProfileId();
  }

  Future<void> _fetchCurrentTutorProfileId() async {
    // ... (your existing _fetchCurrentTutorProfileId method - no changes needed here)
    final response = await _directusService.fetchTutorProfile();
    if (mounted) {
      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'];
        final tutorProfileData = userData['tutor_profile'][0];

        if (tutorProfileData != null && tutorProfileData is Map) {
          if (tutorProfileData['id'] != null) {
            setState(() {
              _currentTutorProfileId = tutorProfileData['id'].toString();
              print("Current Tutor Profile ID: $_currentTutorProfileId");
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Tutor profile data is incomplete (missing ID).'),
                  backgroundColor: Colors.orange),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No tutor profile found for this user or it could not be resolved. Please ensure a tutor profile exists and is linked.'),
                backgroundColor: Colors.orange),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching tutor profile: ${response['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // --- NEW: Image Picker Method ---
  Future<void> _pickCourseImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Or ImageSource.camera
        imageQuality: 70, // Optional: to reduce file size
        maxWidth: 1024,   // Optional: to resize image
        maxHeight: 1024,  // Optional: to resize image
      );
      if (pickedFile != null) {
        setState(() {
          _courseImageFile = pickedFile;
        });
      } else {
        // User canceled the picker
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
        }
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }
  // --- END NEW ---

  String _formatTimeOfDayForDisplay(TimeOfDay? tod) {
    // ... (your existing method)
    if (tod == null) return '00:00';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  String _formatTimeOfDayForApi(TimeOfDay? tod) {
    // ... (your existing method)
    if (tod == null) return '00:00:00';
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatDateForApi(DateTime? date) {
    // ... (your existing method)
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _getDayNameFromWeekday(int weekday) {
    // ... (your existing method)
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
    // ... (your existing method - no changes needed here)
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

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          if (_endTime != null &&
              (_endTime!.hour < picked.hour ||
                  (_endTime!.hour == picked.hour &&
                      _endTime!.minute < picked.minute))) {
            _endTime = null;
          }
        } else {
          if (_startTime != null &&
              (picked.hour < _startTime!.hour ||
                  (picked.hour == _startTime!.hour &&
                      picked.minute < _startTime!.minute))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("End time cannot be before start time."),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            _endTime = picked;
          }
        }
      });
    }
  }

  Future<void> _handleSaveCourseAndAvailability() async {
    if (_isLoading) return;

    final String courseTitle = _titleController.text.trim();
    final String courseDescription = _descriptionController.text.trim();
    final String? subjectId = "3"; // TODO: Replace with dynamic subject ID

    // Validations
    if (_currentTutorProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor Profile ID not found. Cannot save course.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (courseTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course title.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (subjectId == null || subjectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject ID is missing. Please select a subject.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times for availability.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedDays.isEmpty && _calendarSelectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recurring day or a specific date for availability.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });

    String? uploadedCourseImageId; // << MODIFIED: To store the uploaded image ID

    // --- MODIFIED: Step 1. Upload the course_image ---
    if (_courseImageFile != null) {
      final imageUploadResponse = await _directusService.uploadFile(_courseImageFile!);
      if (imageUploadResponse['success'] == true && imageUploadResponse['data'] != null) {
        uploadedCourseImageId = imageUploadResponse['data']['id']?.toString();
        if (uploadedCourseImageId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get ID from uploaded course image.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { _isLoading = false; });
          return;
        }
        print("Uploaded Course Image ID: $uploadedCourseImageId");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload course image: ${imageUploadResponse['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return; // Stop if image upload fails
      }
    }
    // --- END MODIFIED ---

    // 2. Create the Course
    final courseResponse = await _directusService.createCourse(
      title: courseTitle,
      description: courseDescription,
      subjectId: subjectId,
      tutorId: _currentTutorProfileId!,
      courseImageId: uploadedCourseImageId, // << MODIFIED: Pass the image ID
    );

    if (courseResponse['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to create course: ${courseResponse['message']}'),
            backgroundColor: Colors.red),
      );
      setState(() { _isLoading = false; });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Course "${courseResponse['data']?['title'] ?? courseTitle}" created! Adding availability...'),
          backgroundColor: Colors.green),
    );

    //Create Tutor Availability slots
    bool allAvailabilityCreated = true;
    List<String> availabilityErrors = [];

    if (_selectedDays.isNotEmpty) {
      List<String> recurringDaysList = _selectedDays
          .map((shortDay) => _dayMapping[shortDay] ?? '')
          .where((day) => day.isNotEmpty)
          .toList();

      if (recurringDaysList.isNotEmpty) {
        final availabilityResponse = await _directusService.createTutorAvailability(
          tutorId: _currentTutorProfileId!,
          daysOfWeek: recurringDaysList,
          startTime: _formatTimeOfDayForApi(_startTime!),
          endTime: _formatTimeOfDayForApi(_endTime!),
          recurring: true,
          specificDate: null,
        );
        if (availabilityResponse['success'] != true) {
          allAvailabilityCreated = false;
          availabilityErrors.add('Recurring: ${availabilityResponse['message']}');
        }
      }
    }

    if (_calendarSelectedDay != null) {
      final String dayNameForSpecificDate = _getDayNameFromWeekday(_calendarSelectedDay!.weekday);
      final availabilityResponse = await _directusService.createTutorAvailability(
        tutorId: _currentTutorProfileId!,
        daysOfWeek: [dayNameForSpecificDate],
        startTime: _formatTimeOfDayForApi(_startTime!),
        endTime: _formatTimeOfDayForApi(_endTime!),
        recurring: false,
        specificDate: _formatDateForApi(_calendarSelectedDay!),
      );
      if (availabilityResponse['success'] != true) {
        allAvailabilityCreated = false;
        availabilityErrors.add('Specific Date (${_formatDateForApi(_calendarSelectedDay!)}): ${availabilityResponse['message']}');
      }
    }

    setState(() { _isLoading = false; });

    if (allAvailabilityCreated && availabilityErrors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All tutor availability slots created successfully!'),
            backgroundColor: Colors.green),
      );
      // Optionally clear form or navigate:
      // _titleController.clear();
      // _descriptionController.clear();
      // setState(() {
      //   _courseImageFile = null;
      //   _selectedDays.clear();
      //   _startTime = null;
      //   _endTime = null;
      //   _calendarSelectedDay = null;
      // });
      // Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course created. Availability issues: ${availabilityErrors.join("; ")}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }


  // --- UI Widgets ---

  // --- NEW: Widget for Image Picker and Preview ---
  Widget _buildCourseImagePicker() {
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
        ),
        child: _courseImageFile == null
            ? Column( // Placeholder UI when no image is selected
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_rounded, size: 60, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'Tap to upload course image',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Preview will appear here (e.g., 16:9)',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        )
            : ClipRRect( // Display the selected image
          borderRadius: BorderRadius.circular(10.5), // Slightly less than container radius for better look
          child: kIsWeb // <<<< MODIFICATION START >>>>
              ? Image.network( // Use Image.network for web
            _courseImageFile!.path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // Optional: Add errorBuilder for web network image
            errorBuilder: (context, error, stackTrace) {
              print("Error loading web image: $error");
              return const Center(child: Text("Couldn't display image"));
            },
          )
              : Image.file( // Use Image.file for mobile/desktop
            File(_courseImageFile!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ), // <<<< MODIFICATION END >>>>
        ),
      ),
    );
  }
  // --- END NEW ---


  Widget _buildDayToggle(String day) {
    // ... (your existing method)
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
          color: isSelected ? const Color(0xFF53C6D9) : Colors.grey[200],
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
    // ... (your existing method)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Class Schedule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Time',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _selectTime(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatTimeOfDayForDisplay(_startTime),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('-', style: TextStyle(color: Colors.black54)),
              ),
              InkWell(
                onTap: () => _selectTime(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatTimeOfDayForDisplay(_endTime),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Day ',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildDayToggle('Mo'),
                    _buildDayToggle('Tu'),
                    _buildDayToggle('We'),
                    _buildDayToggle('Th'),
                    _buildDayToggle('Fr'),
                    _buildDayToggle('Sa'),
                    _buildDayToggle('Su'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerTabContent() {
    // ... (your existing method)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_add_alt_1, size: 48, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite tutor to course',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invited tutor will have the same access to learning materials and student information.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsTabContent() {
    // ... (your existing method)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_copy_outlined, size: 40, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Drag and drop or click here',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'to upload files (max 500mb)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    // ... (your existing method)
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4DB6AC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Specific Available Date (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        TableCalendar(
          firstDay: DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _calendarFocusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) {
            return isSameDay(_calendarSelectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_calendarSelectedDay, selectedDay)) {
              setState(() {
                _calendarSelectedDay = selectedDay;
                _calendarFocusedDay = focusedDay;
              });
            } else {
              setState(() {
                _calendarSelectedDay = null;
              });
            }
            print('Selected Calendar Day: $_calendarSelectedDay');
          },
          onPageChanged: (focusedDay) {
            _calendarFocusedDay = focusedDay;
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.grey),
            rightChevronIcon:
            const Icon(Icons.chevron_right, color: Colors.grey),
            headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.teal[100],
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: const Color(0xFF4DB6AC),
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(color: Colors.white),
            todayTextStyle: TextStyle(color: Colors.teal[800]),
            weekendTextStyle: TextStyle(color: Colors.grey[700]),
            defaultTextStyle: const TextStyle(color: Colors.black87),
            outsideDaysVisible: false,
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekendStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            weekdayStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        // ... (your existing AppBar)
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Course',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color.fromARGB(255, 238, 231, 231),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MODIFIED: Use the new image picker widget ---
            _buildCourseImagePicker(),
            // --- END MODIFIED ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Course Title',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'E.g., Introduction to Algebra',
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
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: Subject ID is currently hardcoded. Implement dynamic subject selection.',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
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
                  const Text(
                    'Course Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Course description will appear here...',
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
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildClassSchedule(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF4DB6AC),
                    indicatorWeight: 3.0,
                    labelColor: const Color(0xFF4DB6AC),
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                    tabs: const [Tab(text: 'Lecturer'), Tab(text: 'Materials')],
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 150,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLecturerTabContent(),
                    _buildMaterialsTabContent(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCalendarSection(),
            ),
            const SizedBox(height: 120), // Space for bottom sheet
          ],
        ),
      ),
      bottomSheet: Padding(
        // ... (your existing bottomSheet - no changes needed here, already handles _isLoading)
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            onPressed: (_isLoading || _currentTutorProfileId == null)
                ? null
                : _handleSaveCourseAndAvailability,
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : Text(
              _currentTutorProfileId == null ? 'Tutor Profile Missing' : 'Save Course & Availability',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}