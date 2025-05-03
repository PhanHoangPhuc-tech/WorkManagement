import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/settings_viewmodel.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt nhắc nhở & thông báo')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Loại lời nhắc mặc định'),
            subtitle: const Text('Thông báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => viewModel.navigateToDefaultAlertType(
                  context,
                ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Nhạc chuông mặc định'),
            subtitle: const Text('TaskFlow mặc định'),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => viewModel.navigateToDefaultRingtone(
                  context,
                ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 10),

          SwitchListTile(
            title: const Text('Gửi thông báo trước hạn'),
            subtitle: const Text(
              'Nhận cảnh báo trước khi hạn chót đến, tránh bỏ lỡ công việc.',
            ),
            value: viewModel.sendDueDateNotifications,
            onChanged: (bool value) {
              viewModel.updateSendDueDateNotifications(value);
            },
            activeColor: theme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Lời nhắc màn hình khoá'),
            subtitle: const Text(
              'Hiển thị lời nhắc công việc trên màn hình mở khoá điện thoại.',
            ),
            value: viewModel.showLockScreenNotifications,
            onChanged: (bool value) {
              viewModel.updateShowLockScreenNotifications(value);
            },
            activeColor: theme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Nhắc nhở công việc'),
            subtitle: const Text(
              'Bật lời nhắc để nhanh chóng kiểm tra công việc hàng ngày/hàng tuần.',
            ),
            value: viewModel.taskRemindersEnabled,
            onChanged: (bool value) {
              viewModel.updateTaskRemindersEnabled(value);
            },
            activeColor: theme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}
