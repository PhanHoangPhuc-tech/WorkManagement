import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanagement/repositories/category_repository.dart';

class CategoryViewModel with ChangeNotifier {
  final ICategoryRepository _repository = CategoryRepository();
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryViewModel() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _repository.loadCategories();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('user_categories_v2');
      if (saved == null && _categories.isNotEmpty) {
        try {
          await _repository.saveCategories(_categories);
        } catch (e) {
          /* ignore */
        }
      }
    } catch (e) {
      _error = "Lỗi tải phân loại: $e";
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String categoryName) async {
    final trimmedName = categoryName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Tên không được để trống.');
    }
    if (_categories.any((c) => c.toLowerCase() == trimmedName.toLowerCase())) {
      throw Exception('Tên phân loại đã tồn tại.');
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      List<String> updatedList = List.from(_categories)..add(trimmedName);
      await _repository.saveCategories(updatedList);
      await loadCategories();
    } catch (e) {
      _error = "Lỗi thêm phân loại: $e";
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(int index, String newName) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) {
      throw Exception('Tên không được để trống.');
    }
    if (index < 0 || index >= _categories.length) {
      throw Exception('Index không hợp lệ.');
    }
    final lowerNewName = trimmedNewName.toLowerCase();
    final originalName = _categories[index];
    if (originalName.toLowerCase() == lowerNewName) {
      return;
    }
    if (_categories.asMap().entries.any(
      (entry) =>
          entry.key != index && entry.value.toLowerCase() == lowerNewName,
    )) {
      throw Exception('Tên phân loại đã tồn tại.');
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      List<String> updatedList = List.from(_categories);
      updatedList[index] = trimmedNewName;
      await _repository.saveCategories(updatedList);
      await loadCategories();
    } catch (e) {
      _error = "Lỗi cập nhật phân loại: $e";
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> deleteCategory(int index) async {
    if (index < 0 || index >= _categories.length) {
      throw Exception('Index không hợp lệ để xóa.');
    }
    final deletedCategory = _categories[index];
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      List<String> updatedList = List.from(_categories)..removeAt(index);
      await _repository.saveCategories(updatedList);
      _categories = updatedList;
      _isLoading = false;
      notifyListeners();
      return deletedCategory;
    } catch (e) {
      _error = "Lỗi xóa phân loại: $e";
      await loadCategories();
      rethrow;
    }
  }
}
