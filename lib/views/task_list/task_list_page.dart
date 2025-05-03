import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/views/widgets/category_filter_bar.dart';
import 'package:workmanagement/views/widgets/task_list_item.dart';

class TaskListPage extends StatelessWidget {
  final Function(BuildContext, Task) confirmDeleteTaskCallback;
  final Function(BuildContext, Task) navigateToEditTaskCallback;

  const TaskListPage({
    super.key,
    required this.confirmDeleteTaskCallback,
    required this.navigateToEditTaskCallback,
  });

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    // final catVM = context.watch<CategoryViewModel>(); // <<--- DÒNG NÀY ĐÃ ĐƯỢC XÓA
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final groupedTasksMap = taskVM.groupedTasks;
    final visibleSectionKeys = groupedTasksMap.keys.toList();
    final isLoading = taskVM.isLoading;
    final error = taskVM.error;

    final Color? expansionTitleColor = isDarkMode ? theme.textTheme.titleMedium?.color?.withAlpha(204) : Colors.blueGrey.shade800;
    final Color? emptyTextColor = isDarkMode ? theme.textTheme.bodyMedium?.color?.withAlpha(153) : Colors.grey[700];
    final Color expansionTileBorderColor = isDarkMode ? theme.dividerColor.withAlpha(51) : Colors.grey.shade300;

    Widget bodyContent;

    if (error != null && !isLoading) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text("Đã xảy ra lỗi", style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: TextStyle(color: emptyTextColor)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                onPressed: isLoading ? null : () => context.read<TaskViewModel>().loadTasks(),
              ),
            ],
          ),
        ),
      );
    } else if (isLoading && groupedTasksMap.isEmpty) {
      bodyContent = Center(child: CircularProgressIndicator(color: theme.primaryColor));
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
            context.read<CategoryViewModel>().loadCategories(), // Vẫn gọi load ở đây
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
              title: Text('$sectionTitle (${tasksInSection.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: expansionTitleColor)),
              initiallyExpanded: sectionTitle == 'Hôm nay' || sectionTitle == 'Quá hạn',
              maintainState: true,
              collapsedIconColor: isDarkMode ? Colors.grey[500] : Colors.blueGrey,
              iconColor: theme.primaryColor,
              shape: Border(bottom: BorderSide(color: expansionTileBorderColor, width: 0.5)),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              childrenPadding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
              backgroundColor: isDarkMode ? theme.cardColor.withAlpha(10) : Colors.grey.shade50,
              collapsedBackgroundColor: Colors.transparent,
              children: tasksInSection.map((taskData) => TaskListItem(
                    key: ValueKey(taskData.id),
                    taskData: taskData,
                    onTap: () => navigateToEditTaskCallback(context, taskData.originalTask),
                    onDeleteTap: () => confirmDeleteTaskCallback(context, taskData.originalTask),
                  )).toList(),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        const CategoryFilterBar(),
        Expanded(child: bodyContent),
      ],
    );
  }
}