import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import 'package:logger/logger.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});  // Thay key: key bằng super.key

  @override
  Widget build(BuildContext context) {
    var logger = Logger();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            // Tiêu đề
            Text(
              'TaskFlow',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            // Phần khoảng trống giữa tiêu đề và nút
            Spacer(),

            // Nút đăng nhập bằng số điện thoại
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Thêm chức năng sau
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, color: Colors.black),
                    SizedBox(width: 10),
                    Text(
                      'Tiếp tục với số điện thoại',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Nút đăng nhập bằng Google
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Kiểm tra xem widget có còn mounted không
                  if (!context.mounted) return;

                  await Provider.of<AuthViewModel>(context, listen: false)
                      .signInWithGoogle();

                  // Sau khi hoàn thành đăng nhập, kiểm tra xem người dùng đã đăng nhập chưa
                  if (context.mounted) { // Kiểm tra lại trước khi sử dụng BuildContext
                    if (Provider.of<AuthViewModel>(context, listen: false).isAuthenticated) {
                      // Đăng nhập thành công
                      logger.i("Đăng nhập thành công");
                    } else {
                      // Đăng nhập thất bại
                      logger.e("Đăng nhập thất bại");
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Đăng nhập bằng Google',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Nút đăng nhập bằng Facebook
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Thêm chức năng đăng nhập Facebook sau
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Đăng nhập bằng Facebook',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Ghi chú nhỏ dưới màn hình
            Text(
              'Chúng tôi không chia sẻ thông tin của bạn mà chưa cho phép',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
