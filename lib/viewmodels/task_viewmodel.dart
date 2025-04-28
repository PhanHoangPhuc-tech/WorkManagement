import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/repositories/itask_repository.dart';
import 'package:workmanagement/viewmodels/task_view_data.dart';

class TaskViewModel with ChangeNotifier {
  final ITaskRepository _repository;
  final _uuid = const Uuid();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategoryFilter;
  bool _showCompleted = true;

  TaskViewModel(this._repository) {
    loadTasks();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  bool get showCompleted => _showCompleted;
  List<Task> get allRawTasks => UnmodifiableListView(_tasks);

  List<Task> get _filteredAndSortedTasks {
    List<Task> filtered = List.from(_tasks);

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
      if (showCompleted) {
        bool aIsDone = a.isDone;
        bool bIsDone = b.isDone;
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

      final timeA = a.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
      final timeB = b.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
      int timeComparison = _compareTimeOfDay(timeA, timeB);
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
    if (task.isDone && showCompleted) return 99;
    if (task.dueDate == null) return 3;
    final taskDateOnly = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    if (taskDateOnly.isBefore(today)) return 0;
    if (taskDateOnly.isAtSameMomentAs(today)) return 1;
    return 2;
  }

  int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    final timeA = a.hour * 60 + a.minute;
    final timeB = b.hour * 60 + b.minute;
    return timeA.compareTo(timeB);
  }

  int _compareTasksByTimeAndPriority(Task a, Task b) {
    final timeA = a.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    final timeB = b.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    int timeComparison = _compareTimeOfDay(timeA, timeB);
    if (timeComparison != 0) return timeComparison;
    return b.priority.index.compareTo(a.priority.index);
  }

  Map<String, List<TaskViewData>> get groupedTasks {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final List<Task> tasksToGroup = _filteredAndSortedTasks;

    final Map<String, List<TaskViewData>> sections = {
      'Quá hạn': [],
      'Hôm nay': [],
      'Tương lai': [],
      'Chưa xác định': [],
      if (_showCompleted) 'Đã hoàn thành': [],
    };

    for (var task in tasksToGroup) {
      final taskViewData = _createTaskViewData(task, todayStart);

      if (task.isDone) {
        if (_showCompleted) {
          sections['Đã hoàn thành']!.add(taskViewData);
        }
      } else if (task.dueDate != null) {
        final taskDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (taskDate.isBefore(todayStart)) {
          sections['Quá hạn']!.add(taskViewData);
        } else if (taskDate.isAtSameMomentAs(todayStart)) {
          sections['Hôm nay']!.add(taskViewData);
        } else {
          sections['Tương lai']!.add(taskViewData);
        }
      } else {
        sections['Chưa xác định']!.add(taskViewData);
      }
    }

    sections['Hôm nay']?.sort(
      (a, b) => _compareTasksByTimeAndPriority(a.originalTask, b.originalTask),
    );
    sections['Tương lai']?.sort((a, b) {
      int dateComparison = a.originalTask.dueDate!.compareTo(
        b.originalTask.dueDate!,
      );
      if (dateComparison != 0) return dateComparison;
      return _compareTasksByTimeAndPriority(a.originalTask, b.originalTask);
    });

    sections.removeWhere((key, value) => value.isEmpty);
    return sections;
  }

  TaskViewData _createTaskViewData(Task task, DateTime todayStart) {
    final dateFormat = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    ); // Lỗi LocaleDataException xảy ra nếu chưa initialize
    String formattedDueDate = '';
    String formattedDueTime = '';
    List<String> subtitleParts = [];
    bool isOverdue = false;

    if (task.dueDate != null) {
      formattedDueDate = dateFormat.format(task.dueDate!);
      subtitleParts.add(formattedDueDate);

      if (task.dueTime != null) {
        formattedDueTime =
            '${task.dueTime!.hour.toString().padLeft(2, '0')}:${task.dueTime!.minute.toString().padLeft(2, '0')}';
      }
    }

    if (!task.isDone && task.dueDate != null) {
      final taskDateOnly = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      if (taskDateOnly.isBefore(todayStart)) {
        isOverdue = true;
      }
    }

    if (task.description.isNotEmpty) {
      subtitleParts.add(task.description);
    }
    final String categoryDisplay =
        task.category != null && task.category!.isNotEmpty
            ? '[${task.category}]'
            : '';
    if (categoryDisplay.isNotEmpty) {
      subtitleParts.add(categoryDisplay);
    }
    final String displaySubtitle = subtitleParts.join(' • ');

    return TaskViewData(
      id: task.id,
      title: task.title,
      displaySubtitle: displaySubtitle,
      formattedDueDate: formattedDueDate,
      formattedDueTime: formattedDueTime,
      categoryDisplay: categoryDisplay,
      isDone: task.isDone,
      isOverdue: isOverdue,
      priorityColor: task.priority.priorityColor,
      sticker: task.sticker,
      originalTask: task,
    );
  }

  Future<void> loadTasks() async {
    if (_isLoading) return;
    _setLoading(true);
    _error = null;
    try {
      _tasks = await _repository.getAllTasks();
      debugPrint("Tải thành công ${_tasks.length} công việc.");
    } catch (e, s) {
      _setError("Lỗi tải công việc: $e", s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTask(Task task) async {
    if (_isLoading) {
      debugPrint("ViewModel đang bận, bỏ qua addTask");
      return;
    }
    _setLoading(true);
    _error = null;
    try {
      final taskToAdd = task.id.isEmpty ? task.copyWith(id: _uuid.v4()) : task;
      final addedTask = await _repository.addTask(taskToAdd);
      _tasks.insert(0, addedTask);
      debugPrint("Thêm thành công task: ${addedTask.title}");
    } catch (e, s) {
      _setError("Lỗi thêm công việc: $e", s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask(Task task) async {
    if (_isLoading) {
      debugPrint("ViewModel đang bận, bỏ qua updateTask");
      return;
    }
    _error = null;

    Task? originalTask;
    final index = _tasks.indexWhere((t) => t.id == task.id);

    if (index == -1) {
      _setError("Lỗi: Không tìm thấy task để cập nhật.", null);
      return;
    }

    originalTask = _tasks[index];

    _tasks[index] = task;
    notifyListeners();

    try {
      await _repository.updateTask(task);
      debugPrint("Cập nhật thành công task: ${task.title}");
    } catch (e, s) {
      // --- SỬA LỖI Ở ĐÂY: Xóa dấu ! ---
      _tasks[index] = originalTask;
      // -----------------------------
      _setError("Lỗi cập nhật công việc: $e", s);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_isLoading) {
      debugPrint("ViewModel đang bận, bỏ qua deleteTask");
      return;
    }
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      _setError("Lỗi: Không tìm thấy task để xóa.", null);
      return;
    }

    final taskToDelete = _tasks[index];
    _tasks.removeAt(index);
    notifyListeners();

    try {
      await _repository.deleteTask(taskId);
      debugPrint("Xóa thành công task ID: $taskId");
    } catch (e, s) {
      _tasks.insert(index, taskToDelete);
      _setError("Lỗi xóa công việc: $e", s);
      notifyListeners();
    }
  }

  Future<void> toggleTaskDone(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final originalTask = _tasks[index];
      final updatedTask = originalTask.copyWith(isDone: !originalTask.isDone);

      _tasks[index] = updatedTask;
      notifyListeners();

      try {
        await _repository.updateTask(updatedTask);
        debugPrint("Toggle thành công task: ${updatedTask.title}");
      } catch (e, s) {
        _tasks[index] = originalTask;
        _setError("Lỗi cập nhật trạng thái: $e", s);
        notifyListeners();
      }
    } else {
      _setError("Lỗi: Không tìm thấy task để toggle.", null);
    }
  }

  Future<void> handleCategoryDeleted(String deletedCategoryName) async {
    if (_isLoading) {
      debugPrint("ViewModel đang bận, bỏ qua handleCategoryDeleted");
      return;
    }
    _error = null;
    List<Task> originalTasksState = List.from(_tasks);
    String? originalFilter = _selectedCategoryFilter;
    bool stateChanged = false;

    List<Task> tasksToUpdateApi = [];
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].category == deletedCategoryName) {
        final updatedTask = _tasks[i].copyWith(setCategoryNull: true);
        _tasks[i] = updatedTask;
        tasksToUpdateApi.add(updatedTask);
        stateChanged = true;
      }
    }
    if (_selectedCategoryFilter == deletedCategoryName) {
      _selectedCategoryFilter = null;
      stateChanged = true;
    }

    if (stateChanged) {
      notifyListeners();
    }

    try {
      if (tasksToUpdateApi.isNotEmpty) {
        await _repository.updateTasksCategory(deletedCategoryName, null);
        debugPrint(
          "API: Cập nhật category null cho '$deletedCategoryName' thành công.",
        );
      }
    } catch (e, s) {
      _tasks = originalTasksState;
      _selectedCategoryFilter = originalFilter;
      _setError("Lỗi cập nhật phân loại CV khi xóa category: $e", s);
      notifyListeners();
    }
  }

  void setCategoryFilter(String? category) {
    final newFilter =
        (category == 'Tất cả' || category == null || category.isEmpty)
            ? null
            : category;
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

  List<TaskViewData> searchTasks(String query) {
    if (query.isEmpty) return [];

    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final results =
        _tasks.where((t) {
          final titleMatch = t.title.toLowerCase().contains(q);
          final descriptionMatch = t.description.toLowerCase().contains(q);
          final categoryMatch = t.category?.toLowerCase().contains(q) ?? false;
          return titleMatch || descriptionMatch || categoryMatch;
        }).toList();

    return results
        .map((task) => _createTaskViewData(task, todayStart))
        .toList();
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message, StackTrace? stackTrace) {
    if (_error != message) {
      _error = message;
      if (message != null) {
        debugPrint("ViewModel Error: $message");
        if (stackTrace != null) {
          debugPrint("$stackTrace");
        }
      }
      notifyListeners();
    }
  }
}
