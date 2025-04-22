import 'package:flutter/material.dart';

typedef CategoryUpdateCallback =
    void Function(List<String> updatedCategories, {String? deletedCategory});

class ManageCategoriesScreen extends StatefulWidget {
  final List<String> initialCategories;
  final CategoryUpdateCallback onUpdate;

  const ManageCategoriesScreen({
    super.key,
    required this.initialCategories,
    required this.onUpdate,
  });

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late List<String> _categories;
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = List<String>.from(widget.initialCategories);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryDialog({int? editIndex}) async {
    _categoryController.text = editIndex != null ? _categories[editIndex] : '';
    final bool isEditing = editIndex != null;

    await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isEditing ? 'Sửa Phân Loại' : 'Thêm Phân Loại Mới'),
            content: TextField(
              controller: _categoryController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Nhập tên phân loại...',
              ),
              onSubmitted: (_) => _saveCategory(editIndex: editIndex),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => _saveCategory(editIndex: editIndex),
                child: Text(isEditing ? 'Lưu' : 'Thêm'),
              ),
            ],
          ),
    );
  }

  void _saveCategory({int? editIndex}) {
    final String categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên phân loại không được để trống')),
      );
      return;
    }

    final lowerCaseName = categoryName.toLowerCase();
    final isDuplicate = _categories.any(
      (cat) =>
          cat.toLowerCase() == lowerCaseName &&
          (editIndex == null ||
              _categories[editIndex].toLowerCase() != lowerCaseName),
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tên phân loại "$categoryName" đã tồn tại')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        if (editIndex != null) {
          _categories[editIndex] = categoryName;
        } else {
          _categories.add(categoryName);
          _categories.sort(
            (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
          );
        }
      });
    }
    widget.onUpdate(_categories);
    Navigator.pop(context);
    _categoryController.clear();
  }

  void _deleteCategory(int index) {
    final String deletedCategory = _categories[index];
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa Phân Loại?'),
            content: Text(
              'Bạn có chắc muốn xóa phân loại "$deletedCategory"?\nCông việc liên quan sẽ bị mất phân loại.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _categories.removeAt(index);
                    });
                  }
                  widget.onUpdate(
                    _categories,
                    deletedCategory: deletedCategory,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Phân Loại'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm phân loại',
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body:
          _categories.isEmpty
              ? const Center(
                child: Text(
                  'Chưa có phân loại nào.\nNhấn + để thêm.',
                  textAlign: TextAlign.center,
                ),
              )
              : ListView.separated(
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ListTile(
                    title: Text(category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: Colors.blueGrey.shade400,
                          ),
                          tooltip: 'Sửa',
                          splashRadius: 20,
                          onPressed:
                              () => _showCategoryDialog(editIndex: index),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade300,
                          ),
                          tooltip: 'Xóa',
                          splashRadius: 20,
                          onPressed: () => _deleteCategory(index),
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.only(
                      left: 16.0,
                      right: 4.0,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
    );
  }
}
