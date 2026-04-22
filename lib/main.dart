import 'package:flutter/material.dart';
import 'package:kareba/Screens/splash.dart';
import 'package:kareba/Screens/login.dart'; 
import 'package:kareba/Screens/dashboard_guru.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hbnitxayztzoiecirtgf.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhibml0eGF5enR6b2llY2lydGdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MDU0ODgsImV4cCI6MjA5MjI4MTQ4OH0.h0546lwWWwiggqd0yqwM44quvL4Th_7oSs187kzMjdA',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KAREBA - Jurnal Guru',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        'login': (context) => const LoginPage(), 
        'dashboard_guru': (context) => const DashboardGuru(),
      },
    );
  }
}