import 'package:flutter/material.dart';
import 'package:workmanagement/screens/home/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Thêm super.key vào constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}
