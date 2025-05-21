import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/Widgets/navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:turo/services/directus_service.dart';

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

  // Define navigation items - same as in homepage
  final List<NavBarItem> _navItems = [
    NavBarItem(icon: Icons.home, label: "Home"),
    NavBarItem(icon: Icons.search, label: "Search"),
    NavBarItem(icon: Icons.library_books_outlined, label: "My Courses"),
    NavBarItem(icon: Icons.person_outline, label: "Profile"),
  ];

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
        _imageFile = File(pickedImage.path);
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
      if (_imageFile != null) {
        final uploadResponse = await _directusService.uploadFile(_imageFile!);
        if (uploadResponse['success']) {
          avatarId = uploadResponse['data']['id'];
        } else {
          setState(() {
            _errorMessage = 'Failed to upload avatar: ${uploadResponse['message']}';
          });
          // Continue with the rest of the updates even if avatar upload fails
        }
      }

      // Update user data
      final userUpdateResponse = await authProvider.updateUserProfile({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'mode_preference': _selectedModePreference,
        'profile_complete': true,
        // Only include avatar if we have a new one
        if (avatarId != null) 'avatar': avatarId,
      });
      
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Profile' : 'My Profile',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Edit/Save button
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: Colors.orange,
            ),
            onPressed: _isLoading || _isSaving ? null : (_isEditing ? _saveProfile : _toggleEditMode),
          ),
          // Cancel button (only in edit mode)
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: _isSaving ? null : _toggleEditMode,
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadUserProfile,
            child: _buildContent(),
          ),
          
          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavBar(
              selectedIndex: _selectedMenuIndex,
              onItemSelected: _handleNavigation,
              items: _navItems,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Saving profile...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : _isEditing
              ? _buildEditProfileForm()
              : _buildProfileView(),
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header with Avatar and Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade400, Colors.orange.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 56,
                    backgroundImage: userData['avatar'] != null
                        ? NetworkImage(_directusService.getAssetUrl(userData['avatar']))
                        : null,
                    backgroundColor: Colors.orange.shade300,
                    child: userData['avatar'] == null
                        ? Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Name
                Text(
                  '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Email
                Text(
                  userData['email'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // User Type & Mode Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // User Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userData['user_type'] ?? 'Student',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mode Preference Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            userData['mode_preference'] == 'Online' ? Icons.computer : Icons.person_pin_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userData['mode_preference'] ?? 'Online',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        
        // Profile Info Section
        _buildSectionTitle('Location', Icons.location_on),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  userData['location'] ?? 'Not specified',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Education Section
        _buildSectionTitle('Education', Icons.school),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow(
                  label: 'Current Grade',
                  value: grade,
                  icon: Icons.school,
                ),
                const Divider(),
                _buildInfoRow(
                  label: 'Learning Level',
                  value: learnLevel,
                  icon: Icons.auto_stories,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // About Section
        _buildSectionTitle('About Me', Icons.person),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              userData['description'] ?? 'No description provided',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Learning Goals Section
        _buildSectionTitle('Learning Goals', Icons.emoji_events),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              learningGoals,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Subjects Section
        _buildSectionTitle('Subjects of Interest', Icons.category),
        subjectsList.isEmpty
            ? Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No subjects added yet',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjectsList.map<Widget>((subject) {
                  return Chip(
                    label: Text(subject.toString()),
                    backgroundColor: Colors.grey[200],
                    labelStyle: const TextStyle(color: Colors.black87),
                    avatar: const Icon(Icons.book, size: 16, color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
              ),
        
        const SizedBox(height: 24),
        
        // Enrolled Courses Section
        _buildSectionTitle('Enrolled Courses', Icons.school),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.book, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  '${userData['enrolled_courses'] is List ? userData['enrolled_courses'].length : 0} courses',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileForm() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar Edit
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageFile != null 
                    ? FileImage(_imageFile!) 
                    : (authProvider.fullUserProfile != null && 
                       authProvider.fullUserProfile!['avatar'] != null)
                        ? NetworkImage(_directusService.getAssetUrl(
                            authProvider.fullUserProfile!['avatar']))
                        : null,
                child: (_imageFile == null && (
                        authProvider.fullUserProfile == null || 
                        authProvider.fullUserProfile!['avatar'] == null))
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: InkWell(
                    onTap: _pickImage,
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Form Fields
        _buildFormSection('Personal Information', Icons.person),
        _buildTextField('First Name', _firstNameController),
        _buildTextField('Last Name', _lastNameController),
        _buildTextField('Email', _emailController, isEmail: true),
        _buildTextField('Location', _locationController),
        
        _buildFormSection('Education', Icons.school),
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
        
        _buildFormSection('Preferences', Icons.settings),
        _buildDropdown(
          'Mode Preference',
          _selectedModePreference,
          ['Online', 'In-person'],
          (value) => setState(() => _selectedModePreference = value!),
        ),
        
        _buildFormSection('About You', Icons.info_outline),
        _buildTextField('Description', _descriptionController, isMultiline: true, 
          hintText: 'Tell us about yourself, your interests, and your background.'),
        _buildTextField('Learning Goals', _learningGoalsController, isMultiline: true,
          hintText: 'What are you hoping to achieve through your learning journey?'),
        
        const SizedBox(height: 24),
        
        // Save button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Save Profile',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFormSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(),
        ],
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          labelStyle: TextStyle(color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.orange),
        dropdownColor: Colors.white,
      ),
    );
  }
} 