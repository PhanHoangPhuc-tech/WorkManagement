import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanagement/viewmodels/auth_view_model.dart';
import 'package:workmanagement/views/auth_screen.dart';
import 'package:workmanagement/views/manage_categories_screen.dart';

class SettingsViewModel with ChangeNotifier {
  final AuthViewModel _authViewModel;
  static const String _themePrefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _isLoadingTheme = false;
  bool get isLoadingTheme => _isLoadingTheme;

  SettingsViewModel(this._authViewModel) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    _isLoadingTheme = true;
    notifyListeners();

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
    } catch (e) {
      debugPrint("Lỗi load theme: $e");
      _themeMode = ThemeMode.system;
    } finally {
      _isLoadingTheme = false;
      notifyListeners();
    }
  }

  Future<void> updateThemeMode(ThemeMode? newMode) async {
    if (newMode == null || newMode == _themeMode) {
      return;
    }
    _themeMode = newMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePrefKey, newMode.index);
    } catch (e) {
      debugPrint("Lỗi lưu theme: $e");
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng Thông báo chưa cài đặt')),
    );
  }

  void navigateToAboutHelp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng Giới thiệu & Trợ giúp chưa cài đặt'),
      ),
    );
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng xuất thất bại: ${e.toString()}')),
        );
      }
    }
  }

  String? get userDisplayName => _authViewModel.user?.displayName;
  String? get userEmail => _authViewModel.user?.email;
  String? get userPhotoUrl => _authViewModel.user?.photoUrl;
}
