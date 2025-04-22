import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Cài đặt')),
      body: Center(
        child: Text(
          'Màn hình Cài đặt (Chưa cài đặt)',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
