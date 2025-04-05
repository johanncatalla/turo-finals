import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/Screens/Tutors/tutor_login.dart';
import 'package:turo/Screens/Tutors/tutor_homepage.dart';
import 'package:turo/providers/auth_provider.dart';

class TutorSignUpScreen extends StatefulWidget {
  const TutorSignUpScreen({super.key});

  @override
  _TutorSignUpScreenState createState() => _TutorSignUpScreenState();
}

class _TutorSignUpScreenState extends State<TutorSignUpScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.teal),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              /// Logo
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/turo_logo.png', height: 120),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// Title
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Teach ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    TextSpan(
                      text: 'with us!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Error Message (if any)
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                    ],
                  ),
                ),

              /// Form Fields
              _buildTextField('First Name', _firstNameController),
              _buildTextField('Last Name', _lastNameController),
              _buildTextField('Email Address', _emailController, isEmail: true),
              _buildPasswordField(),

              const SizedBox(height: 20),

              /// Signup Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign up', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 20),

              /// OR Divider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('- or sign up with -', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 20),

              /// Social Sign Up Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton('assets/google.png'),
                  const SizedBox(width: 20),
                  _buildSocialButton('assets/facebook.png'),
                  const SizedBox(width: 20),
                  _buildSocialButton('assets/twitter.png'),
                ],
              ),

              const SizedBox(height: 20),

              /// Login Prompt
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TutorLoginScreen()),
                    );
                  }, // Navigate to login screen
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Input Fields
  Widget _buildTextField(String hint, TextEditingController controller, {bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  /// Password Field with Visibility Toggle
  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: 'Password',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[200],
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  /// Social Media Buttons
  Widget _buildSocialButton(String assetPath) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
        ),
        child: Image.asset(assetPath, height: 30),
      ),
    );
  }

  void _handleSignUp() async {
    // Validate form
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please fill all fields";
      });
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = "Please enter a valid email address";
      });
      return;
    }

    // Validate password strength (at least 6 characters)
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = "Password must be at least 6 characters long";
      });
      return;
    }

    // Clear previous error and show loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        accountType: 'tutor',
      );

      if (success) {
        // Navigate to tutor homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TutorHomepage()),
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? "Registration failed";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}