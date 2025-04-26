import 'package:flutter/material.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/repositories/task_repository.dart';

class TaskViewModel with ChangeNotifier {
  final ITaskRepository _repository = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategoryFilter;
  bool _showCompleted = true;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  bool get showCompleted => _showCompleted;

  List<Task> get filteredAndSortedTasks {
    List<Task> filtered = _tasks;

    if (_selectedCategoryFilter != null) {
      filtered =
          filtered.where((t) => t.category == _selectedCategoryFilter).toList();
    }

    if (!_showCompleted) {
      filtered = filtered.where((t) => !t.isDone).toList();
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    filtered.sort((a, b) {
      bool aIsDone = a.isDone;
      bool bIsDone = b.isDone;

      if (showCompleted) {
        if (aIsDone != bIsDone) {
          return aIsDone ? 1 : -1;
        }
        if (aIsDone) {
          final timeA = a.completedAt ?? a.createdAt;
          final timeB = b.completedAt ?? b.createdAt;
          return timeB.compareTo(timeA);
        }
      }

      int groupA = _getTaskGroupIndex(a, todayStart);
      int groupB = _getTaskGroupIndex(b, todayStart);
      if (groupA != groupB) {
        return groupA.compareTo(groupB);
      }

      if (!a.isDone && !b.isDone) {}

      final timeA = a.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
      final timeB = b.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
      int timeComparison = (timeA.hour * 60 + timeA.minute).compareTo(
        timeB.hour * 60 + timeB.minute,
      );
      if (timeComparison != 0) {
        return timeComparison;
      }

      int priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) {
        return priorityComparison;
      }

      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  int _getTaskGroupIndex(Task task, DateTime today) {
    if (task.dueDate == null) {
      return 3;
    }
    final taskDateOnly = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    if (taskDateOnly.isBefore(today)) {
      return 0;
    }
    if (taskDateOnly.isAtSameMomentAs(today)) {
      return 1;
    }
    return 2;
  }

  int _compareTasksByTimeAndPriority(Task a, Task b) {
    final timeA = a.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    final timeB = b.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    int timeComparison = (timeA.hour * 60 + timeA.minute).compareTo(
      timeB.hour * 60 + timeB.minute,
    );
    if (timeComparison != 0) {
      return timeComparison;
    }
    return a.priority.index.compareTo(b.priority.index);
  }

  Map<String, List<Task>> get groupedTasks {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final List<Task> tasksToGroup = filteredAndSortedTasks;
    final Map<String, List<Task>> sections = {
      'Quá hạn': [],
      'Hôm nay': [],
      'Tương lai': [],
      'Chưa xác định': [],
      'Đã hoàn thành hôm nay': [],
    };

    for (var task in tasksToGroup) {
      if (task.isDone) {
        if (_showCompleted) {
          sections['Đã hoàn thành hôm nay']!.add(task);
        }
      } else if (task.dueDate != null) {
        final taskDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (taskDate.isBefore(todayStart)) {
          sections['Quá hạn']!.add(task);
        } else if (taskDate.isAtSameMomentAs(todayStart)) {
          sections['Hôm nay']!.add(task);
        } else {
          sections['Tương lai']!.add(task);
        }
      } else {
        sections['Chưa xác định']!.add(task);
      }
    }

    sections['Hôm nay']?.sort(_compareTasksByTimeAndPriority);
    sections['Tương lai']?.sort((a, b) {
      int c = a.dueDate!.compareTo(b.dueDate!);
      return c != 0 ? c : _compareTasksByTimeAndPriority(a, b);
    });
    sections['Đã hoàn thành hôm nay']?.sort(
      (a, b) => (b.completedAt ?? b.createdAt).compareTo(
        a.completedAt ?? a.createdAt,
      ),
    );
    sections.removeWhere((key, value) => value.isEmpty);
    return sections;
  }

  TaskViewModel() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _repository.getAllTasks();
    } catch (e) {
      _error = "Lỗi tải công việc: $e";
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    if (_isLoading) {
      throw Exception("Đang xử lý...");
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final taskToAdd =
          task.id.isEmpty
              ? task.copyWith(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              )
              : task;
      final addedTask = await _repository.addTask(taskToAdd);
      _tasks.insert(0, addedTask);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Lỗi thêm: $e";
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    if (_isLoading) {
      throw Exception("Đang xử lý...");
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      } else {
        _tasks.insert(0, task);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Lỗi cập nhật: $e";
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_isLoading) {
      throw Exception("Đang xử lý...");
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Lỗi xóa: $e";
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleTaskDone(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(isDone: !task.isDone);
      _tasks[index] = updatedTask;
      notifyListeners();
      _repository.updateTask(updatedTask).catchError((e) {
        _tasks[index] = task;
        _error = "Lỗi lưu";
        notifyListeners();
      });
    }
  }

  Future<void> handleCategoryDeleted(String deletedCategoryName) async {
    _error = null;
    try {
      await _repository.updateTasksCategory(deletedCategoryName, null);
      bool changed = false;
      for (int i = 0; i < _tasks.length; i++) {
        if (_tasks[i].category == deletedCategoryName) {
          _tasks[i] = _tasks[i].copyWith(setCategoryNull: true);
          changed = true;
        }
      }
      if (_selectedCategoryFilter == deletedCategoryName) {
        _selectedCategoryFilter = null;
        changed = true;
      }
      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      _error = "Lỗi cập nhật CV";
      notifyListeners();
    }
  }

  void setCategoryFilter(String? category) {
    final newFilter = (category == 'Tất cả') ? null : category;
    if (_selectedCategoryFilter != newFilter) {
      _selectedCategoryFilter = newFilter;
      notifyListeners();
    }
  }

  void toggleShowCompleted(bool show) {
    if (_showCompleted != show) {
      _showCompleted = show;
      notifyListeners();
    }
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) {
      return [];
    }
    final q = query.toLowerCase();
    return _tasks.where((t) {
      final tl = t.title.toLowerCase();
      final dl = t.description.toLowerCase();
      final cl = t.category?.toLowerCase() ?? '';
      return tl.contains(q) || dl.contains(q) || cl.contains(q);
    }).toList();
  }
}
