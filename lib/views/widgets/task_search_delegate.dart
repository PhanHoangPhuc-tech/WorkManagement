import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/task_view_data.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';

// Bỏ dấu gạch dưới _ ở tên class
class TaskSearchDelegate extends SearchDelegate<Task?> {
  @override
  String? get searchFieldLabel => 'Tìm công việc...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    // Thêm kiểm tra null và giá trị mặc định an toàn hơn
    final Color iconColor =
        theme.appBarTheme.iconTheme?.color ??
        (isDarkMode ? Colors.white70 : Colors.black54);
    final Color appBarColor =
        theme.appBarTheme.backgroundColor ??
        (isDarkMode ? Colors.grey[850]! : Colors.white);

    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: appBarColor,
        elevation: 1.0,
        iconTheme: IconThemeData(color: iconColor),
        actionsIconTheme: IconThemeData(color: iconColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.hintColor.withAlpha(153)),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.primaryColor,
        selectionColor: theme.primaryColor.withAlpha(77),
        selectionHandleColor: theme.primaryColor,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color iconColor =
        theme.appBarTheme.iconTheme?.color ??
        (isDarkMode ? Colors.white70 : Colors.black54);
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: iconColor),
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
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color iconColor =
        theme.appBarTheme.iconTheme?.color ??
        (isDarkMode ? Colors.white70 : Colors.black54);
    return IconButton(
      icon: Icon(Icons.arrow_back, color: iconColor),
      tooltip: 'Quay lại',
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    // Sử dụng context.read để lấy ViewModel khi cần
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
                    ? theme.disabledColor.withAlpha(10)
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
            // Hiển thị category hoặc description làm subtitle
            taskData.categoryDisplay.isNotEmpty
                ? taskData.categoryDisplay
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                : taskData.originalTask.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: theme.hintColor),
          ),
          trailing: Icon(
            Icons.flag_outlined,
            color: taskData.priorityColor,
            size: 18,
          ),
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
    // Sử dụng context.read để lấy ViewModel khi cần
    final taskViewModel = context.read<TaskViewModel>();

    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          'Nhập từ khóa để tìm kiếm công việc...',
          style: TextStyle(color: theme.hintColor),
        ),
      );
    }

    final List<TaskViewData> suggestions =
        taskViewModel.searchTasks(query).take(8).toList();

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
                : (taskData.originalTask.description.length > 40
                    ? '${taskData.originalTask.description.substring(0, 40)}...'
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
