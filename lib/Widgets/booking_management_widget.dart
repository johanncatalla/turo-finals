import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/services/directus_service.dart';

class BookingManagementWidget extends StatefulWidget {
  final String? userRole; // 'student', 'tutor', or null for both
  final Color primaryColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color shadowColor;
  final Color borderColor;
  final VoidCallback? onBookingChanged;

  const BookingManagementWidget({
    super.key,
    this.userRole,
    this.primaryColor = const Color(0xFF53C6D9),
    this.secondaryTextColor = Colors.grey,
    this.cardBackgroundColor = Colors.white,
    this.shadowColor = Colors.grey,
    this.borderColor = Colors.grey,
    this.onBookingChanged,
  });

  @override
  State<BookingManagementWidget> createState() => _BookingManagementWidgetState();
}

class _BookingManagementWidgetState extends State<BookingManagementWidget> {
  final DirectusService _directusService = DirectusService();
  
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = ['All', 'Pending', 'Active', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _directusService.getUserBookings(
        user.id,
        role: widget.userRole,
      );
      
      if (response['success']) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading bookings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_selectedFilter == 'All') {
      return _bookings;
    }
    return _bookings.where((booking) => booking['status'] == _selectedFilter).toList();
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final response = await _directusService.updateBookingStatus(bookingId, newStatus);
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadBookings(); // Refresh the list
        widget.onBookingChanged?.call();
      } else {
        throw Exception(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePaymentStatus(String bookingId, String newPaymentStatus) async {
    try {
      final response = await _directusService.updatePaymentStatus(bookingId, newPaymentStatus);
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment status updated to $newPaymentStatus'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadBookings(); // Refresh the list
        widget.onBookingChanged?.call();
      } else {
        throw Exception(response['message'] ?? 'Failed to update payment status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking? This action cannot be undone.'),
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

    if (confirmed == true) {
      try {
        final response = await _directusService.deleteBooking(bookingId);
        
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          _loadBookings(); // Refresh the list
          widget.onBookingChanged?.call();
        } else {
          throw Exception(response['message'] ?? 'Failed to delete booking');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'Unknown';
    
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final time = TimeOfDay(hour: hour, minute: minute);
        return time.format(context);
      }
    } catch (e) {
      // Return original string if parsing fails
    }
    
    return timeString.substring(0, timeString.length >= 5 ? 5 : timeString.length);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return widget.secondaryTextColor;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      default:
        return widget.secondaryTextColor;
    }
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
              'My Bookings',
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
                  onPressed: _loadBookings,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filterOptions.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: widget.primaryColor.withOpacity(0.2),
                  checkmarkColor: widget.primaryColor,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Content
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          _buildErrorWidget()
        else if (_filteredBookings.isEmpty)
          _buildEmptyState()
        else
          _buildBookingsList(),
      ],
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
            onPressed: _loadBookings,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: widget.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All' 
                ? 'You haven\'t made any bookings yet.'
                : 'No bookings with status "$_selectedFilter".',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return Column(
      children: _filteredBookings.map((booking) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking #${booking['id']?.toString().substring(0, 8) ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking['status'] ?? '').withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking['status'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(booking['status'] ?? ''),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor(booking['payment_status'] ?? '').withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking['payment_status'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPaymentStatusColor(booking['payment_status'] ?? ''),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course and Participants
                    if (booking['course_id'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.school, size: 16, color: widget.secondaryTextColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking['course_id']['title'] ?? 'Unknown Course',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Client and Tutor info
                    if (booking['client_id'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: widget.secondaryTextColor),
                          const SizedBox(width: 8),
                          Text(
                            'Student: ${booking['client_id']['first_name']} ${booking['client_id']['last_name']}',
                            style: TextStyle(
                              color: widget.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (booking['tutor_id'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: widget.secondaryTextColor),
                          const SizedBox(width: 8),
                          Text(
                            'Tutor: ${booking['tutor_id']['first_name']} ${booking['tutor_id']['last_name']}',
                            style: TextStyle(
                              color: widget.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Booking details
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: widget.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text(
                          '${booking['total_hours']} hours • ${booking['mode']} • ₱${booking['total_cost']?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: widget.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Dates
                    if (booking['dates'] != null && booking['dates'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Scheduled Dates:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: widget.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...List.generate(
                        (booking['dates'] as List).length > 3 ? 3 : booking['dates'].length,
                        (index) {
                          final date = booking['dates'][index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• ${_formatDate(date['date'])} ${_formatTime(date['start_time'])} - ${_formatTime(date['end_time'])}',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.secondaryTextColor,
                              ),
                            ),
                          );
                        },
                      ),
                      if (booking['dates'].length > 3) 
                        Text(
                          '... and ${booking['dates'].length - 3} more',
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.secondaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        if (booking['status'] == 'Pending') ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateBookingStatus(
                                booking['id'].toString(),
                                'Active',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                              ),
                              child: const Text('Accept', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        if (booking['status'] == 'Active') ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateBookingStatus(
                                booking['id'].toString(),
                                'Completed',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                              ),
                              child: const Text('Complete', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        if (booking['payment_status'] == 'Unpaid') ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updatePaymentStatus(
                                booking['id'].toString(),
                                'Paid',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: widget.primaryColor,
                                side: BorderSide(color: widget.primaryColor),
                              ),
                              child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _deleteBooking(booking['id'].toString()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Delete', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
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
} 