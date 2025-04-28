import 'package:flutter/material.dart';
import 'package:workmanagement/models/task_model.dart';

class TaskViewData {
  final String id;
  final String title;
  final String displaySubtitle;
  final String formattedDueDate;
  final String formattedDueTime;
  final String categoryDisplay;
  final bool isDone;
  final bool isOverdue;
  final Color priorityColor;
  final IconData? sticker;
  final Task originalTask;

  TaskViewData({
    required this.id,
    required this.title,
    required this.displaySubtitle,
    required this.formattedDueDate,
    required this.formattedDueTime,
    required this.categoryDisplay,
    required this.isDone,
    required this.isOverdue,
    required this.priorityColor,
    this.sticker,
    required this.originalTask,
  });
}
