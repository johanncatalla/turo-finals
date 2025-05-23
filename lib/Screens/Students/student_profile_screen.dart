import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/Widgets/navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:turo/services/directus_service.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:fl_chart/fl_chart.dart';
import 'package:turo/Widgets/booking_management_widget.dart';

// --- Constants ---
const Color primaryOrange = Color(0xFFF9A825);
const Color primaryTeal = Color(0xFF3F8E9B);
const Color darkCharcoal = Color(0xFF303030);
const Color darkText = Color(0xFF303030);
const Color greyText = Color(0xFF616161);
const Color logoutRed = Color(0xFFE57373);
const Color chartBarColor = Color(0xFFF9A825);
const Color chartBarBackground = Color(0x4DF9A825);

// --- Scroll Behavior ---
class _MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch, PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus, PointerDeviceKind.mouse,
      };
}

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  int _selectedMenuIndex = 3; // Selected menu index for Profile
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;
  XFile? _webImageFile;
  final DirectusService _directusService = DirectusService();
  
  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _learningGoalsController;
  String _selectedGrade = 'College';
  String _selectedLearnLevel = 'College';
  String _selectedModePreference = 'Online';

  // Define navigation items
  final List<NavBarItem> _navItems = [
    NavBarItem(icon: Icons.home, label: "Home"),
    NavBarItem(icon: Icons.search, label: "Search"),
    NavBarItem(icon: Icons.library_books_outlined, label: "My Courses"),
    NavBarItem(icon: Icons.person_outline, label: "Profile"),
  ];
  
  // --- Error Builder ---
  Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    print("Error loading image: $error");
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 30),
    );
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _learningGoalsController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _learningGoalsController = TextEditingController();
  }

  // Load user profile data from auth provider
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.getFullUserProfile();
      
      if (response['success']) {
        final userData = authProvider.fullUserProfile!;
        
        setState(() {
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _locationController.text = userData['location'] ?? '';
          _descriptionController.text = userData['description'] ?? '';
          
          // Handle student profile data safely
          final studentProfile = userData['student_profile'];
          if (studentProfile is Map) {
            _learningGoalsController.text = studentProfile['learning_goals']?.toString() ?? '';
            _selectedGrade = studentProfile['grade']?.toString() ?? 'College';
            _selectedLearnLevel = studentProfile['learn_level']?.toString() ?? 'College';
          }
          
          _selectedModePreference = userData['mode_preference'] ?? 'Online';
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load profile';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleNavigation(int index) {
    if (index == _selectedMenuIndex) return;

    // Navigation logic
    switch (index) {
      case 0:
        // Navigate to Home page
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        // Navigate to search page
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        // Navigate to my courses
        Navigator.pushReplacementNamed(context, '/courses');
        break;
      case 3:
        // Already on Profile page
        break;
    }
  }

  void _toggleEditMode() {
    if (_isEditing) {
      // Reset form if canceling
      _loadUserProfile();
    }
    
    setState(() {
      _isEditing = !_isEditing;
      _errorMessage = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedImage != null) {
      setState(() {
        if (kIsWeb) {
          // For web, store the XFile directly
          _webImageFile = pickedImage;
        } else {
          // For native platforms, convert to File
          _imageFile = File(pickedImage.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = authProvider.fullUserProfile;
      
      if (userData == null) {
        setState(() {
          _errorMessage = 'User profile not loaded';
          _isSaving = false;
        });
        return;
      }

      // Upload avatar image if selected
      String? avatarId;
      if (kIsWeb && _webImageFile != null) {
        try {
          print('Uploading web file: ${_webImageFile!.name}');
          final uploadResponse = await _directusService.uploadFile(_webImageFile!);
          
          if (uploadResponse['success']) {
            print('Upload success, ID: ${uploadResponse['data']['id']}');
            avatarId = uploadResponse['data']['id'];
          } else {
            print('Upload failed: ${uploadResponse['message']}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload avatar: ${uploadResponse['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print('Error during web file upload: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading avatar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (!kIsWeb && _imageFile != null) {
        try {
          print('Uploading native file: ${_imageFile!.path}');
          final uploadResponse = await _directusService.uploadFile(_imageFile!);
          
          if (uploadResponse['success']) {
            print('Upload success, ID: ${uploadResponse['data']['id']}');
            avatarId = uploadResponse['data']['id'];
          } else {
            print('Upload failed: ${uploadResponse['message']}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload avatar: ${uploadResponse['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print('Error during native file upload: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading avatar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Update user data
      Map<String, dynamic> updateData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'mode_preference': _selectedModePreference,
        'profile_complete': true,
      };
      
      // Only include avatar if we have a new one
      if (avatarId != null) {
        updateData['avatar'] = avatarId;
      }
      
      final userUpdateResponse = await authProvider.updateUserProfile(updateData);
      
      if (!userUpdateResponse['success']) {
        setState(() {
          _errorMessage = userUpdateResponse['message'] ?? 'Failed to update user profile';
          _isSaving = false;
        });
        return;
      }

      // Update student profile if it exists and is a Map
      final studentProfile = userData['student_profile'];
      if (studentProfile is Map && studentProfile.containsKey('id')) {
        // Convert studentId to String to ensure type safety
        final studentId = studentProfile['id'].toString();
        final studentUpdateResponse = await authProvider.updateStudentProfile(
          studentId,
          {
            'grade': _selectedGrade,
            'learn_level': _selectedLearnLevel,
            'learning_goals': _learningGoalsController.text,
          },
        );
        
        if (!studentUpdateResponse['success']) {
          setState(() {
            _errorMessage = studentUpdateResponse['message'] ?? 'Failed to update student profile';
          });
        }
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Exit edit mode
      setState(() {
        _isEditing = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back, color: darkText),
          onPressed: () => Navigator.pop(context)
        ) : null,
        title: Text(
          _isEditing ? 'Edit Profile' : 'Profile',
          style: const TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        actions: [
          // Refresh button
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: primaryOrange),
              onPressed: _loadUserProfile,
              tooltip: 'Refresh Profile',
            ),
          // Edit/Save button
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit_outlined,
              color: primaryOrange,
              size: 24,
            ),
            onPressed: _isLoading || _isSaving ? null : (_isEditing ? _saveProfile : _toggleEditMode),
          ),
          // Cancel button (only in edit mode)
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: greyText, size: 24),
              onPressed: _isSaving ? null : _toggleEditMode,
            ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        child: _buildSettingsDrawerContent(context),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        selectedIndex: _selectedMenuIndex,
        onItemSelected: _handleNavigation,
        selectedColor: primaryOrange,
        unselectedColor: Colors.white60,
        backgroundColor: darkCharcoal,
      ),
      body: _isLoading ? 
        const Center(child: CircularProgressIndicator(color: primaryOrange)) : 
        (_errorMessage != null ? 
          _buildErrorState() : 
          ScrollConfiguration(
            behavior: _MyCustomScrollBehavior(),
            child: RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: primaryOrange,
              child: SingleChildScrollView(
                child: _isSaving ? 
                  _buildSavingState() : 
                  (_isEditing ? _buildEditProfileForm() : _buildProfileView()),
              ),
            ),
          )
        ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Error loading profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: greyText, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSavingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryOrange),
            const SizedBox(height: 16),
            const Text(
              'Saving profile...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsDrawerContent(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),

        ListTile(
          leading: const Icon(Icons.account_circle_outlined, color: greyText),
          title: const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account Settings'), duration: Duration(seconds: 1))
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        ListTile(
          leading: const Icon(Icons.tune_outlined, color: greyText),
          title: const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preferences'), duration: Duration(seconds: 1))
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined, color: greyText),
          title: const Text('Privacy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy Settings'), duration: Duration(seconds: 1))
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        ListTile(
          leading: const Icon(Icons.info_outline, color: greyText),
          title: const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText)),
          onTap: () {
            Navigator.pop(context);
            showAboutDialog(
              context: context,
              applicationName: 'Turo App',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 Turo',
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 24.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: logoutRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.2),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              // Navigate to role selection screen
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.fullUserProfile;
    
    if (userData == null) {
      return const Center(child: Text('No profile data available'));
    }

    // Safely handle student profile data
    final studentProfile = userData['student_profile'];
    final subjects = userData['subjects'];
    
    // Extract values safely
    final String grade = studentProfile is Map ? (studentProfile['grade']?.toString() ?? 'Not specified') : 'Not specified';
    final String learnLevel = studentProfile is Map ? (studentProfile['learn_level']?.toString() ?? 'Not specified') : 'Not specified';
    final String learningGoals = studentProfile is Map ? (studentProfile['learning_goals']?.toString() ?? 'No learning goals provided') : 'No learning goals provided';
    final List subjectsList = subjects is List ? subjects : [];
    
    // Get the enrolled courses
    final enrolledCourses = userData['enrolled_courses'] is List ? userData['enrolled_courses'] : [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile header with cover image and avatar
        _buildProfileHeader(userData),
        
        const SizedBox(height: 20),
        
        // Learner Badges section (placeholder)
        _buildLearnerBadgesSection(context),
        
        const SizedBox(height: 24),
        
        // My Courses Section (using real enrolled courses)
        _buildMyCoursesSection(context, enrolledCourses),
        
        const SizedBox(height: 24),
        
        // My Bookings Section
        _buildMyBookingsSection(context),
        
        const SizedBox(height: 24),
        
        // User Information Sections - Improved layout with cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Section
              _buildDetailCard(
                'Location', 
                Icons.location_on_outlined, 
                [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: primaryTeal, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            userData['location'] ?? 'Not specified',
                            style: const TextStyle(fontSize: 16, color: darkText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ),
              
              const SizedBox(height: 20),
              
              // Education Section
              _buildDetailCard(
                'Education', 
                Icons.school_outlined, 
                [
                  _buildDetailItem('Current Grade', grade),
                  const Divider(height: 20),
                  _buildDetailItem('Learning Level', learnLevel),
                ]
              ),
              
              const SizedBox(height: 20),
              
              // About Me Section
              _buildDetailCard(
                'About Me', 
                Icons.person_outline, 
                [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      userData['description'] ?? 'No description provided',
                      style: const TextStyle(fontSize: 16, color: darkText, height: 1.4),
                    ),
                  ),
                ]
              ),
              
              const SizedBox(height: 20),
              
              // Learning Goals Section
              _buildDetailCard(
                'Learning Goals', 
                Icons.emoji_events_outlined, 
                [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      learningGoals,
                      style: const TextStyle(fontSize: 16, color: darkText, height: 1.4),
                    ),
                  ),
                ]
              ),
              
              const SizedBox(height: 20),
              
              // Subjects of Interest Section
              _buildDetailCard(
                'Subjects of Interest', 
                Icons.category_outlined, 
                [
                  subjectsList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No subjects added yet',
                          style: TextStyle(fontSize: 16, color: greyText),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: subjectsList.map<Widget>((subject) {
                            return Chip(
                              label: Text(subject.toString()),
                              backgroundColor: primaryTeal.withOpacity(0.08),
                              labelStyle: TextStyle(color: primaryTeal.withOpacity(0.9), fontSize: 13),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: const VisualDensity(horizontal: 0.0, vertical: -2),
                            );
                          }).toList(),
                        ),
                      ),
                ]
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Progress Report section (placeholder)
        _buildProgressReportsSection(context),
        
        const SizedBox(height: 24),
      ],
    );
  }

  // Helper method to build a detail card with consistent styling
  Widget _buildDetailCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }
  
  // Helper method to build a detail item with label and value
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            // Cover image
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.asset(
                'assets/cover.png',
                fit: BoxFit.cover,
                errorBuilder: _imageErrorBuilder,
              ),
            ),
            // Profile image
            Positioned(
              bottom: -35,
              left: 20,
              child: CircleAvatar(
                radius: 47,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: userData['avatar'] != null
                    ? NetworkImage(_directusService.getAssetUrl(userData['avatar']))
                    : const AssetImage('assets/student1.png') as ImageProvider,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading profile image: $exception');
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 55),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: primaryOrange, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData['description'] ?? 'No description provided',
                      style: const TextStyle(color: greyText, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _toggleEditMode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryOrange,
                  side: const BorderSide(color: primaryOrange, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 34),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFEEEEEE), height: 1),
      ],
    );
  }

  Widget _buildLearnerBadgesSection(BuildContext context) {
    // Placeholder badges
    const badgeAssets = ['assets/b1.png', 'assets/b2.png', 'assets/b3.png', 'assets/b4.png', 'assets/b5.png'];
    const int maxBadgesToShow = 5;
    final List<String> badgesToShow = badgeAssets.take(maxBadgesToShow).toList();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))
        ],
        border: Border.all(color: const Color(0xFFEEEEEE))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: primaryOrange,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12.0), topRight: Radius.circular(12.0))
            ),
            child: const Center(
              child: Text(
                'Learner Badges',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ...badgesToShow.map((badge) => _buildBadgeItem(context, badge)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, String badgePath) {
    const double badgeSize = 45.0;
    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: Image.asset(
        badgePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading badge image: $badgePath, $error");
          return Container(
            width: badgeSize, height: badgeSize,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(badgeSize / 2)
            ),
            child: Icon(Icons.emoji_events_outlined, color: Colors.grey[400], size: 25),
          );
        },
      ),
    );
  }

  Widget _buildMyCoursesSection(BuildContext context, List enrolledCourses) {
    // Transform the enrolledCourses data to handle the junction table format
    List<Map<String, dynamic>> processedCourses = [];
    
    for (var courseEntry in enrolledCourses) {
      if (courseEntry is Map<String, dynamic>) {
        // Check if this is a direct course object or a junction table entry
        if (courseEntry.containsKey('Courses_id') && courseEntry['Courses_id'] is Map<String, dynamic>) {
          // This is a junction table entry - extract the course data
          processedCourses.add(courseEntry['Courses_id']);
        } else {
          // This is already a course object
          processedCourses.add(courseEntry);
        }
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 12),
          if (processedCourses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Text('No courses enrolled yet.', style: TextStyle(color: greyText))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: processedCourses.length.clamp(0, 3), // Show up to 3 courses
              itemBuilder: (context, index) {
                return _buildCourseCard(context, processedCourses[index]);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          if (processedCourses.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/courses');
                },
                child: const Text('See All Courses', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.grey.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to course details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course image
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: _getCourseImage(course, 85, 85),
              ),
              const SizedBox(width: 12),
              // Course details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'] ?? 'Untitled Course',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['description'] ?? 'No description available',
                      style: const TextStyle(fontSize: 13, color: greyText, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 16, color: greyText),
                        const SizedBox(width: 4),
                        Text(
                          course['duration'] ?? '1hr/day',
                          style: const TextStyle(fontSize: 12, color: greyText),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline, size: 16, color: greyText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getInstructorName(course),
                            style: const TextStyle(fontSize: 12, color: greyText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to handle different course image data structures
  Widget _getCourseImage(Map<String, dynamic> course, double width, double height) {
    String? imageId;
    
    // Check different possible structures for course_image
    if (course['course_image'] != null) {
      if (course['course_image'] is Map) {
        // If it's a Map with an 'id' field
        imageId = course['course_image']['id']?.toString();
      } else if (course['course_image'] is String) {
        // If it's directly a String
        imageId = course['course_image'];
      }
    }
    
    // If we're in a junction item structure (Courses_id nested object)
    if (imageId == null && course['Courses_id'] != null && course['Courses_id'] is Map) {
      final nestedCourse = course['Courses_id'];
      if (nestedCourse['course_image'] != null) {
        if (nestedCourse['course_image'] is Map) {
          imageId = nestedCourse['course_image']['id']?.toString();
        } else if (nestedCourse['course_image'] is String) {
          imageId = nestedCourse['course_image'];
        }
      }
    }
    
    // Fallback to 'image' field if course_image not found
    if (imageId == null && course['image'] != null && !course['image'].toString().startsWith('assets/')) {
      imageId = course['image'].toString();
    }
    
    // Debug image path
    print('Course ${course['title']}: Image ID = $imageId');
    
    if (imageId != null) {
      return Image.network(
        _directusService.getAssetUrl(imageId),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading course image: $error');
          return Image.asset(
            'assets/courses/python.png',
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.asset(
        'assets/courses/python.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
  }

  String _getInstructorName(Map<String, dynamic> course) {
    // Try to extract instructor name from different possible structures
    if (course['tutor_id'] != null && course['tutor_id'] is Map) {
      final tutor = course['tutor_id'];
      
      // If tutor has a user_id that's expanded
      if (tutor['user_id'] != null && tutor['user_id'] is Map) {
        final user = tutor['user_id'];
        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        return '$firstName $lastName'.trim();
      }
      
      // If tutor has a name directly
      if (tutor['name'] != null) {
        return tutor['name'];
      }
    }
    
    // Fallback to any instructor related fields
    return course['instructorName'] ?? course['instructorFirstName'] ?? 'Instructor';
  }

  Widget _buildMyBookingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          BookingManagementWidget(
            userRole: 'student',
            primaryColor: primaryOrange,
            secondaryTextColor: greyText,
            cardBackgroundColor: Colors.white,
            shadowColor: Colors.grey,
            borderColor: Colors.grey.shade300,
            onBookingChanged: () {
              // Optional: Refresh data if needed
              print('Student booking changed');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressReportsSection(BuildContext context) {
    // Create a placeholder progress report
    final report = {
      'tutorName': 'Joshua Perez',
      'tutorImageUrl': 'assets/Joshua.png',
      'subjects': ['English', 'Filipino', 'Literature'],
      'overallRating': 4.8,
      'comment': 'An exemplary student showing dedication to learning, active participation in class, and a strong work ethic.',
      'progressPercent': 85,
      'weeklyProgress': [0.2, 0.25, 0.4, 0.7, 0.6, 0.85, 0.95],
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
          child: Text('Learning Progress Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
        ),
        SizedBox(
          height: 380,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: 1, // Just one placeholder report
            itemBuilder: (context, index) {
              return _buildProgressReportCard(context, report);
            },
            separatorBuilder: (context, index) => const SizedBox(width: 12),
          ),
        ),
      ]
    );
  }

  Widget _buildProgressReportCard(BuildContext context, Map<String, dynamic> report) {
    const double barWidth = 16;
    final BorderRadius barBorderRadius = const BorderRadius.vertical(top: Radius.circular(4));
    final List<double> weeklyProgress = List<double>.from(report['weeklyProgress']);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.grey.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(report['tutorImageUrl']),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                report['tutorName'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkText),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: primaryTeal, size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4.0,
                          runSpacing: 4.0,
                          children: [
                            for (var subject in (report['subjects'] as List).take(2))
                              Chip(
                                label: Text(subject),
                                labelStyle: TextStyle(fontSize: 9, color: primaryTeal.withOpacity(0.9)),
                                backgroundColor: primaryTeal.withOpacity(0.08),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(horizontal: 0.0, vertical: -4),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                side: BorderSide.none,
                              ),
                            if ((report['subjects'] as List).length > 2)
                              Chip(
                                label: Text('+${(report['subjects'] as List).length - 2} more'),
                                labelStyle: const TextStyle(fontSize: 9, color: greyText),
                                backgroundColor: Colors.grey.withOpacity(0.1),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(horizontal: 0.0, vertical: -4),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < report['overallRating'].floor() ? Icons.star_rounded
                              : (i < report['overallRating'] ? Icons.star_half_rounded : Icons.star_border_rounded),
                              color: primaryOrange,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report['overallRating'].toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, color: greyText, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFEEEEEE)),
              const SizedBox(height: 10),
              Text(
                report['comment'],
                style: const TextStyle(fontSize: 13, color: greyText, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.only(top: 10.0, left: 5, right: 10, bottom: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Weekly Class Progress", style: TextStyle(fontSize: 11, color: greyText.withOpacity(0.8))),
                          const SizedBox(height: 1),
                          Text(
                            report['progressPercent'] >= 80 ? "Excellent!" : (report['progressPercent'] >= 60 ? "Good Progress" : "Needs Improvement"),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText)
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 130,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 1.0,
                          minY: 0,
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  String text = '';
                                  switch (value.toInt()) {
                                    case 0: text = 'M'; break; case 1: text = 'T'; break; case 2: text = 'W'; break;
                                    case 3: text = 'Th'; break; case 4: text = 'F'; break; case 5: text = 'Sa'; break;
                                    case 6: text = 'Su'; break;
                                    default: text = '';
                                  }
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 4,
                                    child: Text(text, style: const TextStyle(color: greyText, fontWeight: FontWeight.w500, fontSize: 10)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                interval: 0.5,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  String text;
                                  if (value == 0) text = '0%';
                                  else if (value == 0.5) text = '50%';
                                  else if (value == 1) text = '100%';
                                  else return Container();
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 4,
                                    child: Text(text, style: const TextStyle(color: greyText, fontWeight: FontWeight.w500, fontSize: 10)),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                              dashArray: [3, 3],
                            ),
                            checkToShowHorizontalLine: (value) => value == 0.5 || value == 1.0,
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                              left: BorderSide(color: Colors.grey[300]!, width: 1),
                              top: BorderSide.none,
                              right: BorderSide.none,
                            )
                          ),
                          barGroups: List.generate(
                            weeklyProgress.length.clamp(0, 7),
                            (index) {
                              final double barY = weeklyProgress[index].clamp(0.0, 1.0);
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: barY,
                                    color: chartBarColor,
                                    width: barWidth,
                                    borderRadius: barBorderRadius,
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 1.0,
                                      color: chartBarBackground,
                                    )
                                  ),
                                ],
                              );
                            },
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: const Color(0xFF2C3E50),
                              tooltipPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                if (groupIndex < 0 || groupIndex >= weeklyProgress.length) {
                                  return null;
                                }
                                final dayProgressPercent = (weeklyProgress[groupIndex] * 100).toStringAsFixed(0);
                                String day = '';
                                switch (groupIndex) {
                                  case 0: day = 'Mon'; break; case 1: day = 'Tue'; break; case 2: day = 'Wed'; break;
                                  case 3: day = 'Thu'; break; case 4: day = 'Fri'; break; case 5: day = 'Sat'; break;
                                  case 6: day = 'Sun'; break;
                                  default: return null;
                                }
                                return BarTooltipItem(
                                  '$day: $dayProgressPercent%',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get the profile image  
  ImageProvider? _getProfileImage(AuthProvider authProvider) {
    if (kIsWeb && _webImageFile != null) {
      // For web, we can create a network image from the XFile
      return NetworkImage(_webImageFile!.path);
    } else if (!kIsWeb && _imageFile != null) {
      // For native platforms, use FileImage
      return FileImage(_imageFile!);
    } else if (authProvider.fullUserProfile != null && 
              authProvider.fullUserProfile!['avatar'] != null) {
      // Use the existing avatar
      return NetworkImage(_directusService.getAssetUrl(
          authProvider.fullUserProfile!['avatar']));
    }
    return null;
  }
  
  Widget _buildEditProfileForm() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Edit
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _getProfileImage(authProvider),
                  child: (_imageFile == null && _webImageFile == null && (
                          authProvider.fullUserProfile == null || 
                          authProvider.fullUserProfile!['avatar'] == null))
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: InkWell(
                      onTap: _pickImage,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Form Fields with card-based styling
          _buildFormCard(
            'Personal Information', 
            Icons.person,
            [
              _buildTextField('First Name', _firstNameController),
              _buildTextField('Last Name', _lastNameController),
              _buildTextField('Email', _emailController, isEmail: true),
              _buildTextField('Location', _locationController),
            ]
          ),
          
          const SizedBox(height: 24),
          
          _buildFormCard(
            'Education', 
            Icons.school,
            [
              _buildDropdown(
                'Grade',
                _selectedGrade,
                ['Elementary', 'High School', 'College'],
                (value) => setState(() => _selectedGrade = value!),
              ),
              _buildDropdown(
                'Learning Level',
                _selectedLearnLevel,
                ['Elementary', 'High School', 'College'],
                (value) => setState(() => _selectedLearnLevel = value!),
              ),
            ]
          ),
          
          const SizedBox(height: 24),
          
          _buildFormCard(
            'Preferences', 
            Icons.settings,
            [
              _buildDropdown(
                'Mode Preference',
                _selectedModePreference,
                ['Online', 'In-person'],
                (value) => setState(() => _selectedModePreference = value!),
              ),
            ]
          ),
          
          const SizedBox(height: 24),
          
          _buildFormCard(
            'About You', 
            Icons.info_outline,
            [
              _buildTextField('Description', _descriptionController, isMultiline: true, 
                hintText: 'Tell us about yourself, your interests, and your background.'),
              _buildTextField('Learning Goals', _learningGoalsController, isMultiline: true,
                hintText: 'What are you hoping to achieve through your learning journey?'),
            ]
          ),
          
          const SizedBox(height: 30),
          
          // Save button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Save Profile'),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFormCard(String title, IconData icon, List<Widget> fields) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,    
    TextEditingController controller,    
    {bool isEmail = false,    
    bool isMultiline = false,   
    String? hintText, 
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : (isMultiline ? TextInputType.multiline : TextInputType.text),
        maxLines: isMultiline ? 4 : 1,
        style: const TextStyle(fontSize: 16, color: darkText),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: const TextStyle(color: greyText, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryOrange, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: greyText, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryOrange, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down_circle, color: primaryOrange),
        dropdownColor: Colors.white,
      ),
    );
  }
} 