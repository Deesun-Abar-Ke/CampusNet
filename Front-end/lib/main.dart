import 'package:flutter/material.dart';
import 'screens/home/landing_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/auth/login_page.dart';
import 'services/current_user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load user data from storage
  await CurrentUserService.loadUserFromStorage();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Net App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/landing': (context) => const LandingPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
