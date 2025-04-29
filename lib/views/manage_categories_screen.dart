import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});
  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final TextEditingController _categoryDialogController =
      TextEditingController();
  String? _dialogErrorText;

  @override
  void dispose() {
    _categoryDialogController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryDialog({
    int? editIndex,
    String? currentName,
  }) async {
    final categoryViewModel = context.read<CategoryViewModel>();
    _categoryDialogController.text = currentName ?? '';
    _dialogErrorText = null;
    final bool isEditing = editIndex != null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isLoading = context.watch<CategoryViewModel>().isLoading;
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: Text(isEditing ? 'Sửa Phân Loại' : 'Thêm Phân Loại Mới'),
              content: TextField(
                controller: _categoryDialogController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập tên phân loại...',
                  errorText: _dialogErrorText,
                ),
                onChanged: (_) {
                  if (_dialogErrorText != null) {
                    stfSetState(() => _dialogErrorText = null);
                  }
                },
                onSubmitted:
                    isLoading
                        ? null
                        : (_) async {
                          await _handleSaveCategory(
                            dialogContext,
                            categoryViewModel,
                            editIndex,
                            stfSetState,
                          );
                        },
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            await _handleSaveCategory(
                              dialogContext,
                              categoryViewModel,
                              editIndex,
                              stfSetState,
                            );
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(isEditing ? 'Lưu' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSaveCategory(
    BuildContext dialogContext,
    CategoryViewModel viewModel,
    int? editIndex,
    Function(VoidCallback) stfSetState,
  ) async {
    final String categoryName = _categoryDialogController.text;
    final navigator = Navigator.of(dialogContext);
    try {
      if (editIndex != null) {
        await viewModel.updateCategory(editIndex, categoryName);
      } else {
        await viewModel.addCategory(categoryName);
      }

      if (!mounted) return;
      navigator.pop();
      _categoryDialogController.clear();
    } on Exception catch (e) {
      stfSetState(
        () => _dialogErrorText = e.toString().replaceFirst('Exception: ', ''),
      );
    } catch (e) {
      stfSetState(() => _dialogErrorText = 'Lỗi: $e');
    }
  }

  void _confirmDeleteCategory(int index, String categoryName) {
    final categoryViewModel = context.read<CategoryViewModel>();
    final taskViewModel = context.read<TaskViewModel>();
    bool isLoading = categoryViewModel.isLoading;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc muốn xóa phân loại "$categoryName"?\nCông việc liên quan sẽ bị mất phân loại.',
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          final dialogNavigator = Navigator.of(dialogContext);
                          dialogNavigator.pop();

                          try {
                            final deletedName = await categoryViewModel
                                .deleteCategory(index);

                            if (!mounted) return;
                            if (deletedName != null) {
                              await taskViewModel.handleCategoryDeleted(
                                deletedName,
                              );
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Đã xóa "$deletedName"'),
                                ),
                              );
                            }
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Lỗi khi xóa: ${e.toString().replaceFirst('Exception: ', '')}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                        : const Text('Xóa'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryViewModel = context.watch<CategoryViewModel>();
    final categories = categoryViewModel.categories;
    final isLoading = categoryViewModel.isLoading;
    final error = categoryViewModel.error;

    if (error != null && categories.isEmpty && !isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed:
                      isLoading
                          ? null
                          : () => categoryViewModel.loadCategories(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Phân Loại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                isLoading && categories.isEmpty
                    ? null
                    : () => _showCategoryDialog(),
          ),
        ],
      ),
      body:
          isLoading && categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : categories.isEmpty
              ? const Center(
                child: Text(
                  'Chưa có phân loại nào...',
                  textAlign: TextAlign.center,
                ),
              )
              : ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = categories[index];
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
                          onPressed:
                              isLoading
                                  ? null
                                  : () => _showCategoryDialog(
                                    editIndex: index,
                                    currentName: category,
                                  ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade300,
                          ),
                          onPressed:
                              isLoading
                                  ? null
                                  : () =>
                                      _confirmDeleteCategory(index, category),
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
