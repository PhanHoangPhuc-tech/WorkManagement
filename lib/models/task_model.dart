import 'package:flutter/material.dart';

// Enum cho mức độ ưu tiên
enum Priority { low, medium, high }

// Extension để lấy màu và text từ Priority
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

// Lớp cho các công việc con (subtask)
class Subtask {
  String title;
  bool isDone;

  Subtask({required this.title, this.isDone = false});

  Subtask copyWith({String? title, bool? isDone}) {
    return Subtask(title: title ?? this.title, isDone: isDone ?? this.isDone);
  }

  Map<String, dynamic> toJson() => {'title': title, 'isDone': isDone};
  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    title: json['title'] as String? ?? '',
    isDone: json['isDone'] as bool? ?? false,
  );
}

// Lớp chính cho công việc (task)
class Task {
  final String id;
  String title;
  String description;
  Priority priority;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  List<Subtask> subtasks;
  String? category;
  IconData? sticker;
  List<String> attachments;
  bool isDone;
  final DateTime createdAt;
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
    List<String>? attachments,
    this.isDone = false,
    DateTime? createdAt,
    DateTime? completedAtParam,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       subtasks = subtasks ?? [],
       attachments = attachments ?? [],
       createdAt = createdAt ?? DateTime.now() {
    completedAt = isDone ? (completedAtParam ?? DateTime.now()) : null;
    if (!isDone) {
      completedAt = null;
    }
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    Priority? priority,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    List<Subtask>? subtasks,
    String? category,
    IconData? sticker,
    List<String>? attachments,
    bool? isDone,
    DateTime? createdAt,
    DateTime? completedAt,
    bool setDueDateNull = false,
    bool setDueTimeNull = false,
    bool setCategoryNull = false,
    bool setStickerNull = false,
  }) {
    bool finalIsDone = isDone ?? this.isDone;
    DateTime? finalCompletedAt;

    if (isDone != null) {
      finalCompletedAt =
          finalIsDone
              ? (completedAt ?? this.completedAt ?? DateTime.now())
              : null;
    } else {
      finalCompletedAt = completedAt ?? this.completedAt;
      if (!finalIsDone) finalCompletedAt = null;
    }

    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: setDueDateNull ? null : (dueDate ?? this.dueDate),
      dueTime: setDueTimeNull ? null : (dueTime ?? this.dueTime),
      subtasks: subtasks ?? List.from(this.subtasks.map((s) => s.copyWith())),
      category: setCategoryNull ? null : (category ?? this.category),
      sticker: setStickerNull ? null : (sticker ?? this.sticker),
      attachments: attachments ?? List.from(this.attachments),
      isDone: finalIsDone,
      createdAt: createdAt ?? this.createdAt,
      completedAtParam: finalCompletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.index,
    'dueDate': dueDate?.toIso8601String(),
    'dueTime':
        dueTime == null
            ? null
            : '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}',
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'category': category,
    'sticker_code_point': sticker?.codePoint,
    'sticker_font_family': sticker?.fontFamily,
    'attachments': attachments,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null) return null;
      try {
        final parts = timeString.split(':');
        if (parts.length == 2) {
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        // --- LỖI 1 (Line 170): Đã xóa print ---
      }
      return null;
    }

    IconData? parseIconData(int? codePoint, String? fontFamily) {
      if (codePoint == null) return null;
      if (fontFamily == 'MaterialIcons') {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
      return null;
    }

    return Task(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority:
          Priority.values[json['priority'] as int? ?? Priority.medium.index],
      dueDate:
          json['dueDate'] == null ? null : DateTime.tryParse(json['dueDate']),
      dueTime: parseTimeOfDay(json['dueTime'] as String?),
      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      category: json['category'] as String?,
      sticker: parseIconData(
        json['sticker_code_point'] as int?,
        json['sticker_font_family'] as String?,
      ),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      isDone: json['isDone'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completedAtParam:
          json['completedAt'] == null
              ? null
              : DateTime.tryParse(json['completedAt']),
    );
  }
}
