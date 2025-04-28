import 'package:flutter/material.dart';
import 'package:workmanagement/views/manage_categories_screen.dart'; // Import để điều hướng
import 'package:workmanagement/viewmodels/auth_view_model.dart'; // Để truy cập AuthViewModel
import 'package:provider/provider.dart'; // Để sử dụng Provider
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Quản lý phân loại'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Giao diện & Chủ đề'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng chưa cài đặt')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Thông báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng chưa cài đặt')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Giới thiệu & Trợ giúp'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng chưa cài đặt')),
              );
            },
          ),
          const Divider(height: 1),
          // Thêm ListTile cho chức năng đăng xuất
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Xử lý đăng xuất
              final authViewModel = Provider.of<AuthViewModel>(
                context,
                listen: false,
              );
              await authViewModel.signOut();

              // Kiểm tra xem widget còn tồn tại không trước khi điều hướng
              if (!context.mounted) {
                return; // Kiểm tra widget có tồn tại hay không
              }

              // Sau khi đăng xuất, chuyển hướng về màn hình đăng nhập
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
