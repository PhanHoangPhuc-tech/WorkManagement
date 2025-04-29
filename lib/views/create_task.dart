import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/models/task_model.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});
  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskTitleController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<Subtask> _subtasks = [];
  final List<TextEditingController> _subtaskControllers = [];
  String? _selectedCategory;
  IconData? _selectedSticker;
  final List<PlatformFile> _selectedFiles = [];
  bool _isSaving = false;

  final List<IconData> _stickerOptions = [
    Icons.star_border,
    Icons.favorite_border,
    Icons.work_outline,
    Icons.lightbulb_outline,
    Icons.school_outlined,
    Icons.shopping_cart_outlined,
    Icons.home_outlined,
    Icons.flag_outlined,
    Icons.pets_outlined,
    Icons.fitness_center_outlined,
    Icons.music_note_outlined,
    Icons.code_outlined,
    Icons.attach_money_outlined,
    Icons.airplane_ticket_outlined,
    Icons.restaurant_outlined,
    Icons.directions_car_outlined,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskTitleController.dispose();
    for (var c in _subtaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return child!;
      },
    );
    if (p != null) {
      setState(() => _selectedDate = p);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final p = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return child!;
      },
    );
    if (p != null) {
      setState(() => _selectedTime = p);
    }
  }

  void _addSubtask() {
    if (_subtaskTitleController.text.trim().isNotEmpty) {
      final t = _subtaskTitleController.text.trim();
      setState(() {
        _subtasks.add(Subtask(title: t));
        _subtaskControllers.add(TextEditingController(text: t));
        _subtaskTitleController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _removeSubtask(int index) {
    if (index < 0 || index >= _subtaskControllers.length) return;
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
      _subtasks.removeAt(index);
    });
  }

  void _showStickerDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Chọn Sticker'),
            contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _stickerOptions.length,
                itemBuilder: (ctxGrid, idx) {
                  final icon = _stickerOptions[idx];
                  final bool isSelected = _selectedSticker == icon;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedSticker = icon);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected
                                  ? theme.primaryColor
                                  : theme.dividerColor.withAlpha(150),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            isSelected
                                ? theme.primaryColor.withAlpha(30)
                                : theme.dialogTheme.backgroundColor,
                      ),
                      child: Icon(icon, size: 28, color: theme.primaryColor),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              if (_selectedSticker != null)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedSticker = null);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Xóa Sticker',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (!_selectedFiles.any(
              (existingFile) => existingFile.path == file.path,
            )) {
              _selectedFiles.add(file);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi chọn tệp: $e')));
      }
      debugPrint('Lỗi chọn tệp: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isSaving) return;
      setState(() => _isSaving = true);

      final taskViewModel = context.read<TaskViewModel>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      for (int i = 0; i < _subtasks.length; i++) {
        if (i < _subtaskControllers.length) {
          _subtasks[i].title = _subtaskControllers[i].text.trim();
        }
      }
      _subtasks.removeWhere((st) => st.title.isEmpty);

      final List<String> attachmentPaths = [
        for (final file in _selectedFiles)
          if (file.path != null) file.path!,
      ];

      final newTask = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDate,
        dueTime: _selectedTime,
        subtasks: _subtasks,
        category: _selectedCategory,
        sticker: _selectedSticker,
        attachments: attachmentPaths,
      );
      try {
        await taskViewModel.addTask(newTask);

        if (!mounted) return;
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Đã thêm "${newTask.title}"')),
        );
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi thêm: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final availableCategories = context.watch<CategoryViewModel>().categories;
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final defaultInputBorder = theme.inputDecorationTheme.border;
    final defaultRadius =
        (defaultInputBorder is OutlineInputBorder)
            ? defaultInputBorder.borderRadius.topLeft.x
            : 8.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: const Text('Tạo Công Việc'),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                _isSaving
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                    : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveTask,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _selectedSticker ?? Icons.sticky_note_2_outlined,
                      size: 28,
                      color:
                          _selectedSticker != null
                              ? theme.primaryColor
                              : theme.iconTheme.color?.withAlpha(150),
                    ),
                    tooltip: 'Chọn Sticker',
                    onPressed: _showStickerDialog,
                    splashRadius: 24,
                    padding: const EdgeInsets.only(right: 10),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề công việc...',
                        labelStyle: TextStyle(
                          fontSize: 18,
                          color: theme.hintColor,
                        ),
                        hintText: 'Nhập tiêu đề công việc',
                        border: const UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.dividerColor,
                            width: 1.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Vui lòng nhập tiêu đề'
                                  : null,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Thêm mô tả chi tiết công việc...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 24),
              Text('Ưu tiên:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    Priority.values
                        .map(
                          (p) => ChoiceChip(
                            label: Text(p.priorityText),
                            selected: _selectedPriority == p,
                            onSelected: (s) {
                              if (s) {
                                setState(() => _selectedPriority = p);
                              }
                            },
                            selectedColor: p.priorityColor.withAlpha(220),
                            backgroundColor: theme.chipTheme.backgroundColor,
                            side:
                                theme.chipTheme.side ??
                                BorderSide(color: theme.dividerColor),
                            avatar: Icon(
                              Icons.flag,
                              size: 16,
                              color:
                                  _selectedPriority == p
                                      ? (isDarkMode
                                          ? Colors.black
                                          : Colors.white)
                                      : p.priorityColor,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color:
                                  _selectedPriority == p
                                      ? (isDarkMode
                                          ? Colors.black
                                          : Colors.white)
                                      : theme.chipTheme.labelStyle?.color,
                            ),
                            showCheckmark: false,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Chưa phân loại'),
                decoration: const InputDecoration(
                  labelText: 'Phân loại',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                dropdownColor: theme.colorScheme.surface,
                items:
                    availableCategories
                        .map(
                          (cat) => DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 24),
              Text('Hạn chót:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(defaultRadius),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày',
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Chọn ngày'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color:
                                _selectedDate == null
                                    ? theme.hintColor
                                    : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(defaultRadius),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Giờ',
                          prefixIcon: Icon(Icons.access_time, size: 20),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Chọn giờ'
                              : localizations.formatTimeOfDay(
                                _selectedTime!,
                                alwaysUse24HourFormat: true,
                              ),
                          style: TextStyle(
                            color:
                                _selectedTime == null
                                    ? theme.hintColor
                                    : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Công việc con:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subtasks.length,
                itemBuilder: (ctx, idx) {
                  if (idx < 0 || idx >= _subtaskControllers.length) {
                    return const SizedBox.shrink();
                  }
                  final subtask = _subtasks[idx];
                  final controller = _subtaskControllers[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: subtask.isDone,
                      onChanged:
                          (v) => setState(() {
                            if (idx < _subtasks.length) {
                              _subtasks[idx].isDone = v ?? false;
                            }
                          }),
                      visualDensity: VisualDensity.compact,
                    ),
                    title: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Công việc con...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(color: theme.hintColor),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      style: TextStyle(
                        decoration:
                            subtask.isDone ? TextDecoration.lineThrough : null,
                        color:
                            subtask.isDone
                                ? theme.disabledColor
                                : theme.textTheme.bodyLarge?.color,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (controller.text.trim().isEmpty) {
                          _removeSubtask(idx);
                        } else if (idx < _subtasks.length) {
                          _subtasks[idx].title = controller.text.trim();
                        }
                      },
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                        if (controller.text.trim().isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && idx < _subtasks.length) {
                              _removeSubtask(idx);
                            }
                          });
                        } else if (idx < _subtasks.length) {
                          _subtasks[idx].title = controller.text.trim();
                        }
                      },
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: theme.colorScheme.error.withAlpha(200),
                      ),
                      onPressed: () => _removeSubtask(idx),
                      splashRadius: 20,
                      tooltip: 'Xóa công việc con',
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                    child: Icon(
                      Icons.add,
                      color: theme.iconTheme.color?.withAlpha(150),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _subtaskTitleController,
                      decoration: InputDecoration(
                        hintText: 'Thêm công việc con mới...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(color: theme.hintColor),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 0,
                        ),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: theme.primaryColor,
                    ),
                    onPressed: _addSubtask,
                    tooltip: 'Thêm công việc con',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 16),
              Text('Đính kèm:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_selectedFiles.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children:
                      _selectedFiles.asMap().entries.map((entry) {
                        int idx = entry.key;
                        PlatformFile file = entry.value;
                        return Chip(
                          label: Text(file.name),
                          avatar: Icon(
                            Icons.insert_drive_file_outlined,
                            size: 16,
                            color: theme.chipTheme.labelStyle?.color?.withAlpha(
                              200,
                            ),
                          ),
                          deleteIconColor: theme.colorScheme.error.withAlpha(
                            200,
                          ),
                          onDeleted: () => _removeAttachment(idx),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Chọn tệp'),
                onPressed: _pickFiles,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
