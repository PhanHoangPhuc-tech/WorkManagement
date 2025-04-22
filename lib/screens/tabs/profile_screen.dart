import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Của tôi')),
      body: Center(
        child: Text(
          'Màn hình Của tôi (Chưa cài đặt)',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
