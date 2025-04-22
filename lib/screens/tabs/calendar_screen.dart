import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Lịch')), // AppBar chung đã có ở HomePage
      body: Center(
        child: Text(
          'Màn hình Lịch (Chưa cài đặt)',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
