import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/task_view_data.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'dart:collection';

enum CalendarFilterRange { today, thisWeek, thisMonth, thisYear, allTime }

class CalendarViewModel with ChangeNotifier {
  final TaskViewModel _taskViewModel;

  late List<Task> _allTasks;
  late LinkedHashMap<DateTime, List<TaskViewData>> _events;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFilterRange _selectedFilter = CalendarFilterRange.allTime;

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;
  CalendarFilterRange get selectedFilter => _selectedFilter;

  List<TaskViewData> get tasksForFilterRange {
    final range = _getDateTimeRangeForFilter(_selectedFilter);
    final start = range.start;
    final end = range.end;
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    List<Task> filteredTasks =
        _allTasks.where((task) {
          if (task.dueDate == null) return false;
          final taskDateOnly = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          return !taskDateOnly.isBefore(start) && taskDateOnly.isBefore(end);
        }).toList();

    filteredTasks.sort((a, b) {
      int dateCompare = a.dueDate!.compareTo(b.dueDate!);
      if (dateCompare != 0) return dateCompare;
      return _compareTasksByTimeAndPriority(a, b);
    });

    return filteredTasks
        .map((task) => _createTaskViewData(task, todayStart))
        .toList();
  }

  List<TaskViewData> get tasksForSelectedDay => _getTasksForDay(_selectedDay);

  CalendarViewModel(this._taskViewModel) {
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
    _allTasks = _taskViewModel.allRawTasks;
    _events = _groupTasksByDay(_allTasks);
    _taskViewModel.addListener(_onTaskViewModelChanged);
  }

  @override
  void dispose() {
    _taskViewModel.removeListener(_onTaskViewModelChanged);
    super.dispose();
  }

  void _onTaskViewModelChanged() {
    _allTasks = _taskViewModel.allRawTasks;
    _events = _groupTasksByDay(_allTasks);
    notifyListeners();
  }

  LinkedHashMap<DateTime, List<TaskViewData>> _groupTasksByDay(
    List<Task> tasks,
  ) {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final map = LinkedHashMap<DateTime, List<TaskViewData>>(
      equals: isSameDay,
      hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
    );
    for (final task in tasks) {
      if (task.dueDate != null) {
        final dateOnly = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        final viewData = _createTaskViewData(task, todayStart);
        final list = map.putIfAbsent(dateOnly, () => []);
        list.add(viewData);
      }
    }
    map.forEach((date, tasks) {
      tasks.sort(
        (a, b) =>
            _compareTasksByTimeAndPriority(a.originalTask, b.originalTask),
      );
    });
    return map;
  }

  List<TaskViewData> _getTasksForDay(DateTime? day) {
    if (day == null) return [];
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _events[dateOnly] ?? [];
  }

  List<TaskViewData> getEventsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _events[dateOnly] ?? [];
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final selectedDateOnly = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final currentSelectedDateOnly =
        _selectedDay != null
            ? DateTime(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
            )
            : null;
    final newFocusedDay = DateTime(
      focusedDay.year,
      focusedDay.month,
      focusedDay.day,
    );

    bool changed = false;
    if (currentSelectedDateOnly == null ||
        !isSameDay(currentSelectedDateOnly, selectedDateOnly)) {
      _selectedDay = selectedDateOnly;
      _focusedDay = newFocusedDay;
      changed = true;
    } else if (!isSameDay(_focusedDay, newFocusedDay)) {
      _focusedDay = newFocusedDay;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void onPageChanged(DateTime focusedDay) {
    final newFocusedDay = DateTime(
      focusedDay.year,
      focusedDay.month,
      focusedDay.day,
    );
    if (!isSameDay(_focusedDay, newFocusedDay)) {
      _focusedDay = newFocusedDay;
      notifyListeners(); // Đã thêm dòng này
    }
  }

  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      _calendarFormat = format;
      notifyListeners();
    }
  }

  void selectToday() {
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    bool changed = false;
    if (!isSameDay(_selectedDay, todayDateOnly)) {
      _selectedDay = todayDateOnly;
      changed = true;
    }
    if (!isSameDay(_focusedDay, todayDateOnly)) {
      _focusedDay = todayDateOnly;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void setFilter(CalendarFilterRange newFilter) {
    if (_selectedFilter != newFilter) {
      _selectedFilter = newFilter;
      notifyListeners();
    }
  }

  DateTimeRange _getDateTimeRangeForFilter(CalendarFilterRange filter) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (filter) {
      case CalendarFilterRange.today:
        return DateTimeRange(
          start: todayStart,
          end: todayStart.add(const Duration(days: 1)),
        );
      case CalendarFilterRange.thisWeek:
        final daysToSubtract = (now.weekday - DateTime.monday + 7) % 7;
        final startOfWeek = todayStart.subtract(Duration(days: daysToSubtract));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case CalendarFilterRange.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth =
            (now.month < 12)
                ? DateTime(now.year, now.month + 1, 1)
                : DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case CalendarFilterRange.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case CalendarFilterRange.allTime:
        final tenYearsAgo = DateTime(now.year - 10, 1, 1);
        final endOfThisYear = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: tenYearsAgo, end: endOfThisYear);
    }
  }

  TaskViewData _createTaskViewData(Task task, DateTime todayStart) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');
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
}
