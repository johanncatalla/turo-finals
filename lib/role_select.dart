import 'package:flutter/material.dart';
import 'package:turo/Screens/Students/student_login.dart';
import 'package:turo/Screens/Tutors/tutor_login.dart';
import 'package:turo/Screens/Tutors/tutor_signup.dart';
import 'package:turo/Screens/Students/student_signup.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool isLearnerSelected = true;

  @override
  Widget build(BuildContext context) {
    Color primaryColor = isLearnerSelected ? Colors.orange : Colors.teal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Image.asset('assets/turo_logo.png', height: 100),
            SizedBox(height: 10),
            Text(
              'What are you looking for?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildOption(
              icon: Icons.menu_book,
              title: 'i-Learn',
              subtitle: 'I’m looking for a tutor to teach me',
              selected: isLearnerSelected,
              color: Colors.orange,
              onTap: () => setState(() => isLearnerSelected = true),
            ),
            SizedBox(height: 10),
            _buildOption(
              icon: Icons.work,
              title: 'i-Teach',
              subtitle: 'I’m looking for a client to teach',
              selected: !isLearnerSelected,
              color: Colors.teal,
              onTap: () => setState(() => isLearnerSelected = false),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isLearnerSelected
                        ? StudentSignUpScreen()
                        : TutorSignUpScreen(),
                  ),
                );
              },
              child: Text(
                'Create Account',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isLearnerSelected
                        ? StudentLoginScreen()
                        : TutorLoginScreen(),
                  ),
                );
              },
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.black54),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? color : Colors.grey),
          borderRadius: BorderRadius.circular(10),
          color: selected ? color.withOpacity(0.1) : Colors.grey[200],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: selected ? Colors.black : Colors.grey),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Spacer(),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
