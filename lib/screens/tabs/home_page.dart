import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/screens/tabs/create_task.dart';
import 'package:workmanagement/screens/tabs/edit_task.dart';
import 'package:workmanagement/screens/tabs/manage_categories_screen.dart';
import 'package:workmanagement/screens/tabs/calendar_screen.dart';
import 'package:workmanagement/screens/tabs/profile_screen.dart';
import 'package:workmanagement/screens/tabs/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedFilter = 0;
  int _currentIndex = 0;
  bool _showCompletedTasks = true;
  List<String> _userCategories = [];
  List<String> _activeFilters = ['Tất cả'];
  final String _prefsCategoriesKey = 'user_categories';

  // !!! Dữ liệu mẫu - Cần thay thế bằng logic lưu trữ thực tế !!!
  final List<Task> _allTasks = [
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
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList(_prefsCategoriesKey);
      List<String> loadedCategories;
      if (savedCategories != null && savedCategories.isNotEmpty) {
        loadedCategories = savedCategories;
      } else {
        loadedCategories = ['Công việc', 'Cá nhân', 'Học tập', 'Mua sắm'];
        await prefs.setStringList(_prefsCategoriesKey, loadedCategories);
      }
      loadedCategories.sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
      if (mounted) {
        setState(() {
          _userCategories = loadedCategories;
          _activeFilters = ['Tất cả', ..._userCategories];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userCategories = ['Công việc', 'Cá nhân', 'Học tập', 'Mua sắm'];
          _activeFilters = ['Tất cả', ..._userCategories];
        });
      }
    }
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsCategoriesKey, _userCategories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lưu danh sách phân loại')),
        );
      }
    }
  }

  void _updateCategoriesAndTasks(
    List<String> updatedList, {
    String? deletedCategory,
  }) {
    if (!mounted) return;
    setState(() {
      _userCategories = updatedList;
      _userCategories.sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
      _activeFilters = ['Tất cả', ..._userCategories];
      _saveCategories();

      if (deletedCategory != null) {
        bool needResetFilter = _selectedFilter > 0;
        for (var task in _allTasks) {
          if (task.category == deletedCategory) {
            task.category = null;
          }
        }
        if (needResetFilter) {
          _selectedFilter = 0;
        }
      } else if (_selectedFilter >= _activeFilters.length) {
        _selectedFilter = 0;
      }
    });
  }

  Map<String, List<Task>> _getGroupedTasks() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    List<Task> filteredByCategory = _allTasks;
    if (_selectedFilter > 0 && _selectedFilter < _activeFilters.length) {
      String category = _activeFilters[_selectedFilter];
      filteredByCategory =
          _allTasks.where((task) => task.category == category).toList();
    } else if (_selectedFilter != 0) {
      _selectedFilter = 0;
      filteredByCategory = _allTasks;
    }

    List<Task> filteredTasks = filteredByCategory;
    final Map<String, List<Task>> sections = {
      'Quá hạn': [],
      'Hôm nay': [],
      'Tương lai': [],
      'Đã hoàn thành hôm nay': [],
      'Chưa xác định': [],
    };

    for (var task in filteredTasks) {
      if (task.isDone) {
        if (task.completedAt != null) {
          final completedDateOnly = DateTime(
            task.completedAt!.year,
            task.completedAt!.month,
            task.completedAt!.day,
          );
          if (completedDateOnly.isAtSameMomentAs(todayStart)) {
            sections['Đã hoàn thành hôm nay']!.add(task);
          }
        } else {
          sections['Đã hoàn thành hôm nay']!.add(task);
        }
      } else if (task.dueDate != null) {
        final taskDateOnly = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (taskDateOnly.isBefore(todayStart)) {
          sections['Quá hạn']!.add(task);
        } else if (taskDateOnly.isAtSameMomentAs(todayStart)) {
          sections['Hôm nay']!.add(task);
        } else {
          sections['Tương lai']!.add(task);
        }
      } else {
        sections['Chưa xác định']!.add(task);
      }
    }

    sections['Quá hạn']?.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    sections['Hôm nay']?.sort((a, b) => _compareTasks(a, b));
    sections['Tương lai']?.sort((a, b) {
      int dateComparison = a.dueDate!.compareTo(b.dueDate!);
      if (dateComparison != 0) return dateComparison;
      return _compareTasks(a, b);
    });
    sections['Đã hoàn thành hôm nay']?.sort((a, b) {
      final timeA = a.completedAt ?? DateTime(1970);
      final timeB = b.completedAt ?? DateTime(1970);
      return timeB.compareTo(timeA);
    });
    sections['Chưa xác định']?.sort((a, b) => _compareTasks(a, b));

    return sections;
  }

  int _compareTasks(Task a, Task b) {
    final timeA = a.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    final timeB = b.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    int timeComparison = (timeA.hour * 60 + timeA.minute).compareTo(
      timeB.hour * 60 + timeB.minute,
    );
    if (timeComparison != 0) return timeComparison;
    return a.priority.index.compareTo(b.priority.index);
  }

  void _onFilterIconPressed() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tùy chọn lọc & Quản lý',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Hiển thị công việc đã hoàn thành'),
                  value: _showCompletedTasks,
                  onChanged: (bool value) {
                    if (mounted) {
                      setState(() {
                        _showCompletedTasks = value;
                      });
                    }
                    Navigator.pop(context);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Quản lý phân loại'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToManageCategories();
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Sắp xếp theo... (Chưa cài đặt)'),
                ),
              ],
            ),
          ),
    );
  }

  void _navigateToManageCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ManageCategoriesScreen(
              initialCategories: _userCategories,
              onUpdate: _updateCategoriesAndTasks,
            ),
      ),
    );
  }

  void _navigateToCreateTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CreateTaskScreen(availableCategories: _userCategories),
      ),
    );
    if (result != null && result is Task && mounted) {
      setState(() {
        _allTasks.insert(0, result);
      });
    }
  }

  void _navigateToEditTask(Task taskToEdit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditTaskScreen(
              task: taskToEdit,
              availableCategories: _userCategories,
            ),
      ),
    );
    if (result != null && result is Task && mounted) {
      setState(() {
        final index = _allTasks.indexWhere((task) => task.id == result.id);
        if (index != -1) {
          _allTasks[index] = result;
        }
      });
    }
  }

  Widget _buildTaskTile(Task task) {
    final localizations = MaterialLocalizations.of(context);
    String trailingInfo = '';
    List<String> subtitleParts = [];

    if (task.dueDate != null) {
      subtitleParts.add(DateFormat('dd/MM/yyyy').format(task.dueDate!));
      if (task.dueTime != null) {
        trailingInfo = localizations.formatTimeOfDay(
          task.dueTime!,
          alwaysUse24HourFormat: true,
        );
      }
    }
    if (task.description.isNotEmpty) {
      subtitleParts.add(task.description);
    }
    if (task.category != null && task.category!.isNotEmpty) {
      subtitleParts.add('[${task.category}]');
    }
    final subtitleText = subtitleParts.join('\n');

    return ListTile(
      leading: Checkbox(
        value: task.isDone,
        onChanged: (v) {
          if (v != null && mounted) {
            setState(() => task.setDone(v));
          }
        },
        activeColor: Theme.of(context).primaryColor,
        visualDensity: VisualDensity.compact,
      ),
      title: Row(
        children: [
          if (task.sticker != null)
            Icon(task.sticker, size: 18, color: Theme.of(context).primaryColor),
          if (task.sticker != null) const SizedBox(width: 6),
          Expanded(
            child: Text(
              task.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w500,
                color: task.isDone ? Colors.grey[600] : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitleText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: task.isDone ? TextDecoration.lineThrough : null,
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.flag, color: task.priority.priorityColor, size: 18),
          if (trailingInfo.isNotEmpty) const SizedBox(height: 4),
          if (trailingInfo.isNotEmpty)
            Text(
              trailingInfo,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
        ],
      ),
      tileColor: task.isDone ? Colors.grey.shade100 : Colors.white,
      onTap: () => _navigateToEditTask(task),
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _activeFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      return ChoiceChip(
                        label: Text(_activeFilters[idx]),
                        selected: _selectedFilter == idx,
                        onSelected: (_) {
                          if (mounted) setState(() => _selectedFilter = idx);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: "Lọc & Tùy chọn",
                  onPressed: _onFilterIconPressed,
                  color: Colors.grey[700],
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildTaskList()),
        ],
      ),
      const CalendarScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Tìm kiếm",
            onPressed: () async {
              final Task? selectedTask = await showSearch<Task?>(
                context: context,
                delegate: _TaskSearchDelegate(List.from(_allTasks)),
              );
              if (selectedTask != null && mounted) {
                _navigateToEditTask(selectedTask);
              }
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed: _navigateToCreateTask,
                tooltip: 'Tạo công việc mới',
                child: const Icon(Icons.add),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (idx) {
          // --- !! SỬA LỖI: Thêm dấu ngoặc nhọn {} !! ---
          if (mounted) {
            setState(() {
              _currentIndex = idx;
            });
          }
          // --- Kết thúc sửa lỗi ---
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_outlined),
            activeIcon: Icon(Icons.task_alt),
            label: 'Nhiệm vụ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final groupedTasks = _getGroupedTasks();
    final sectionKeys = groupedTasks.keys.toList();
    final visibleSectionKeys =
        sectionKeys.where((key) {
          final tasksInSection = groupedTasks[key]!;
          final isCompletedSectionHidden =
              (key == 'Đã hoàn thành hôm nay' && !_showCompletedTasks);
          return tasksInSection.isNotEmpty && !isCompletedSectionHidden;
        }).toList();

    if (visibleSectionKeys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _allTasks.isEmpty
                ? 'Chưa có công việc nào.\nNhấn nút + để thêm.'
                : 'Không có công việc nào khớp với bộ lọc.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: visibleSectionKeys.length,
      itemBuilder: (context, index) {
        final sectionTitle = visibleSectionKeys[index];
        final tasksInSection = groupedTasks[sectionTitle]!;
        return ExpansionTile(
          key: PageStorageKey(sectionTitle),
          title: Text(
            '$sectionTitle (${tasksInSection.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          initiallyExpanded:
              sectionTitle == 'Hôm nay' || sectionTitle == 'Quá hạn',
          maintainState: true,
          shape: const Border(),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 0,
          ),
          childrenPadding: const EdgeInsets.only(
            bottom: 8.0,
            left: 16,
            right: 16,
          ),
          children: tasksInSection.map(_buildTaskTile).toList(),
        );
      },
    );
  }
}

class _TaskSearchDelegate extends SearchDelegate<Task?> {
  final List<Task> tasks;
  _TaskSearchDelegate(this.tasks);

  @override
  String? get searchFieldLabel => 'Tìm kiếm công việc...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Xóa',
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Quay lại',
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results =
        tasks.where((task) {
          final queryLower = query.toLowerCase();
          final titleLower = task.title.toLowerCase();
          final descriptionLower = task.description.toLowerCase();
          final categoryLower = task.category?.toLowerCase() ?? '';
          return titleLower.contains(queryLower) ||
              descriptionLower.contains(queryLower) ||
              categoryLower.contains(queryLower);
        }).toList();

    if (results.isEmpty) {
      return Center(child: Text('Không tìm thấy kết quả nào cho "$query"'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        return ListTile(
          leading: Checkbox(
            value: task.isDone,
            onChanged: null,
            visualDensity: VisualDensity.compact,
          ),
          title: Row(
            children: [
              if (task.sticker != null)
                Icon(
                  task.sticker,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              if (task.sticker != null) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    color: task.isDone ? Colors.grey[600] : null,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${task.description.isNotEmpty ? task.description : ""}${task.description.isNotEmpty && task.category != null ? "\n" : ""}${task.category != null ? "[${task.category}]" : ""}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Icon(
            Icons.flag,
            color: task.priority.priorityColor,
            size: 18,
          ),
          onTap: () {
            close(context, task);
          },
          tileColor: task.isDone ? Colors.grey.shade100 : null,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        tasks
            .where((task) {
              final queryLower = query.toLowerCase();
              final titleLower = task.title.toLowerCase();
              final categoryLower = task.category?.toLowerCase() ?? '';
              return query.isEmpty
                  ? false
                  : (titleLower.contains(queryLower) ||
                      categoryLower.contains(queryLower));
            })
            .take(8)
            .toList();

    if (query.isEmpty) {
      return const Center(
        child: Text('Nhập tiêu đề, mô tả hoặc loại công việc'),
      );
    }
    if (suggestions.isEmpty) {
      return const Center(child: Text('Không có gợi ý nào'));
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final task = suggestions[index];
        return ListTile(
          leading:
              task.sticker != null
                  ? Icon(task.sticker)
                  : const Icon(Icons.label_outline),
          title: Text(task.title),
          subtitle: Text(task.category ?? ''),
          onTap: () {
            query = task.title;
            showResults(context);
          },
        );
      },
    );
  }
}
