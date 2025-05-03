import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/settings_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/views/create_task.dart';
import 'package:workmanagement/views/edit_task.dart';
import 'package:workmanagement/views/manage_categories_screen.dart';
import 'package:workmanagement/views/calendar_screen.dart';
import 'package:workmanagement/views/profile_screen.dart';
import 'package:workmanagement/views/settings_screen.dart';
import 'package:workmanagement/views/widgets/task_search_delegate.dart';
import 'package:workmanagement/views/task_list/task_list_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TaskSearchDelegate _searchDelegate = TaskSearchDelegate();

  @override
  void initState() {
    super.initState();
    Future.delayed(
        Duration.zero,
        // ignore: use_build_context_synchronously
        () => context
            .read<SettingsViewModel>()
            // ignore: use_build_context_synchronously
            .checkAndRequestNotificationPermissions(context));
  }

  void _confirmDeleteTask(BuildContext context, Task task) {
    final taskViewModel = context.read<TaskViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext).dialogTheme;
        final textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          backgroundColor: dialogTheme.backgroundColor,
          title: Text('Xác nhận xóa', style: dialogTheme.titleTextStyle ?? textTheme.titleLarge),
          content: Text('Xóa công việc "${task.title}"?', style: dialogTheme.contentTextStyle ?? textTheme.bodyMedium),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Hủy')),
            Consumer<TaskViewModel>(
              builder: (context, vm, child) {
                return TextButton(
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: vm.isLoading ? null : () async {
                    Navigator.of(dialogContext).pop();
                    try {
                      await taskViewModel.deleteTask(task.id);
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Đã xóa "${task.title}"')));
                    } catch (e) {
                      debugPrint("Lỗi xóa từ dialog: $e");
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi xóa: ${vm.error ?? e.toString()}'),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    }
                  },
                  child: vm.isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.error))
                      : const Text('Xóa'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditTask(BuildContext context, Task task) {
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)));
  }

  void _navigateToAddTask(BuildContext context) {
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen()));
  }

  void _navigateToManageCategories(BuildContext context) {
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()));
  }

  void _onFilterIconPressed() {
    final taskViewModel = context.read<TaskViewModel>();
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bottomSheetTheme.modalBackgroundColor ?? (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Tùy chọn lọc & Quản lý', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Consumer<TaskViewModel>(
              builder: (context, vm, child) {
                return SwitchListTile(
                  title: const Text('Hiển thị công việc đã hoàn thành'),
                  value: vm.showCompleted,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    Navigator.pop(context);
                    taskViewModel.toggleShowCompleted(value);
                  },
                  activeColor: theme.primaryColor,
                );
              },
            ),
            Divider(color: theme.dividerColor.withAlpha(128)),
            ListTile(
              leading: Icon(Icons.category_outlined, color: theme.listTileTheme.iconColor),
              title: const Text('Quản lý phân loại'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                final navContext = context;
                Navigator.pop(context);
                _navigateToManageCategories(navContext);
              },
              trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TaskListPage(
        confirmDeleteTaskCallback: _confirmDeleteTask,
        navigateToEditTaskCallback: _navigateToEditTask,
      ),
      const CalendarScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "Lọc & Tùy chọn",
            onPressed: _onFilterIconPressed,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Tìm kiếm",
            onPressed: () async {
              final currentContext = context;
              final Task? selectedOriginalTask = await showSearch<Task?>(
                context: currentContext,
                delegate: _searchDelegate,
              );
              if (!mounted || selectedOriginalTask == null) return;
              // ignore: use_build_context_synchronously
              _navigateToEditTask(currentContext, selectedOriginalTask);
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _navigateToAddTask(context),
              tooltip: 'Tạo công việc mới',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) { setState(() => _currentIndex = idx); },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task_alt_outlined), activeIcon: Icon(Icons.task_alt), label: 'Nhiệm vụ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Lịch'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}