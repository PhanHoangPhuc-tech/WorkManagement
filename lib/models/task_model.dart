import 'package:flutter/material.dart';

enum Priority { low, medium, high }

class Subtask {
  String title;
  bool isDone;

  Subtask({required this.title, this.isDone = false});
}

extension PriorityExtension on Priority {
  Color get priorityColor {
    switch (this) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  String get priorityText {
    switch (this) {
      case Priority.high:
        return 'Cao';
      case Priority.medium:
        return 'Trung Bình';
      case Priority.low:
        return 'Thấp';
    }
  }
}

class Task {
  String id;
  String title;
  String description;
  Priority priority;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  List<Subtask> subtasks;
  String? category;
  IconData? sticker;
  List<String>? attachments;
  bool isDone;
  DateTime createdAt;
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    this.dueDate,
    this.dueTime,
    List<Subtask>? subtasks,
    this.category,
    this.sticker,
    this.attachments,
    this.isDone = false,
    DateTime? createdAt,
    DateTime? completedAtParam,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       subtasks = subtasks ?? [],
       createdAt = createdAt ?? DateTime.now() {
    if (isDone) {
      completedAt = completedAtParam ?? DateTime.now();
    } else {
      completedAt = null;
    }
  }

  void setDone(bool done) {
    isDone = done;
    completedAt = done ? DateTime.now() : null;
  }
}
