import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Để dùng authStateChanges
import 'package:workmanagement/views/home_page.dart'; // Màn hình chính
import 'package:workmanagement/views/auth_screen.dart'; // Màn hình đăng nhập

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Giữ màn hình Splash trong 2 giây trước khi kiểm tra trạng thái đăng nhập
    Future.delayed(const Duration(seconds: 2), () {
      // Lắng nghe trạng thái đăng nhập của người dùng sau khi 2 giây
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (!mounted) return; // Kiểm tra xem widget có còn tồn tại không
        if (user != null) {
          // Nếu người dùng đã đăng nhập, chuyển đến màn hình chính (HomePage)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(userId: user.uid)),
          );
        } else {
          // Nếu người dùng chưa đăng nhập, chuyển đến màn hình đăng nhập (AuthScreen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF005AE0),
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
