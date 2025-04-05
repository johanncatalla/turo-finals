import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turo/Screens/Students/student_signup.dart';
import 'package:turo/Screens/Students/student_homepage.dart';
import 'package:turo/providers/auth_provider.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  _StudentLoginScreenState createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

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
                icon: const Icon(Icons.arrow_back, color: Colors.orange),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              /// Logo
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/turo_logo.png', height: 100),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome Back, Student!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

              /// Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              /// Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Log in',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              /// OR Divider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child:
                        Text('- or log in with -', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 10),

              /// Social Login Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: Image.asset('assets/google.png'), onPressed: () {}),
                  IconButton(icon: Image.asset('assets/facebook.png'), onPressed: () {}),
                  IconButton(icon: Image.asset('assets/twitter.png'), onPressed: () {}),
                ],
              ),

              const SizedBox(height: 20),

              /// Signup Prompt
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudentSignUpScreen()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign up",
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

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Email and password cannot be empty";
      });
      return;
    }

    // Clear previous error
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        'student',
      );

      if (success) {
        // Navigate to student homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentHomepage()),
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? "Authentication failed";
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
}