import 'package:flutter/material.dart';
import 'package:turo/role_select.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:turo/providers/auth_provider.dart';
import 'package:turo/Screens/Students/student_homepage.dart';
import 'package:turo/Screens/Tutors/tutor_homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Check auth status
          if (auth.status == AuthStatus.unknown) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (auth.status == AuthStatus.authenticated) {
            // Redirect based on account type
            if (auth.user?.isStudent == true) {
              return const StudentHomepage();
            } else if (auth.user?.isTutor == true) {
              return const TutorHomepage();
            }
          }
          
          // Default return role selection screen
          return const RoleSelectionScreen();
        },
      ),
    );
  }
}