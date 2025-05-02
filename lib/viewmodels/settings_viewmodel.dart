import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanagement/viewmodels/auth_view_model.dart';
import 'package:workmanagement/views/auth_screen.dart';
import 'package:workmanagement/views/manage_categories_screen.dart';
import 'package:workmanagement/views/notification_settings_screen.dart';
import 'package:workmanagement/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsViewModel with ChangeNotifier {
  final AuthViewModel _authViewModel;
  final NotificationService _notificationService = NotificationService();

  static const String _themePrefKey = 'app_theme_mode';
  static const String _sendDueDatePrefKey = 'notif_send_due_date';
  static const String _showLockScreenPrefKey = 'notif_show_lock_screen';
  static const String _taskRemindersPrefKey = 'notif_task_reminders';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  bool _sendDueDateNotifications = true;
  bool get sendDueDateNotifications => _sendDueDateNotifications;
  bool _showLockScreenNotifications = false;
  bool get showLockScreenNotifications => _showLockScreenNotifications;
  bool _taskRemindersEnabled = true;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  bool _isLoadingPrefs = false;
  bool get isLoadingPrefs => _isLoadingPrefs;

  SettingsViewModel(this._authViewModel) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _isLoadingPrefs = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themePrefKey);
      if (savedThemeIndex != null &&
          savedThemeIndex >= 0 &&
          savedThemeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      } else {
        _themeMode = ThemeMode.system;
      }
      _sendDueDateNotifications = prefs.getBool(_sendDueDatePrefKey) ?? true;
      _showLockScreenNotifications =
          prefs.getBool(_showLockScreenPrefKey) ?? false;
      _taskRemindersEnabled = prefs.getBool(_taskRemindersPrefKey) ?? true;
    } catch (e) {
      debugPrint("Lỗi load preferences: $e");
      _themeMode = ThemeMode.system;
      _sendDueDateNotifications = true;
      _showLockScreenNotifications = false;
      _taskRemindersEnabled = true;
    } finally {
      _isLoadingPrefs = false;
      notifyListeners();
    }
  }

  Future<void> checkAndRequestNotificationPermissions(
    BuildContext context,
  ) async {
    bool granted = await _notificationService.requestPermissions();

    if (!granted) {
      debugPrint(
        "Quyền thông báo không được cấp (kiểm tra từ SettingsViewModel).",
      );
      PermissionStatus status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (dialogContext) => AlertDialog(
                  title: const Text("Yêu cầu quyền thông báo"),
                  content: const Text(
                    "Ứng dụng cần quyền thông báo để gửi nhắc nhở. Vui lòng cấp quyền trong cài đặt ứng dụng.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text("Để sau"),
                    ),
                    TextButton(
                      onPressed: () {
                        openAppSettings();
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text("Mở cài đặt"),
                    ),
                  ],
                ),
          );
        }
      }
    }

    PermissionStatus exactAlarmStatus =
        await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text("Yêu cầu quyền lên lịch chính xác"),
                content: const Text(
                  "Ứng dụng cần quyền 'Báo thức và lời nhắc' để đảm bảo nhắc nhở đúng giờ. Vui lòng bật quyền này trong cài đặt.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text("Để sau"),
                  ),
                  TextButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("Mở cài đặt"),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> updateThemeMode(ThemeMode? newMode) async {
    if (newMode == null || newMode == _themeMode) return;
    _themeMode = newMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePrefKey, newMode.index);
    } catch (e) {
      debugPrint("Lỗi lưu theme: $e");
    }
  }

  Future<void> updateSendDueDateNotifications(bool value) async {
    if (_sendDueDateNotifications == value) return;
    _sendDueDateNotifications = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sendDueDatePrefKey, value);
    } catch (e) {
      debugPrint("Lỗi lưu gửi thông báo trước hạn: $e");
    }
  }

  Future<void> updateShowLockScreenNotifications(bool value) async {
    if (_showLockScreenNotifications == value) return;
    _showLockScreenNotifications = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showLockScreenPrefKey, value);
    } catch (e) {
      debugPrint("Lỗi lưu lời nhắc màn hình khóa: $e");
    }
  }

  Future<void> updateTaskRemindersEnabled(bool value) async {
    if (_taskRemindersEnabled == value) return;
    _taskRemindersEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_taskRemindersPrefKey, value);
    } catch (e) {
      debugPrint("Lỗi lưu nhắc nhở công việc: $e");
    }
  }

  void navigateToManageCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()),
    );
  }

  void navigateToThemeSettings(BuildContext context) {}

  void navigateToNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void navigateToAboutHelp(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng Giới thiệu & Trợ giúp chưa cài đặt'),
      ),
    );
  }

  void navigateToDefaultAlertType(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng chưa cài đặt')));
  }

  void navigateToDefaultRingtone(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng chưa cài đặt')));
  }

  Future<void> signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      await _authViewModel.signOut();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Lỗi đăng xuất từ SettingsViewModel: $e");
      if (navigator.context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(content: Text('Đăng xuất thất bại: ${e.toString()}')),
        );
      }
    }
  }

  String? get userDisplayName => _authViewModel.user?.displayName;
  String? get userEmail => _authViewModel.user?.email;
  String? get userPhotoUrl => _authViewModel.user?.photoUrl;
}
