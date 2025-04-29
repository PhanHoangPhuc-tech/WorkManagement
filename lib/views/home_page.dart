import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_view_data.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/views/create_task.dart';
import 'package:workmanagement/views/edit_task.dart';
import 'package:workmanagement/views/manage_categories_screen.dart';
import 'package:workmanagement/views/calendar_screen.dart';
import 'package:workmanagement/views/profile_screen.dart';
import 'package:workmanagement/views/settings_screen.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _TaskSearchDelegate _searchDelegate = _TaskSearchDelegate();

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
          title: Text(
            'Xác nhận xóa',
            style: dialogTheme.titleTextStyle ?? textTheme.titleLarge,
          ),
          content: Text(
            'Xóa công việc "${task.title}"?',
            style: dialogTheme.contentTextStyle ?? textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            Consumer<TaskViewModel>(
              builder: (context, vm, child) {
                return TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed:
                      vm.isLoading
                          ? null
                          : () async {
                            Navigator.of(dialogContext).pop();
                            try {
                              await taskViewModel.deleteTask(task.id);
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Đã xóa "${task.title}"'),
                                ),
                              );
                            } catch (e) {
                              debugPrint("Lỗi xóa từ dialog: $e");
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Lỗi khi xóa: ${vm.error ?? e.toString()}',
                                  ),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          },
                  child:
                      vm.isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.error,
                            ),
                          )
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
    );
  }

  void _navigateToAddTask(BuildContext context) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );
  }

  void _navigateToManageCategories(BuildContext context) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
    );
  }

  void _onFilterIconPressed() {
    final taskViewModel = context.read<TaskViewModel>();
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          theme.bottomSheetTheme.modalBackgroundColor ??
          (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tùy chọn lọc & Quản lý',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<TaskViewModel>(
                  builder: (context, vm, child) {
                    return SwitchListTile(
                      title: const Text('Hiển thị công việc đã hoàn thành'),
                      value: vm.showCompleted,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        taskViewModel.toggleShowCompleted(value);
                      },
                      activeColor: theme.primaryColor,
                    );
                  },
                ),
                Divider(color: theme.dividerColor),
                ListTile(
                  leading: Icon(
                    Icons.category_outlined,
                    color: theme.listTileTheme.iconColor,
                  ),
                  title: const Text('Quản lý phân loại'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    final navContext = context;
                    Navigator.pop(context);
                    _navigateToManageCategories(navContext);
                  },
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
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
    final currentFilter = taskViewModel.selectedCategoryFilter;
    final filterOptions = ['Tất cả', ...categories.where((c) => c != 'Tất cả')];

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
        actions: [
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
      body: Consumer<TaskViewModel>(
        builder: (context, vm, child) {
          return IndexedStack(index: _currentIndex, children: screens);
        },
      ),
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
    String? currentFilterValue,
  ) {
    Widget bodyContent;
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final groupedTasksMap = taskVM.groupedTasks;
    final visibleSectionKeys = groupedTasksMap.keys.toList();
    final isLoading = taskVM.isLoading;
    final error = taskVM.error;
    final bool categoriesStillLoading =
        catVM.isLoading && catVM.categories.isEmpty;

    final Color? expansionTitleColor =
        isDarkMode
            ? theme.textTheme.titleMedium?.color?.withAlpha(204)
            : Colors.blueGrey.shade800;
    final Color? emptyTextColor =
        isDarkMode
            ? theme.textTheme.bodyMedium?.color?.withAlpha(153)
            : Colors.grey[700];
    final Color filterBarBorderColor =
        isDarkMode ? theme.dividerColor : Colors.grey.shade300;
    final Color filterBarBackgroundColor =
        isDarkMode ? theme.colorScheme.surface : Colors.white;
    final Color expansionTileBorderColor =
        isDarkMode ? theme.dividerColor : Colors.grey.shade300;
    final Color? filterIconColor =
        isDarkMode ? theme.iconTheme.color?.withAlpha(179) : Colors.grey[700];

    if (error != null && !isLoading) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text("Đã xảy ra lỗi", style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: emptyTextColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                onPressed:
                    isLoading
                        ? null
                        : () {
                          context.read<TaskViewModel>().loadTasks();
                        },
              ),
            ],
          ),
        ),
      );
    } else if (isLoading && groupedTasksMap.isEmpty) {
      bodyContent = Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
    } else if (groupedTasksMap.isEmpty && !isLoading) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            taskVM.selectedCategoryFilter != null
                ? 'Không có công việc nào trong phân loại "${taskVM.selectedCategoryFilter}".'
                : 'Bạn chưa có công việc nào.\nNhấn (+) để thêm công việc mới!',
            textAlign: TextAlign.center,
            style: TextStyle(color: emptyTextColor, fontSize: 16, height: 1.5),
          ),
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        onRefresh: () async {
          await context.read<TaskViewModel>().loadTasks();
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
                  color: expansionTitleColor,
                ),
              ),
              initiallyExpanded:
                  sectionTitle == 'Hôm nay' || sectionTitle == 'Quá hạn',
              maintainState: true,
              collapsedIconColor:
                  isDarkMode ? Colors.grey[500] : Colors.blueGrey,
              iconColor: theme.primaryColor,
              shape: Border(
                bottom: BorderSide(color: expansionTileBorderColor, width: 0.5),
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              childrenPadding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              backgroundColor:
                  isDarkMode
                      ? theme.expansionTileTheme.backgroundColor
                      : Colors.grey.shade50,
              collapsedBackgroundColor:
                  isDarkMode
                      ? theme.expansionTileTheme.collapsedBackgroundColor
                      : Colors.transparent,
              children:
                  tasksInSection
                      .map((taskData) => _buildTaskItem(context, taskData))
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
          decoration: BoxDecoration(
            color: filterBarBackgroundColor,
            border: Border(bottom: BorderSide(color: filterBarBorderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child:
                    categoriesStillLoading
                        ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor,
                            ),
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
                              onSelected:
                                  (_) => taskVM.setCategoryFilter(filterValue),
                            );
                          },
                        ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: "Lọc & Tùy chọn",
                onPressed: _onFilterIconPressed,
                color: filterIconColor,
                splashRadius: 20,
              ),
            ],
          ),
        ),
        Expanded(child: bodyContent),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskViewData taskData) {
    final taskViewModel = context.read<TaskViewModel>();
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final String title = taskData.title;
    final String subtitleText = taskData.displaySubtitle;
    final String trailingInfo = taskData.formattedDueTime;
    final Color priorityColor = taskData.priorityColor;
    final bool isDone = taskData.isDone;
    final bool isOverdue = taskData.isOverdue;
    final IconData? sticker = taskData.sticker;

    final Color? titleColor =
        isDone
            ? (isDarkMode
                ? theme.textTheme.bodyLarge?.color?.withAlpha(128)
                : Colors.grey[600])
            : (isDarkMode ? theme.textTheme.bodyLarge?.color : Colors.black87);
    final Color? subtitleColor =
        isDarkMode
            ? theme.textTheme.bodySmall?.color?.withAlpha(179)
            : Colors.grey[600];
    // ignore: unnecessary_nullable_for_final_variable_declarations
    final Color? overdueColor =
        isDarkMode ? theme.colorScheme.error : Colors.red.shade700;
    final Color? timeColor =
        isOverdue
            ? overdueColor
            : (isDarkMode
                ? theme.textTheme.bodySmall?.color?.withAlpha(204)
                : Colors.grey[700]);
    final Color? popupIconColor =
        isDarkMode ? theme.iconTheme.color?.withAlpha(153) : Colors.grey;
    final Color itemDividerColor =
        isDarkMode ? theme.dividerColor.withAlpha(128) : Colors.grey.shade200;

    return InkWell(
      onTap: () => _navigateToEditTask(context, taskData.originalTask),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: itemDividerColor, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isDone,
                  onChanged: (v) {
                    if (v != null) taskViewModel.toggleTaskDone(taskData.id);
                  },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (sticker != null)
                        Icon(sticker, size: 18, color: theme.primaryColor),
                      if (sticker != null) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitleText.isNotEmpty) const SizedBox(height: 4),
                  if (subtitleText.isNotEmpty)
                    Text(
                      subtitleText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.flag, color: priorityColor, size: 18),
                    if (trailingInfo.isNotEmpty) const SizedBox(height: 4),
                    if (trailingInfo.isNotEmpty)
                      Text(
                        trailingInfo,
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 12,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: popupIconColor),
                  tooltip: 'Tùy chọn khác',
                  iconSize: 20,
                  padding: const EdgeInsets.all(0),
                  splashRadius: 18,
                  onSelected: (String result) {
                    if (result == 'edit') {
                      _navigateToEditTask(context, taskData.originalTask);
                    } else if (result == 'delete') {
                      _confirmDeleteTask(context, taskData.originalTask);
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: theme.iconTheme.color,
                              ),
                              const SizedBox(width: 8),
                              const Text('Sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'delete',
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Xóa',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSearchDelegate extends SearchDelegate<Task?> {
  @override
  String? get searchFieldLabel => 'Tìm công việc...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.hintColor.withAlpha(153)),
        border: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.primaryColor,
        // ignore: deprecated_member_use
        selectionColor: theme.primaryColor.withOpacity(0.3),
        selectionHandleColor: theme.primaryColor,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    final theme = Theme.of(context);
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: theme.iconTheme.color?.withAlpha(179)),
          tooltip: 'Xóa tìm kiếm',
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
      tooltip: 'Quay lại',
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final taskViewModel = context.read<TaskViewModel>();
    final List<TaskViewData> results = taskViewModel.searchTasks(query);

    if (results.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy kết quả nào cho "$query".',
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final taskData = results[index];
        final Color? tileColor =
            taskData.isDone
                ? (isDarkMode
                    ? theme.disabledColor.withAlpha(26)
                    : Colors.grey.shade100)
                : null;

        return ListTile(
          leading: Icon(
            taskData.isDone ? Icons.check_box : Icons.check_box_outline_blank,
            color: taskData.isDone ? theme.disabledColor : theme.primaryColor,
          ),
          title: Row(
            children: [
              if (taskData.sticker != null)
                Icon(taskData.sticker, size: 18, color: theme.primaryColor),
              if (taskData.sticker != null) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  taskData.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration:
                        taskData.isDone ? TextDecoration.lineThrough : null,
                    color: taskData.isDone ? theme.disabledColor : null,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            taskData.displaySubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: theme.hintColor),
          ),
          trailing: Icon(Icons.flag, color: taskData.priorityColor, size: 18),
          onTap: () => close(context, taskData.originalTask),
          tileColor: tileColor,
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final taskViewModel = context.read<TaskViewModel>();

    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          'Nhập từ khóa để tìm kiếm...',
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }

    final List<TaskViewData> suggestions =
        taskViewModel.searchTasks(query).take(10).toList();

    if (suggestions.isEmpty) {
      return Center(
        child: Text(
          'Không có gợi ý nào cho "$query".',
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final taskData = suggestions[index];
        return ListTile(
          leading: Icon(
            taskData.sticker ?? Icons.label_outline,
            color:
                isDarkMode
                    ? theme.iconTheme.color?.withAlpha(179)
                    : Colors.grey[600],
          ),
          title: Text(taskData.title),
          subtitle: Text(
            taskData.categoryDisplay.isNotEmpty
                ? taskData.categoryDisplay
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                : (taskData.originalTask.description.length > 30
                    ? '${taskData.originalTask.description.substring(0, 30)}...'
                    : taskData.originalTask.description),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.hintColor),
          ),
          onTap: () {
            close(context, taskData.originalTask);
          },
        );
      },
    );
  }
}
