import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum Priority { low, medium, high }

extension PriorityExtension on Priority {
  Color get priorityColor {
    switch (this) {
      case Priority.high:
        return Colors.red.shade600;
      case Priority.medium:
        return Colors.orange.shade700;
      case Priority.low:
        return Colors.green.shade600;
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
  }) : id = id ?? const Uuid().v4(),
       subtasks = subtasks ?? [],
       attachments = attachments ?? [],
       createdAt = createdAt ?? DateTime.now() {
    if (isDone) {
      completedAt = completedAtParam ?? DateTime.now();
    } else {
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
    bool setCompletedAtNull = false,
  }) {
    final bool finalIsDone = isDone ?? this.isDone;
    DateTime? finalCompletedAt;

    if (setCompletedAtNull) {
      finalCompletedAt = null;
    } else if (isDone != null) {
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
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      } catch (e) {
        debugPrint("Lỗi parse TimeOfDay: $e, Input: $timeString");
      }
      return null;
    }

    IconData? parseIconData(int? codePoint, String? fontFamily) {
      if (codePoint == null) return null;
      if (fontFamily == 'MaterialIcons') {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
      debugPrint(
        "Không thể parse IconData: codePoint=$codePoint, fontFamily=$fontFamily",
      );
      return null;
    }

    return Task(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority:
          Priority.values[json['priority'] as int? ?? Priority.medium.index],
      dueDate:
          json['dueDate'] == null
              ? null
              : DateTime.tryParse(json['dueDate'] as String? ?? ''),
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
              : DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}
