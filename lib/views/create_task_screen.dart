import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum Priority { low, medium, high }

extension PriorityExtension on Priority {
  String get priorityText {
    switch (this) {
      case Priority.low:
        return 'Thấp';
      case Priority.medium:
        return 'Trung Bình';
      case Priority.high:
        return 'Cao';
    }
  }

  Color get priorityColor {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }
}

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});
  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Priority? _selectedPriority;
  final List<String> _subtasks = [];
  final _subtaskController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (p != null) {
      setState(() => _selectedDate = p);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final p = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (p != null) {
      setState(() => _selectedTime = p);
    }
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(_subtaskController.text);
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005AE0),
        title: const Text(
          'Tạo Công Việc',
          style: TextStyle(color: Colors.white),  // Đổi màu chữ thành trắng
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              // Thêm logic để lưu công việc tại đây
            },
            tooltip: 'Lưu công việc',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề công việc
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề công việc...',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),

              // Mô tả công việc
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết công việc...',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Ưu tiên (không mặc định chọn)
              const Text(
                'Ưu tiên:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ChoiceChip(
                    label: const Text('Thấp'),
                    selected: _selectedPriority == Priority.low,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedPriority =
                            selected ? Priority.low : null;
                      });
                    },
                    selectedColor: Colors.green.withAlpha(204),
                  ),
                  ChoiceChip(
                    label: const Text('Trung Bình'),
                    selected: _selectedPriority == Priority.medium,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedPriority =
                            selected ? Priority.medium : null;
                      });
                    },
                    selectedColor: Colors.orange.withAlpha(204),
                  ),
                  ChoiceChip(
                    label: const Text('Cao'),
                    selected: _selectedPriority == Priority.high,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedPriority =
                            selected ? Priority.high : null;
                      });
                    },
                    selectedColor: Colors.red.withAlpha(204),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Phân loại
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Chọn phân loại'),
                decoration: const InputDecoration(
                  labelText: 'Phân loại',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Work',
                  'Personal',
                  'Shopping',
                ]
                    .map((cat) => DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 24),

              // Hạn chót: Ngày và Giờ
              const Text(
                'Hạn chót:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Chưa chọn ngày'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Giờ',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Chưa chọn giờ'
                              : localizations.formatTimeOfDay(
                                  _selectedTime!,
                                  alwaysUse24HourFormat: true,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Công việc con
              const Text(
                'Công việc con:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: _subtasks.map((subtask) {
                  return ListTile(
                    title: Text(subtask),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removeSubtask(_subtasks.indexOf(subtask)),
                    ),
                  );
                }).toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: const InputDecoration(
                        hintText: 'Thêm công việc con mới...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.blue,
                    ),
                    onPressed: _addSubtask,
                    tooltip: 'Thêm công việc con',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Đính kèm
              const Text(
                'Đính kèm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Chọn tệp'),
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
