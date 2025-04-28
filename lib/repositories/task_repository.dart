import 'package:flutter/material.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/repositories/itask_repository.dart';
import 'package:uuid/uuid.dart';

class TaskRepository implements ITaskRepository {
  final _uuid = const Uuid();

  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Làm bài tập Flutter',
      description: 'Hoàn thành UI và ViewModel',
      priority: Priority.high,
      dueDate: DateTime.now().add(const Duration(hours: -2)),
      dueTime: const TimeOfDay(hour: 9, minute: 0),
      category: 'Học tập',
      sticker: Icons.school_outlined,
      isDone: false,
    ),
    Task(
      id: '2',
      title: 'Tập thể dục buổi sáng',
      description: 'Chạy bộ 30 phút quanh công viên',
      priority: Priority.medium,
      dueDate: DateTime.now(),
      dueTime: const TimeOfDay(hour: 6, minute: 30),
      category: 'Cá nhân',
      sticker: Icons.fitness_center_outlined,
      isDone: false,
    ),
    Task(
      id: '3',
      title: 'Họp nhóm dự án A',
      description: 'Thảo luận về tiến độ và kế hoạch tuần tới',
      priority: Priority.high,
      dueDate: DateTime.now(),
      dueTime: const TimeOfDay(hour: 14, minute: 0),
      category: 'Công việc',
      sticker: Icons.group_work_outlined,
      isDone: false,
    ),
    Task(
      id: '4',
      title: 'Đi siêu thị mua đồ ăn',
      description: 'Mua rau, thịt, sữa chua',
      priority: Priority.medium,
      dueDate: DateTime.now(),
      dueTime: const TimeOfDay(hour: 17, minute: 30),
      category: 'Mua sắm',
      sticker: Icons.shopping_cart_outlined,
      isDone: false,
    ),
    Task(
      id: '5',
      title: 'Đọc sách "Clean Code"',
      description: 'Chương 3: Functions',
      priority: Priority.low,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      category: 'Học tập',
      sticker: Icons.book_outlined,
      isDone: false,
    ),
    Task(
      id: '6',
      title: 'Lên kế hoạch cho cuối tuần',
      description: 'Đi chơi hoặc ở nhà nghỉ ngơi?',
      priority: Priority.low,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      category: 'Cá nhân',
      sticker: Icons.flag_outlined,
      isDone: false,
    ),
    Task(
      id: '7',
      title: 'Nộp báo cáo công việc tuần',
      priority: Priority.high,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      dueTime: const TimeOfDay(hour: 16, minute: 0),
      category: 'Công việc',
      sticker: Icons.assessment_outlined,
      isDone: false,
    ),
    Task(
      id: '8',
      title: 'Gọi điện cho gia đình',
      priority: Priority.medium,
      sticker: Icons.call_outlined,
      category: 'Cá nhân',
      isDone: false,
    ),
    Task(
      id: '9',
      title: 'Hoàn thành Khóa học Flutter Online',
      description: 'Đã xem hết video và làm bài tập',
      priority: Priority.high,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Học tập',
      sticker: Icons.check_circle_outline,
      isDone: true,
      completedAtParam: DateTime.now().subtract(const Duration(hours: 15)),
    ),
    Task(
      id: '10',
      title: 'Dọn dẹp nhà cửa',
      priority: Priority.low,
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Việc nhà',
      sticker: Icons.cleaning_services_outlined,
      isDone: true,
    ),
  ];

  @override
  Future<List<Task>> getAllTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Task>.from(_tasks);
  }

  @override
  Future<Task> addTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newTask = task.id.isEmpty ? task.copyWith(id: _uuid.v4()) : task;
    _tasks.insert(0, newTask);
    return newTask;
  }

  @override
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    } else {
      debugPrint(
        'Repository Error: Không tìm thấy công việc ID ${task.id} để cập nhật.',
      );
      throw Exception('Không tìm thấy công việc ID ${task.id} để cập nhật.');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final initialLength = _tasks.length;
    _tasks.removeWhere((t) => t.id == taskId);
    if (_tasks.length == initialLength) {
      debugPrint(
        'Repository Error: Không tìm thấy công việc ID $taskId để xóa.',
      );
    }
  }

  @override
  Future<void> updateTasksCategory(
    String oldCategory,
    String? newCategory,
  ) async {
    await Future.delayed(const Duration(milliseconds: 80));
    bool changed = false;
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].category == oldCategory) {
        _tasks[i] = _tasks[i].copyWith(
          category: newCategory,
          setCategoryNull: newCategory == null,
        );
        changed = true;
      }
    }
    if (changed) {
      debugPrint("Đã cập nhật category từ '$oldCategory' sang '$newCategory'");
    } else {
      debugPrint(
        "Không tìm thấy task nào có category '$oldCategory' để cập nhật.",
      );
    }
  }
}
