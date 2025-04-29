import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showThemeDialog(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    final currentMode = viewModel.themeMode;

    final ThemeMode? selectedMode = await showDialog<ThemeMode>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            ThemeMode groupValue = currentMode;

            String getThemeModeName(ThemeMode mode) {
              switch (mode) {
                case ThemeMode.light:
                  return 'Sáng';
                case ThemeMode.dark:
                  return 'Tối';
                case ThemeMode.system:
                  return 'Theo hệ thống';
              }
            }

            return AlertDialog(
              title: const Text('Chọn giao diện'),
              contentPadding: const EdgeInsets.only(top: 12.0, bottom: 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    ThemeMode.values.map((mode) {
                      return RadioListTile<ThemeMode>(
                        title: Text(getThemeModeName(mode)),
                        value: mode,
                        groupValue: groupValue,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            stfSetState(() {
                              groupValue = value;
                            });
                            Navigator.pop(dialogContext, value);
                          }
                        },
                        activeColor: Theme.of(context).primaryColor,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedMode != null) {
      viewModel.updateThemeMode(selectedMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);

    final photoUrl = settingsViewModel.userPhotoUrl;
    final bool hasPhotoUrl = photoUrl != null && photoUrl.isNotEmpty;

    String getCurrentThemeName() {
      switch (settingsViewModel.themeMode) {
        case ThemeMode.light:
          return 'Sáng';
        case ThemeMode.dark:
          return 'Tối';
        case ThemeMode.system:
          return 'Theo hệ thống';
      }
    }

    return Scaffold(
      body: ListView(
        children: [
          if (settingsViewModel.userEmail != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        hasPhotoUrl ? NetworkImage(photoUrl) : null,
                    child:
                        !hasPhotoUrl
                            ? Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.grey.shade600,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settingsViewModel.userDisplayName ?? 'Người dùng',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settingsViewModel.userEmail!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (settingsViewModel.userEmail != null) const Divider(),

          _buildSettingsItem(
            context,
            icon: Icons.category_outlined,
            title: 'Quản lý phân loại',
            onTap: () => settingsViewModel.navigateToManageCategories(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.color_lens_outlined,
              color: Theme.of(context).listTileTheme.iconColor,
            ),
            title: const Text('Giao diện & Chủ đề'),
            subtitle: Text(
              getCurrentThemeName(),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () {
              _showThemeDialog(context, settingsViewModel);
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            dense: true,
          ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            onTap:
                () => settingsViewModel.navigateToNotificationSettings(context),
          ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.info_outline,
            title: 'Giới thiệu & Trợ giúp',
            onTap: () => settingsViewModel.navigateToAboutHelp(context),
          ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.logout,
            title: 'Đăng xuất',
            iconColor: theme.colorScheme.error,
            titleColor: theme.colorScheme.error,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (dialogContext) => AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                // ignore: use_build_context_synchronously
                await settingsViewModel.signOut(context);
              }
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    final effectiveIconColor =
        iconColor ?? Theme.of(context).listTileTheme.iconColor;

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      dense: true,
    );
  }
}
