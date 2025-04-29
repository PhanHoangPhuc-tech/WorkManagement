import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

abstract class ICategoryRepository {
  Future<List<String>> loadCategories();
  Future<void> saveCategories(List<String> categories);
}

class CategoryRepository implements ICategoryRepository {
  final String _prefsKey = 'user_categories_v2';
  final List<String> _defaultCategories = const [
    'Công việc',
    'Cá nhân',
    'Học tập',
    'Mua sắm',
  ];

  @override
  Future<List<String>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList(_prefsKey);
      if (savedCategories != null && savedCategories.isNotEmpty) {
        savedCategories.sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );
        return savedCategories;
      } else {
        List<String> sortedDefaults = List.from(_defaultCategories)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return sortedDefaults;
      }
    } catch (e) {
      List<String> sortedDefaults = List.from(_defaultCategories)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return sortedDefaults;
    }
  }

  @override
  Future<void> saveCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> sortedCategories = List.from(categories)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      await prefs.setStringList(_prefsKey, sortedCategories);
    } catch (e) {
      throw Exception('Không thể lưu danh sách phân loại.');
    }
  }
}
