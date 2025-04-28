import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanagement/views/splash_screen.dart'; 
import 'firebase_options.dart';  
import 'package:provider/provider.dart'; 
import 'package:workmanagement/viewmodels/task_viewmodel.dart'; 
import 'package:workmanagement/viewmodels/category_viewmodel.dart'; 
import 'package:workmanagement/viewmodels/auth_user_view_model.dart';  
import 'package:workmanagement/viewmodels/profile_view_model.dart';  

void main() async {
  // Đảm bảo Flutter bindings được khởi tạo trước khi Firebase được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với các cấu hình đặc thù cho từng nền tảng
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Đăng ký tất cả các provider cho ViewModels
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()), // Đảm bảo ProfileViewModel có sẵn ở đây
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      theme: ThemeData(
        primaryColor: const Color(0xFF005AE0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005AE0)),
      ),
      home: const SplashScreen(),  // Màn hình splash khi khởi động
      debugShowCheckedModeBanner: false,  // Tắt banner debug
    );
  }
}
