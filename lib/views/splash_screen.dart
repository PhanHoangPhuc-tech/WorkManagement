import 'package:flutter/material.dart';
import 'package:workmanagement/screens/tabs/home_page.dart'; // Màn hình chính

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {  
  @override
  void initState() {
    super.initState();
    // Chờ 3 giây rồi chuyển sang màn hình chính (HomePage)
    Future.delayed(const Duration(seconds: 3), () {
      // Kiểm tra nếu widget còn tồn tại (mounted) trước khi sử dụng BuildContext
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF005AE0), // Nền xanh
      body: Center(
        child: Text(
          'TaskFlow',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
