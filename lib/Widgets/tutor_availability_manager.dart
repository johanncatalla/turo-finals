import 'package:flutter/material.dart';
import 'package:turo/services/directus_service.dart';

class TutorAvailabilityManager extends StatefulWidget {
  final String tutorProfileId;
  final VoidCallback? onAvailabilityChanged;
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;

  const TutorAvailabilityManager({
    super.key,
    required this.tutorProfileId,
    this.onAvailabilityChanged,
    this.primaryColor = const Color(0xFF53C6D9),
    this.secondaryTextColor = Colors.grey,
    this.cardBackgroundColor = Colors.white,
    this.shadowColor = Colors.grey,
    this.borderColor = Colors.grey,
  });

  @override
  State<TutorAvailabilityManager> createState() => _TutorAvailabilityManagerState();
}

class _TutorAvailabilityManagerState extends State<TutorAvailabilityManager> {
  final DirectusService _directusService = DirectusService();
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  String? _error;

  // Add/Edit form state
  bool _showAddForm = false;
  Map<String, dynamic>? _editingAvailability;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isRecurring = true;
  DateTime? _specificDate;
  List<String> _selectedDays = [];

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

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
          _error = response['message'] ?? 'Failed to load availabilities';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading availabilities: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _startTime = null;
    _endTime = null;
    _isRecurring = true;
    _specificDate = null;
    _selectedDays = [];
    _editingAvailability = null;
    _showAddForm = false;
  }

  void _openAddForm() {
    _resetForm();
    setState(() {
      _showAddForm = true;
    });
  }

  void _openEditForm(Map<String, dynamic> availability) {
    setState(() {
      _editingAvailability = availability;
      _showAddForm = true;
      
      // Parse existing data
      _isRecurring = availability['recurring'] ?? true;
      
      // Parse time
      if (availability['start_time'] != null) {
        final startParts = availability['start_time'].split(':');
        _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
      }
      
      if (availability['end_time'] != null) {
        final endParts = availability['end_time'].split(':');
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      }
      
      // Parse days
      if (availability['day_of_week'] is List) {
        _selectedDays = List<String>.from(availability['day_of_week']);
      }
      
      // Parse specific date
      if (availability['specific_date'] != null && !_isRecurring) {
        _specificDate = DateTime.parse(availability['specific_date']);
      }
    });
  }

  Future<void> _saveAvailability() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
    final specificDateStr = _specificDate?.toIso8601String().split('T')[0];

    Map<String, dynamic> response;
    
    if (_editingAvailability != null) {
      // Update existing
      response = await _directusService.updateTutorAvailability(
        availabilityId: _editingAvailability!['id'].toString(),
        daysOfWeek: _selectedDays,
        startTime: startTimeStr,
        endTime: endTimeStr,
        recurring: _isRecurring,
        specificDate: specificDateStr,
      );
    } else {
      // Create new
      response = await _directusService.createTutorAvailability(
        tutorId: widget.tutorProfileId,
        daysOfWeek: _selectedDays,
        startTime: startTimeStr,
        endTime: endTimeStr,
        recurring: _isRecurring,
        specificDate: specificDateStr,
      );
    }

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingAvailability != null 
            ? 'Availability updated successfully' 
            : 'Availability added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
      _loadAvailabilities();
      widget.onAvailabilityChanged?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to save availability'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAvailability(String availabilityId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Availability'),
        content: const Text('Are you sure you want to delete this availability slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _directusService.deleteTutorAvailability(availabilityId);
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAvailabilities();
        widget.onAvailabilityChanged?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete availability'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimeString(String? timeString) {
    if (timeString == null) return '';
    return timeString.length >= 5 ? timeString.substring(0, 5) : timeString;
  }

  String _formatDayName(String? dayName) {
    if (dayName == null) return '';
    return dayName.length >= 3 ? dayName.substring(0, 3) : dayName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Availability Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.refresh, color: widget.primaryColor),
                  onPressed: _loadAvailabilities,
                  tooltip: 'Refresh',
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Slot'),
                  onPressed: _openAddForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Content
        if (_showAddForm) ...[
          _buildAddEditForm(),
          const SizedBox(height: 24),
        ],

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          _buildErrorWidget()
        else if (_availabilities.isEmpty)
          _buildEmptyState()
        else
          _buildAvailabilityList(),
      ],
    );
  }

  Widget _buildAddEditForm() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingAvailability != null ? 'Edit Availability' : 'Add New Availability',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showAddForm = false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: widget.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setState(() => _startTime = time);
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
                                _startTime?.format(context) ?? 'Select time',
                                style: TextStyle(
                                  color: _startTime != null ? Colors.black : widget.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: widget.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (time != null) {
                            setState(() => _endTime = time);
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
                                _endTime?.format(context) ?? 'Select time',
                                style: TextStyle(
                                  color: _endTime != null ? Colors.black : widget.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Days selection
            Text(
              'Days of Week',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: widget.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(_formatDayName(day)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                  selectedColor: widget.primaryColor.withOpacity(0.2),
                  checkmarkColor: widget.primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            Row(
              children: [
                Checkbox(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value ?? true;
                      if (_isRecurring) {
                        _specificDate = null;
                      }
                    });
                  },
                  activeColor: widget.primaryColor,
                ),
                Text(
                  'Recurring weekly',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: widget.secondaryTextColor,
                  ),
                ),
              ],
            ),

            // Specific date selection (if not recurring)
            if (!_isRecurring) ...[
              const SizedBox(height: 8),
              Text(
                'Specific Date',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: widget.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _specificDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _specificDate = date);
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
                      Icon(Icons.calendar_today, color: widget.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _specificDate != null 
                          ? '${_specificDate!.day}/${_specificDate!.month}/${_specificDate!.year}'
                          : 'Select date',
                        style: TextStyle(
                          color: _specificDate != null ? Colors.black : widget.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showAddForm = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAvailability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_editingAvailability != null ? 'Update' : 'Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityList() {
    return Column(
      children: _availabilities.map((availability) {
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Days
                    if (availability['day_of_week'] is List)
                      Wrap(
                        spacing: 4,
                        children: (availability['day_of_week'] as List)
                            .map((day) => Chip(
                                  label: Text(
                                    _formatDayName(day.toString()),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: widget.primaryColor.withOpacity(0.1),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 8),
                    
                    // Time
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: widget.secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatTimeString(availability['start_time'])} - ${_formatTimeString(availability['end_time'])}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: widget.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    
                    // Type and date
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          availability['recurring'] == true ? Icons.repeat : Icons.event,
                          size: 16,
                          color: widget.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          availability['recurring'] == true 
                            ? 'Recurring'
                            : 'One-time (${availability['specific_date'] ?? ''})',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: widget.primaryColor),
                    onPressed: () => _openEditForm(availability),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAvailability(availability['id'].toString()),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: widget.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No availability set',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your available times so students can book sessions with you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: widget.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.secondaryTextColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAvailabilities,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
} 