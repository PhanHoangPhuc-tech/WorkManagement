import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase initialization
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Khởi tạo Firebase

  // Khởi tạo Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Gửi sự kiện Firebase Analytics khi ứng dụng mở (chỉ gọi ở đây một lần)
  await analytics.logEvent(
    name: 'app_open',
    parameters: <String, dynamic>{
      'user_id': '12345', // Tùy chỉnh thông tin người dùng
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      home: const SplashScreen(),
    );
  }
}
