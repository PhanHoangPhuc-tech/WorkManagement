import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/ViewModel/category_viewmodel.dart';
import 'package:workmanagement/ViewModel/task_viewmodel.dart';
import 'package:workmanagement/Mo/task_model.dart';
import 'package:workmanagement/screens/tabs/create_task.dart';
import 'package:workmanagement/screens/tabs/edit_task.dart';
import 'package:workmanagement/screens/tabs/manage_categories_screen.dart';
import 'package:workmanagement/screens/tabs/calendar_screen.dart';
import 'package:workmanagement/screens/tabs/profile_screen.dart';
import 'package:workmanagement/screens/tabs/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _searchDelegate = _TaskSearchDelegate();

  void _confirmDeleteTask(BuildContext context, Task task) {
    final taskViewModel = context.read<TaskViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Xóa công việc "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed:
                  taskViewModel.isLoading
                      ? null
                      : () async {
                        navigator.pop();
                        try {
                          await taskViewModel.deleteTask(task.id);
                          if (!mounted) {
                            return;
                          }
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Đã xóa "${task.title}"')),
                          );
                        } catch (e) {
                          if (!mounted) {
                            return;
                          }
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Lỗi xóa: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
              child:
                  taskViewModel.isLoading
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
        );
      },
    );
  }

  void _navigateToEditTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
    );
  }

  void _navigateToAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );
  }

  void _navigateToManageCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
    );
  }

  void _onFilterIconPressed() {
    final taskViewModel = context.read<TaskViewModel>();
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tùy chọn lọc & Quản lý',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Hiển thị công việc đã hoàn thành'),
                  value: taskViewModel.showCompleted,
                  onChanged: (v) {
                    taskViewModel.toggleShowCompleted(v);
                    Navigator.pop(context);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Quản lý phân loại'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToManageCategories();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.watch<TaskViewModel>();
    final categoryViewModel = context.watch<CategoryViewModel>();
    final categories = categoryViewModel.categories;
    final currentFilter = taskViewModel.selectedCategoryFilter ?? 'Tất cả';
    final filterOptions = ['Tất cả', ...categories];

    final List<Widget> screens = [
      _buildTaskListPage(
        context,
        taskViewModel,
        categoryViewModel,
        filterOptions,
        currentFilter,
      ),
      const CalendarScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        backgroundColor: const Color(0xFF005AE0),
        titleTextStyle: const TextStyle(  // Đặt màu trắng cho title
          color: Colors.white,  // Chỉnh màu chữ thành trắng
          fontSize: 20,         // Kích thước chữ (có thể thay đổi tùy ý)
          fontWeight: FontWeight.bold,  // Định dạng chữ đậm (tuỳ chọn)
        ),
        iconTheme: const IconThemeData(  
          color: Colors.white, 
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Tìm kiếm",
            onPressed: () async {
              _searchDelegate.taskViewModel = taskViewModel;
              final Task? selectedTask = await showSearch<Task?>(
                context: context,
                delegate: _searchDelegate,
              );
              // --- Kiểm tra mounted SAU await và TRƯỚC khi dùng context ---
              if (!mounted) {
                return;
              }
              if (selectedTask != null) {
                _navigateToEditTask(
                  // ignore: use_build_context_synchronously
                  context,
                  selectedTask,
                ); // Context an toàn để dùng ở đây
              }
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed: () => _navigateToAddTask(context),
                tooltip: 'Tạo công việc mới',
                child: const Icon(Icons.add),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (idx) {
          setState(() => _currentIndex = idx);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_outlined),
            activeIcon: Icon(Icons.task_alt),
            label: 'Nhiệm vụ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListPage(
    BuildContext context,
    TaskViewModel taskVM,
    CategoryViewModel catVM,
    List<String> filters,
    String currentFilterValue,
  ) {
    Widget bodyContent;
    final groupedTasksMap = taskVM.groupedTasks;
    final visibleSectionKeys = groupedTasksMap.keys.toList();
    final isLoading = taskVM.isLoading || catVM.isLoading;
    final error = taskVM.error ?? catVM.error;
    final categories = catVM.categories;

    if (error != null && groupedTasksMap.isEmpty && !isLoading) {
      bodyContent = Center(child: Text("Lỗi: $error"));
    } else if (isLoading && groupedTasksMap.isEmpty && categories.isEmpty) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (groupedTasksMap.isEmpty) {
      bodyContent = Center(
        child: Text(
          taskVM.selectedCategoryFilter != null
              ? 'Không có CV trong "${taskVM.selectedCategoryFilter}".'
              : 'Không có công việc nào.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        onRefresh: () async {
          await Future.wait([catVM.loadCategories(), taskVM.loadTasks()]);
        },
        child: ListView.builder(
          key: const PageStorageKey('taskList'),
          padding: const EdgeInsets.only(bottom: 80.0),
          itemCount: visibleSectionKeys.length,
          itemBuilder: (context, index) {
            final sectionTitle = visibleSectionKeys[index];
            final tasksInSection = groupedTasksMap[sectionTitle]!;
            return ExpansionTile(
              key: PageStorageKey(sectionTitle),
              title: Text(
                '$sectionTitle (${tasksInSection.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              initiallyExpanded:
                  sectionTitle == 'Hôm nay' || sectionTitle == 'Quá hạn',
              maintainState: true,
              shape: const Border(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
              childrenPadding: const EdgeInsets.only(bottom: 8.0),
              children:
                  tasksInSection
                      .map((task) => _buildTaskItem(context, task))
                      .toList(),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child:
                    catVM.isLoading && categories.isEmpty
                        ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final filterName = filters[idx];
                            final filterValue =
                                filterName == 'Tất cả' ? null : filterName;
                            return ChoiceChip(
                              label: Text(filterName),
                              selected:
                                  taskVM.selectedCategoryFilter == filterValue,
                              onSelected: (_) {
                                taskVM.setCategoryFilter(filterValue);
                              },
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                            );
                          },
                        ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: "Lọc & Tùy chọn",
                onPressed: _onFilterIconPressed,
                color: Colors.grey[700],
                splashRadius: 20,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(child: bodyContent),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final taskViewModel = context.read<TaskViewModel>();
    final localizations = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final bool isOverdue =
        !task.isDone &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now().copyWith(hour: 0, minute: 0));
    String trailingInfo = '';
    List<String> subtitleParts = [];
    if (task.dueDate != null) {
      subtitleParts.add(DateFormat('dd/MM/yyyy').format(task.dueDate!));
      if (task.dueTime != null) {
        trailingInfo = localizations.formatTimeOfDay(
          task.dueTime!,
          alwaysUse24HourFormat: true,
        );
      }
    }
    if (task.description.isNotEmpty) {
      subtitleParts.add(task.description);
    }
    if (task.category != null && task.category!.isNotEmpty) {
      subtitleParts.add('[${task.category}]');
    }
    final subtitleText = subtitleParts.join('\n');

    return ListTile(
      leading: Checkbox(
        value: task.isDone,
        onChanged: (v) {
          if (v != null) {
            taskViewModel.toggleTaskDone(task.id);
          }
        },
        activeColor: theme.primaryColor,
        visualDensity: VisualDensity.compact,
      ),
      title: Row(
        children: [
          if (task.sticker != null)
            Icon(task.sticker, size: 18, color: theme.primaryColor),
          if (task.sticker != null) const SizedBox(width: 6),
          Expanded(
            child: Text(
              task.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w500,
                color: task.isDone ? Colors.grey[600] : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitleText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: task.isDone ? TextDecoration.lineThrough : null,
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.flag, color: task.priority.priorityColor, size: 18),
              if (trailingInfo.isNotEmpty) const SizedBox(height: 4),
              if (trailingInfo.isNotEmpty)
                Text(
                  trailingInfo,
                  style: TextStyle(
                    color: isOverdue ? Colors.red.shade700 : Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'Tùy chọn khác',
            iconSize: 20,
            padding: EdgeInsets.zero,
            splashRadius: 18,
            onSelected: (String result) {
              if (result == 'edit') {
                _navigateToEditTask(context, task);
              } else if (result == 'delete') {
                _confirmDeleteTask(context, task);
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined, size: 20),
                      title: Text('Sửa'),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      title: Text('Xóa', style: TextStyle(color: Colors.red)),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
          ),
        ],
      ),
      tileColor: task.isDone ? Colors.grey.shade100 : Colors.white,
      onTap: () => _navigateToEditTask(context, task),
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
    );
  }
}

class _TaskSearchDelegate extends SearchDelegate<Task?> {
  TaskViewModel? taskViewModel;
  @override
  String? get searchFieldLabel => 'Tìm kiếm công việc...';
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = taskViewModel?.searchTasks(query) ?? [];
    if (results.isEmpty) {
      return Center(child: Text('Không tìm thấy kết quả nào cho "$query"'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        return ListTile(
          leading: Checkbox(
            value: task.isDone,
            onChanged: null,
            visualDensity: VisualDensity.compact,
          ),
          title: Row(
            children: [
              if (task.sticker != null)
                Icon(
                  task.sticker,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              if (task.sticker != null) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    color: task.isDone ? Colors.grey[600] : null,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${task.description.isNotEmpty ? task.description : ""}${task.description.isNotEmpty && task.category != null ? "\n" : ""}${task.category != null ? "[${task.category}]" : ""}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Icon(
            Icons.flag,
            color: task.priority.priorityColor,
            size: 18,
          ),
          onTap: () => close(context, task),
          tileColor: task.isDone ? Colors.grey.shade100 : null,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        taskViewModel?.searchTasks(query).take(8).toList() ?? [];
    if (query.isEmpty) {
      return const Center(child: Text('Nhập tiêu đề, mô tả...'));
    }
    if (suggestions.isEmpty) {
      return const Center(child: Text('Không có gợi ý'));
    }
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final task = suggestions[index];
        return ListTile(
          leading:
              task.sticker != null
                  ? Icon(task.sticker)
                  : const Icon(Icons.label_outline),
          title: Text(task.title),
          subtitle: Text(task.category ?? ''),
          onTap: () {
            query = task.title;
            showResults(context);
          },
        );
      },
    );
  }
}
