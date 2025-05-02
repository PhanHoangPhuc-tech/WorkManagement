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
import 'package:workmanagement/views/widgets/task_search_delegate.dart';
import 'package:workmanagement/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TaskSearchDelegate _searchDelegate = TaskSearchDelegate();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _requestNotificationPermissions);
  }

  Future<void> _requestNotificationPermissions() async {
    bool granted = await _notificationService.requestPermissions();
    if (!granted) {
      debugPrint("Quyền thông báo không được cấp khi khởi tạo HomePage.");
      PermissionStatus status = await Permission.notification.status;
      if (status.isPermanentlyDenied && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text("Yêu cầu quyền thông báo"),
                content: const Text(
                  "Ứng dụng cần quyền thông báo để gửi nhắc nhở công việc. Vui lòng cấp quyền trong cài đặt ứng dụng.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Để sau"),
                  ),
                  TextButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Mở cài đặt"),
                  ),
                ],
              ),
        );
      }
    } else {
      debugPrint(
        "Quyền thông báo đã được cấp (hoặc cấp trước đó) khi khởi tạo HomePage.",
      );
    }

    PermissionStatus exactAlarmStatus =
        await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text("Yêu cầu quyền lên lịch chính xác"),
              content: const Text(
                "Ứng dụng cần quyền 'Báo thức và lời nhắc' để đảm bảo nhắc nhở đúng giờ. Vui lòng bật quyền này trong cài đặt.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Để sau"),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Mở cài đặt"),
                ),
              ],
            ),
      );
    } else if (exactAlarmStatus.isGranted) {
      debugPrint("Quyền ScheduleExactAlarm đã được cấp.");
    }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Tùy chọn lọc & Quản lý',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildTaskListPage(context),
      const CalendarScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskFlow',
          style: TextStyle(
            fontSize: 24, // <<--- Tăng kích thước chữ ở đây
            fontWeight: FontWeight.bold, // Optional: Làm đậm chữ nếu muốn
          ),
        ),
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
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildTaskListPage(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final catVM = context.watch<CategoryViewModel>();
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final categories = catVM.categories;
    final filterOptions = ['Tất cả', ...categories.where((c) => c != 'Tất cả')];

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
        isDarkMode ? theme.dividerColor.withAlpha(51) : Colors.grey.shade300;
    final Color filterBarBackgroundColor =
        isDarkMode ? theme.colorScheme.surface : Colors.white;
    final Color expansionTileBorderColor =
        isDarkMode ? theme.dividerColor.withAlpha(51) : Colors.grey.shade300;
    final Color? filterIconColor =
        isDarkMode ? theme.iconTheme.color?.withAlpha(179) : Colors.grey[700];
    final Color chipSelectedBgColor = theme.primaryColor.withAlpha(
      isDarkMode ? 70 : 30,
    );
    final Color chipUnselectedBgColor =
        isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final Color chipSelectedTextColor = theme.primaryColor;
    final Color? chipUnselectedTextColor = theme.textTheme.bodySmall?.color;
    final BorderSide chipUnselectedBorder = BorderSide(
      color: filterBarBorderColor,
      width: 0.5,
    );
    final BorderSide chipSelectedBorder = BorderSide(
      color: theme.primaryColor.withAlpha(150),
      width: 1,
    );

    Widget bodyContent;

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
                        : () => context.read<TaskViewModel>().loadTasks(),
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
          await Future.wait([
            context.read<TaskViewModel>().loadTasks(),
            context.read<CategoryViewModel>().loadCategories(),
          ]);
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
                left: 0,
                right: 0,
                bottom: 8.0,
              ),
              backgroundColor:
                  isDarkMode
                      ? theme.cardColor.withAlpha(10)
                      : Colors.grey.shade50,
              collapsedBackgroundColor: Colors.transparent,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: filterBarBackgroundColor,
            border: Border(
              bottom: BorderSide(color: filterBarBorderColor, width: 0.5),
            ),
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
                          itemCount: filterOptions.length,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final filterName = filterOptions[idx];
                            final filterValue =
                                filterName == 'Tất cả' ? null : filterName;
                            final isSelected =
                                taskVM.selectedCategoryFilter == filterValue;
                            return ChoiceChip(
                              label: Text(filterName),
                              selected: isSelected,
                              onSelected:
                                  (_) => taskVM.setCategoryFilter(filterValue),
                              selectedColor: chipSelectedBgColor,
                              backgroundColor: chipUnselectedBgColor,
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color:
                                    isSelected
                                        ? chipSelectedTextColor
                                        : chipUnselectedTextColor,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                              side:
                                  isSelected
                                      ? chipSelectedBorder
                                      : chipUnselectedBorder,
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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
                visualDensity: VisualDensity.compact,
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
        isDarkMode
            ? theme.colorScheme.error.withAlpha(220)
            : Colors.red.shade700;
    final Color? timeColor =
        isOverdue && !isDone
            ? overdueColor
            : (isDarkMode
                ? theme.textTheme.bodySmall?.color?.withAlpha(204)
                : Colors.grey[700]);
    final Color? popupIconColor =
        isDarkMode ? theme.iconTheme.color?.withAlpha(153) : Colors.grey[600];
    final Color itemDividerColor =
        isDarkMode ? theme.dividerColor.withAlpha(51) : Colors.grey.shade200;

    return InkWell(
      onTap: () => _navigateToEditTask(context, taskData.originalTask),
      child: Container(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 4.0,
          top: 12.0,
          bottom: 12.0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: itemDividerColor, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => taskViewModel.toggleTaskDone(taskData.id),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 12.0,
                  left: 0,
                  top: 4,
                  bottom: 4,
                ),
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
                    activeColor: theme.primaryColor,
                    checkColor: theme.colorScheme.onPrimary,
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
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
                        Icon(
                          sticker,
                          size: 18,
                          color:
                              isDone
                                  ? titleColor?.withAlpha(150)
                                  : theme.primaryColor.withAlpha(220),
                        ),
                      if (sticker != null) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
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
                    Icon(
                      Icons.flag_outlined,
                      color:
                          isDone ? priorityColor.withAlpha(100) : priorityColor,
                      size: 18,
                    ),
                    if (trailingInfo.isNotEmpty) const SizedBox(height: 4),
                    if (trailingInfo.isNotEmpty)
                      Text(
                        trailingInfo,
                        style: TextStyle(
                          color: isDone ? timeColor?.withAlpha(100) : timeColor,
                          fontSize: 12,
                          fontWeight:
                              isOverdue && !isDone
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
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
                              const SizedBox(width: 12),
                              const Text('Sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
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
                              const SizedBox(width: 12),
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
                  onSelected: (String result) {
                    if (result == 'edit') {
                      _navigateToEditTask(context, taskData.originalTask);
                    } else if (result == 'delete') {
                      _confirmDeleteTask(context, taskData.originalTask);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
