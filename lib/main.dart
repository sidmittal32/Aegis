import 'package:aegis/login.dart';
import 'package:aegis/nearby_interface.dart';
import 'package:aegis/registration.dart';
import 'package:aegis/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDaVqCub_4kwclkhKfAmA4Tsp6wOcxz8AM",
      appId: "1:2703707847:android:51e4eac2f5cada19b078e2",
      messagingSenderId: "2703707847",
      projectId: "aegis-1aed3",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
      routes: {
        WelcomeScreen.id: (context) => const WelcomeScreen(),
        RegistrationScreen.id: (context) => const RegistrationScreen(),
        LoginScreen.id: (context) => const LoginScreen(),
        NearbyInterface.id: (context) => const NearbyInterface(),
      },
    );
  }
}