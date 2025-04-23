import 'package:flutter/material.dart';
import 'auth_screen.dart'; // Import màn hình đăng nhập

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToAuthScreen(); // Chuyển đến màn hình AuthScreen sau khi SplashScreen hiển thị
  }

  Future<void> _goToAuthScreen() async {
    await Future.delayed(const Duration(seconds: 3)); // Đợi 3 giây

    if (!mounted) return; // ✅ Đảm bảo context còn tồn tại

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(), // Chuyển tới màn hình AuthScreen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF005AE0),
      body: Center(
        child: Text(
          'TaskFlow',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
