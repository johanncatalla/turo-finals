import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  String? _currentTutorProfileId; // << RENAMED
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _selectedDays = {};

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late TabController _tabController;
  DateTime _calendarFocusedDay = DateTime.now();
  DateTime? _calendarSelectedDay;

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
    final response = await _directusService.fetchTutorProfile();
    if (mounted) {
      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'];
        final tutorProfileData = userData['tutor_profile'][0];

        // The `fetchTutorProfile` service method aims to resolve `tutor_profile` to a Map
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
          // This covers null tutor_profile or if it wasn't resolved as expected
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

  String _formatTimeOfDayForDisplay(TimeOfDay? tod) {
    if (tod == null) return '00:00';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  String _formatTimeOfDayForApi(TimeOfDay? tod) {
    if (tod == null) return '00:00:00';
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _formatDateForApi(DateTime? date) {
    if (date == null) return '';
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
    // Ensure times are selected before proceeding
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times for availability.'), backgroundColor: Colors.orange),
      );
      setState(() { _isLoading = false; }); // Reset loading if validation fails
      return;
    }
    // Ensure at least one form of availability is selected
    if (_selectedDays.isEmpty && _calendarSelectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recurring day or a specific date for availability.'), backgroundColor: Colors.orange),
      );
      setState(() { _isLoading = false; }); // Reset loading
      return;
    }


    setState(() { _isLoading = true; });

    // 1. Create the Course
    final courseResponse = await _directusService.createCourse(
      title: courseTitle,
      description: courseDescription,
      subjectId: subjectId,
      tutorId: _currentTutorProfileId!,
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

    // Handle recurring availability (if days are selected)
    if (_selectedDays.isNotEmpty) {
      List<String> recurringDaysList = _selectedDays
          .map((shortDay) => _dayMapping[shortDay] ?? '')
          .where((day) => day.isNotEmpty) // Filter out any empty strings if mapping failed
          .toList();

      if (recurringDaysList.isNotEmpty) { // Proceed only if there are valid day names
        final availabilityResponse = await _directusService.createTutorAvailability(
          tutorId: _currentTutorProfileId!,
          daysOfWeek: recurringDaysList, // Pass the list of full day names
          startTime: _formatTimeOfDayForApi(_startTime!),
          endTime: _formatTimeOfDayForApi(_endTime!),
          recurring: true,
          specificDate: null, // Not a specific single date
        );
        if (availabilityResponse['success'] != true) {
          allAvailabilityCreated = false;
          availabilityErrors.add('Recurring: ${availabilityResponse['message']}');
        }
      }
    }

    // Handle specific date availability (if a calendar day is selected)
    if (_calendarSelectedDay != null) {
      final String dayNameForSpecificDate = _getDayNameFromWeekday(_calendarSelectedDay!.weekday);
      final availabilityResponse = await _directusService.createTutorAvailability(
        tutorId: _currentTutorProfileId!,
        daysOfWeek: [dayNameForSpecificDate], // API expects a list, so wrap the single day name
        startTime: _formatTimeOfDayForApi(_startTime!),
        endTime: _formatTimeOfDayForApi(_endTime!),
        recurring: false, // This is a non-recurring, specific date
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
      // Optionally clear form or navigate
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



  // --- UI Widgets (no changes below this line, assuming they are fine) ---
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
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              margin: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded, size: 60, color: Colors.grey[500]),
                  const SizedBox(height: 16),
                  Text('Drag and drop or click here', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text('to upload your course image preview', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            ),
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
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: Padding(
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
            onPressed: (_isLoading || _currentTutorProfileId == null) // Disable if loading or no tutor profile ID
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