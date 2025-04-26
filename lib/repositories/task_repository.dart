import 'package:flutter/material.dart';
import 'package:workmanagement/Mo/task_model.dart';

// --- VẪN DÙNG IN-MEMORY ---

abstract class ITaskRepository {
  Future<List<Task>> getAllTasks();
  Future<Task> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Future<void> updateTasksCategory(String oldCategory, String? newCategory);
}

class TaskRepository implements ITaskRepository {
  // Dữ liệu mẫu
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Làm bài tập Flutter',
      description: 'Hoàn thành UI',
      priority: Priority.high,
      dueDate: DateTime.now().add(const Duration(hours: 2)),
      dueTime: const TimeOfDay(hour: 15, minute: 0),
      subtasks: [
        Subtask(title: 'Code Create', isDone: true),
        Subtask(title: 'Code Edit'),
      ],
      category: 'Học tập',
      sticker: Icons.school_outlined,
      isDone: false,
    ),
    Task(
      id: '2',
      title: 'Tập thể dục',
      description: 'Chạy bộ 30 phút',
      priority: Priority.medium,
      dueDate: DateTime.now().add(const Duration(hours: 4)),
      dueTime: const TimeOfDay(hour: 17, minute: 0),
      category: 'Cá nhân',
      sticker: Icons.fitness_center_outlined,
      isDone: false,
    ),
    Task(
      id: '3',
      title: 'Đi làm thêm',
      description: 'Ca tối',
      priority: Priority.medium,
      dueDate: DateTime.now().add(const Duration(hours: 5)),
      dueTime: const TimeOfDay(hour: 18, minute: 0),
      category: 'Công việc',
      sticker: Icons.work_outline,
      isDone: false,
    ),
    Task(
      id: '4',
      title: 'Đi học sáng',
      description: 'Lập trình di động',
      priority: Priority.high,
      dueDate: DateTime.now().subtract(const Duration(hours: 5)),
      dueTime: const TimeOfDay(hour: 7, minute: 0),
      category: 'Học tập',
      sticker: Icons.school_outlined,
      isDone: true,
      completedAtParam: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Task(
      id: '5',
      title: 'Lên kế hoạch du lịch',
      description: 'Tìm địa điểm',
      priority: Priority.low,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      category: 'Cá nhân',
      sticker: Icons.flag_outlined,
      isDone: false,
    ),
    Task(
      id: '6',
      title: 'Mua đồ ăn tối',
      description: 'Siêu thị',
      priority: Priority.medium,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Mua sắm',
      sticker: Icons.shopping_cart_outlined,
      isDone: false,
    ),
    Task(
      id: '7',
      title: 'Họp nhóm dự án',
      description: 'Online',
      priority: Priority.high,
      category: 'Công việc',
      sticker: Icons.group_work_outlined,
      isDone: false,
    ),
  ];

  @override
  Future<List<Task>> getAllTasks() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List<Task>.from(_tasks);
  }

  @override
  Future<Task> addTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final newTask = task.copyWith(
      id:
          task.id.isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toString()
              : task.id,
      createdAt: task.createdAt,
    );
    _tasks.insert(0, newTask);
    return newTask;
  }

  @override
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    } else {
      throw Exception('Không tìm thấy công việc ID ${task.id} để cập nhật.');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final initialLength = _tasks.length;
    _tasks.removeWhere((t) => t.id == taskId);
    if (_tasks.length == initialLength) {
      throw Exception('Không tìm thấy công việc ID $taskId để xóa.');
    }
  }

  @override
  Future<void> updateTasksCategory(
    String oldCategory,
    String? newCategory,
  ) async {
    await Future.delayed(const Duration(milliseconds: 20));
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].category == oldCategory) {
        _tasks[i] = _tasks[i].copyWith(
          category: newCategory,
          setCategoryNull: newCategory == null,
        );
      }
    }
  }
}
