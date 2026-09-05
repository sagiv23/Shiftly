import 'package:flutter/material.dart';
import '../widgets/app_icon.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E293B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EssentialWorkIcon(size: 200),
            SizedBox(height: 40),
            Text(
              'Planet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'Arial',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'מעקב שעות עבודה חכם',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 18,
                fontFamily: 'Arial',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
