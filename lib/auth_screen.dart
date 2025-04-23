import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please log in to continue',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Đặt các widget nhập liệu như TextField cho email và password tại đây
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true, // Ẩn mật khẩu khi gõ
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Xử lý đăng nhập tại đây
                // Ví dụ: chuyển đến màn hình Home nếu đăng nhập thành công
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
