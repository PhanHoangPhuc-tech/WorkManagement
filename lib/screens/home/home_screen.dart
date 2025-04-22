import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Filter options
  final List<String> _filters = ['Tất cả', 'Công việc', 'Cá nhân', 'Nghỉ'];
  int _selectedFilter = 0;

  // Bottom navigation current index
  int _currentIndex = 0;

  // Sample data structure for tasks
  final Map<String, List<Task>> _sections = {
    'Hôm nay': [
      Task('Làm bài tập', '13:00 - 15:00'),
      Task('Tập thể dục', '16:00 - 17:00'),
      Task('Đi làm thêm', '18:00 - 20:30'),
    ],
    'Tương lai': [],
    'Đã hoàn thành hôm nay': [Task('Đi học', '07:00 - 11:00', done: true)],
    'Quá hạn': [],
  };

  void _onFilterIconPressed() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SizedBox(
            height: 200,
            child: Center(child: Text('Tuỳ chọn filter chi tiết ở đây')),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF005AE0),
        title: const Text(
          'TaskFlow',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: ImageIcon(
              AssetImage('assets/icons/SearchButton.png'),
              size: 24,
              color: Colors.white,
            ),
            onPressed: () {
              // TODO: Logic tìm kiếm
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar with horizontal scroll + filter icon
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      return ChoiceChip(
                        label: Text(_filters[idx]),
                        selected: _selectedFilter == idx,
                        onSelected: (_) {
                          setState(() => _selectedFilter = idx);
                          // TODO: Lọc dữ liệu theo lựa chọn
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  onPressed: _onFilterIconPressed,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Sections list
          Expanded(
            child: ListView(
              children:
                  _sections.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(entry.key),
                      initiallyExpanded: entry.key == 'Hôm nay',
                      children:
                          entry.value.isNotEmpty
                              ? entry.value.map((task) {
                                return ListTile(
                                  leading: Checkbox(
                                    value: task.done,
                                    onChanged:
                                        (v) => setState(() => task.done = v!),
                                  ),
                                  title: Text(task.title),
                                  subtitle: Text(task.time),
                                  tileColor:
                                      task.done
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                );
                              }).toList()
                              : [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Không có nhiệm vụ',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Thêm nhiệm vụ mới
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          setState(() {
            _currentIndex = idx;
          });
          // TODO: Xử lý chuyển màn hình theo idx
        },
        items: [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/icon_task.png'), size: 24),
            label: 'Nhiệm vụ',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/icon_calendar.png'),
              size: 24,
            ),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/icon_profile.png'),
              size: 24,
            ),
            label: 'Của tôi',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/icon_settings.png'),
              size: 24,
            ),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// Model đơn giản cho một Task
class Task {
  String title;
  String time;
  bool done;
  Task(this.title, this.time, {this.done = false});
}
