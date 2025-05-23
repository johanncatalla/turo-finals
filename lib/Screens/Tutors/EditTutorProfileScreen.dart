// edit_tutor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../providers/auth_provider.dart';
import '../../services/directus_service.dart';

// --- Constants ---
const Color primaryTeal = Color(0xFF3F8E9B);
const Color darkText = Color(0xFF303030);
const Color greyText = Color(0xFF616161);
// const Color logoutRed = Color(0xFFE57373); // Not used in this screen
// const Color chartBarColor = Color(0xFFF9A825); // Not used
// const Color chartBarBackground = Color(0x4DF9A825); // Not used


class EditTutorProfileScreen extends StatefulWidget {
  const EditTutorProfileScreen({Key? key}) : super(key: key);

  @override
  _EditTutorProfileScreenState createState() => _EditTutorProfileScreenState();
}

class _EditTutorProfileScreenState extends State<EditTutorProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  File? _imageFile;
  XFile? _webImageFile;

  final DirectusService _directusService = DirectusService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _educationController;
  late TextEditingController _hourRateController;

  String _selectedTeachLevelsDisplay = 'Not specified';
  List<String> _selectedSubjectsDisplay = [];

  // To store the ID of the tutor_profiles item for updating
  String? _loadedTutorProfileItemId;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadTutorProfile();
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _educationController = TextEditingController();
    _hourRateController = TextEditingController();
  }

  Future<void> _loadTutorProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadedTutorProfileItemId = null; // Reset on each load
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      if (currentUserId == null) {
        _errorMessage = "User not authenticated.";
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await _directusService.fetchTutorProfileByUserId(currentUserId);
      Map<String, dynamic>? fullUserData;

      if (mounted) {
        if (response['success']) {
          fullUserData = response['data'];

          if (fullUserData != null) {
            _firstNameController.text = fullUserData['first_name'] ?? '';
            _lastNameController.text = fullUserData['last_name'] ?? '';
            _emailController.text = fullUserData['email'] ?? '';

            final tutorProfileData = fullUserData['tutor_profile'];
            // print('Raw tutor_profile data from service: $tutorProfileData');

            Map<dynamic, dynamic>? effectiveTutorProfile;

            if (tutorProfileData is List && tutorProfileData.isNotEmpty) {
              if (tutorProfileData[0] is Map) {
                effectiveTutorProfile = tutorProfileData[0] as Map<dynamic, dynamic>;
              }
            } else if (tutorProfileData is Map) {
              effectiveTutorProfile = tutorProfileData;
            }

            // print('Effective Tutor Profile for UI: $effectiveTutorProfile');

            if (effectiveTutorProfile != null) {
              _loadedTutorProfileItemId = effectiveTutorProfile['id']?.toString();
              // print('Loaded Tutor Profile Item ID: $_loadedTutorProfileItemId');


              _bioController.text = effectiveTutorProfile['bio'] ?? '';
              _educationController.text = effectiveTutorProfile['education_background'] ?? '';
              _hourRateController.text = effectiveTutorProfile['hour_rate']?.toString() ?? '';

              // Teach Levels
              if (effectiveTutorProfile['teach_levels'] != null) {
                if (effectiveTutorProfile['teach_levels'] is List) {
                  _selectedTeachLevelsDisplay = (effectiveTutorProfile['teach_levels'] as List)
                      .map((level) {
                    if (level is Map && level.containsKey('TeachLevels_id') && level['TeachLevels_id'] is Map) {
                      return level['TeachLevels_id']['name']?.toString() ?? '';
                    }
                    return level.toString();
                  })
                      .where((name) => name.isNotEmpty)
                      .join(', ');
                  if (_selectedTeachLevelsDisplay.isEmpty) _selectedTeachLevelsDisplay = 'Not specified';
                } else {
                  _selectedTeachLevelsDisplay = effectiveTutorProfile['teach_levels'].toString();
                }
              } else {
                _selectedTeachLevelsDisplay = 'Not specified';
              }

              // Subjects
              if (effectiveTutorProfile['subjects'] != null && effectiveTutorProfile['subjects'] is List) {
                _selectedSubjectsDisplay = List<String>.from(
                    (effectiveTutorProfile['subjects'] as List).map((s) {
                      if (s is Map) {
                        final subjectDetails = s['Subjects_id'];
                        if (subjectDetails is Map && subjectDetails.containsKey('subject_name')) {
                          return subjectDetails['subject_name']?.toString() ?? '';
                        }
                        return s['name']?.toString() ?? '';
                      }
                      return s.toString();
                    }).where((s_name) => s_name.isNotEmpty));
              } else {
                _selectedSubjectsDisplay = [];
              }
            } else {
              _bioController.text = '';
              _educationController.text = '';
              _hourRateController.text = '';
              _selectedTeachLevelsDisplay = 'Not specified';
              _selectedSubjectsDisplay = [];
              _errorMessage = 'Tutor specific details (e.g., bio, education) could not be loaded from profile.';
              // print("Debug: effectiveTutorProfile is null after parsing.");
            }
          } else { // fullUserData is null
            _errorMessage = 'Main tutor profile data not found in response.';
          }
        } else { // response not successful
          _errorMessage = response['message'] ?? 'Failed to load profile (service error).';
        }
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = 'An error occurred: $e';
        // print("Error in _loadTutorProfile: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _hourRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedImage != null) {
      setState(() {
        if (kIsWeb) {
          _webImageFile = pickedImage;
        } else {
          _imageFile = File(pickedImage.path);
        }
      });
    }
  }

  ImageProvider? _getProfileImagePreview(AuthProvider authProvider) {
    if (kIsWeb && _webImageFile != null) {
      return NetworkImage(_webImageFile!.path);
    } else if (!kIsWeb && _imageFile != null) {
      return FileImage(_imageFile!);
    } else if (authProvider.fullUserProfile != null && // Check fullUserProfile from provider as fallback
        authProvider.fullUserProfile!['avatar'] != null) {
      return NetworkImage(
          _directusService.getAssetUrl(authProvider.fullUserProfile!['avatar']));
    }
    // Fallback if no image is picked and no avatar in provider state
    // Could also try to get avatar from the initially loaded `fullUserData` if needed,
    // but provider should be the source of truth after load.
    return const AssetImage('assets/profile.png');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id; // Used for updating the main user record
      if (currentUserId == null) {
        throw Exception('User not authenticated.');
      }

      String? newAvatarId;
      if (kIsWeb && _webImageFile != null) {
        final uploadResponse = await _directusService.uploadFile(_webImageFile!);
        if (uploadResponse['success']) {
          newAvatarId = uploadResponse['data']['id'];
        } else {
          throw Exception('Failed to upload avatar: ${uploadResponse['message']}');
        }
      } else if (!kIsWeb && _imageFile != null) {
        final uploadResponse = await _directusService.uploadFile(_imageFile!);
        if (uploadResponse['success']) {
          newAvatarId = uploadResponse['data']['id'];
        } else {
          throw Exception('Failed to upload avatar: ${uploadResponse['message']}');
        }
      }

      Map<String, dynamic> userUpdateData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
      };
      if (newAvatarId != null) {
        userUpdateData['avatar'] = newAvatarId;
      }

      // Update main user data (directus_users collection)
      // This is now handled by AuthProvider to ensure its internal state is also updated.
      final userUpdateResponse = await authProvider.updateUserProfile(userUpdateData);
      if (!userUpdateResponse['success']) {
        throw Exception('Failed to update user profile: ${userUpdateResponse['message']}');
      }

      // Update tutor_profile specific data (e.g., tutor_profiles collection)
      if (_loadedTutorProfileItemId != null) {
        Map<String, dynamic> tutorProfileUpdateData = {
          'bio': _bioController.text,
          'education_background': _educationController.text,
          'hour_rate': double.tryParse(_hourRateController.text),
          // TODO: For teach_levels and subjects, you need to convert
          // _selectedTeachLevelsDisplay (String) and _selectedSubjectsDisplay (List<String>)
          // back into the format Directus expects for these fields (e.g., List of IDs).
          // This requires knowing your Directus schema for these relations.
          // Example: if 'subjects' on tutor_profile is a M2M relation expecting an array of subject IDs:
          // 'subjects': [ {'id': 'subject_id_1'}, {'id': 'subject_id_2'} ] // or just ['id1', 'id2']
          // You would need to fetch subject IDs based on names if you only store names.
        };

        final tutorProfileUpdateResponse = await _directusService.updateTutorProfile(
            _loadedTutorProfileItemId!,
            tutorProfileUpdateData
        );
        if (!tutorProfileUpdateResponse['success']) {
          throw Exception('Failed to update tutor details: ${tutorProfileUpdateResponse['message']}');
        }
      } else {
        print("Warning: Tutor profile item ID (_loadedTutorProfileItemId) is null. "
            "Cannot update tutor-specific details like bio, education, etc. "
            "This might mean the tutor does not have an existing extended profile record, "
            "or there was an issue loading it.");
        // Depending on your app logic, you might want to create a tutor_profile record here
        // if one doesn't exist, or show a more specific error.
      }

      // Crucial: Refresh the full user profile in AuthProvider so that
      // TutorProfileScreen and other parts of the app see the latest data.
      await authProvider.getFullUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Pop and indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          // print("Error in _saveProfile: $e");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tutor Profile', style: TextStyle(color: darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkText),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: primaryTeal), // Changed to primaryTeal for consistency
              onPressed: _isLoading ? null : _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                ),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _getProfileImagePreview(authProvider),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: primaryTeal, // Changed to primaryTeal
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(_firstNameController, 'First Name'),
              _buildTextField(_lastNameController, 'Last Name'),
              _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              const Text("Tutor Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
              const Divider(height: 20),
              _buildTextField(_bioController, 'Bio (About You)', maxLines: 3),
              _buildTextField(_educationController, 'Education Background', maxLines: 2),
              _buildTextField(_hourRateController, 'Hourly Rate (e.g., 500)', keyboardType: TextInputType.number),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Teaching Levels: $_selectedTeachLevelsDisplay (Edit UI Needed)", style: const TextStyle(color: greyText)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Subjects: ${_selectedSubjectsDisplay.join(', ')} (Edit UI Needed)", style: const TextStyle(color: greyText)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving || _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal, // Changed to primaryTeal
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: greyText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: primaryTeal, width: 2), // Changed to primaryTeal
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Email' && !value.contains('@')) {
            return 'Please enter a valid email';
          }
          if (label.toLowerCase().contains('rate') && double.tryParse(value) == null) {
            return 'Please enter a valid number for the rate';
          }
          return null;
        },
      ),
    );
  }
}