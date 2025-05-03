import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/task_view_data.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';

class TaskListItem extends StatelessWidget {
  final TaskViewData taskData;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  const TaskListItem({
    super.key,
    required this.taskData,
    required this.onTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
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

    final Color? titleColor = isDone ? (isDarkMode ? theme.textTheme.bodyLarge?.color?.withAlpha(128) : Colors.grey[600]) : (isDarkMode ? theme.textTheme.bodyLarge?.color : Colors.black87);
    final Color? subtitleColor = isDarkMode ? theme.textTheme.bodySmall?.color?.withAlpha(179) : Colors.grey[600];
    // ignore: unnecessary_nullable_for_final_variable_declarations
    final Color? overdueColor = isDarkMode ? theme.colorScheme.error.withAlpha(220) : Colors.red.shade700;
    final Color? timeColor = isOverdue && !isDone ? overdueColor : (isDarkMode ? theme.textTheme.bodySmall?.color?.withAlpha(204) : Colors.grey[700]);
    final Color? popupIconColor = isDarkMode ? theme.iconTheme.color?.withAlpha(153) : Colors.grey[600];
    final Color itemDividerColor = isDarkMode ? theme.dividerColor.withAlpha(51) : Colors.grey.shade200;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 16.0, right: 4.0, top: 12.0, bottom: 12.0),
         decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: itemDividerColor, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
               onTap: () => taskViewModel.toggleTaskDone(taskData.id),
               child: Padding(
                 padding: const EdgeInsets.only(right: 12.0, left: 0, top: 4, bottom: 4),
                 child: SizedBox(
                   width: 24,
                   height: 24,
                   child: Checkbox(
                     value: isDone,
                     onChanged: (v) { if (v != null) taskViewModel.toggleTaskDone(taskData.id); },
                     visualDensity: VisualDensity.compact,
                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                     activeColor: theme.primaryColor,
                     checkColor: theme.colorScheme.onPrimary,
                     side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!, width: 1.5),
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
                      if (sticker != null) Icon(sticker, size: 18, color: isDone ? titleColor?.withAlpha(150) : theme.primaryColor.withAlpha(220)),
                      if (sticker != null) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15.5, decoration: isDone ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w500, color: titleColor),
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
                      style: TextStyle(fontSize: 13, decoration: isDone ? TextDecoration.lineThrough : null, color: subtitleColor, height: 1.3),
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
                    Icon(Icons.flag_outlined, color: isDone ? priorityColor.withAlpha(100) : priorityColor, size: 18),
                    if (trailingInfo.isNotEmpty) const SizedBox(height: 4),
                    if (trailingInfo.isNotEmpty)
                      Text(
                        trailingInfo,
                        style: TextStyle(
                          color: isDone ? timeColor?.withAlpha(100) : timeColor,
                          fontSize: 12,
                          fontWeight: isOverdue && !isDone ? FontWeight.bold : FontWeight.normal,
                          decoration: isDone ? TextDecoration.lineThrough : null,
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
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit', height: 40,
                      child: Row(children: [Icon(Icons.edit_outlined, size: 20, color: theme.iconTheme.color), const SizedBox(width: 12), const Text('Sửa')]),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'delete', height: 40,
                      child: Row(children: [Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error), const SizedBox(width: 12), Text('Xóa', style: TextStyle(color: theme.colorScheme.error))]),
                    ),
                  ],
                  onSelected: (String result) {
                    if (result == 'edit') { onTap(); }
                    else if (result == 'delete') { onDeleteTap(); }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}