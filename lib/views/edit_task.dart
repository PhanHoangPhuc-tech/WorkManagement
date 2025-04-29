import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/models/task_model.dart';
import 'dart:io';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});
  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _subtaskTitleController = TextEditingController();
  late Priority _selectedPriority;
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  late List<Subtask> _subtasks;
  late List<TextEditingController> _subtaskControllers;
  late String? _selectedCategory;
  late IconData? _selectedSticker;
  late List<PlatformFile> _selectedFiles;
  late List<String> _existingAttachmentIdentifiers;
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
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _selectedPriority = widget.task.priority;
    _selectedDate = widget.task.dueDate;
    _selectedTime = widget.task.dueTime;
    _subtasks = widget.task.subtasks.map((st) => st.copyWith()).toList();
    _subtaskControllers =
        _subtasks.map((st) => TextEditingController(text: st.title)).toList();
    _selectedCategory = widget.task.category;
    _selectedSticker = widget.task.sticker;
    _selectedFiles = [];
    _existingAttachmentIdentifiers = List<String>.from(widget.task.attachments);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentCategories = context.read<CategoryViewModel>().categories;
        if (_selectedCategory != null &&
            !currentCategories.contains(_selectedCategory)) {
          setState(() => _selectedCategory = null);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskTitleController.dispose();
    for (var controller in _subtaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addSubtask() {
    if (_subtaskTitleController.text.trim().isNotEmpty) {
      final newTitle = _subtaskTitleController.text.trim();
      setState(() {
        _subtasks.add(Subtask(title: newTitle));
        _subtaskControllers.add(TextEditingController(text: newTitle));
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
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Chọn Sticker'),
            contentPadding: const EdgeInsets.all(16),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
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
                                  ? Theme.of(ctxGrid).primaryColor
                                  : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            isSelected
                                ? Theme.of(ctxGrid).primaryColor.withAlpha(26)
                                : null,
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: Theme.of(ctxGrid).primaryColor,
                      ),
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
                  child: const Text(
                    'Xóa Sticker',
                    style: TextStyle(color: Colors.red),
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

  void _removeNewAttachment(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _removeExistingAttachment(int index) {
    setState(() => _existingAttachmentIdentifiers.removeAt(index));
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isSaving) {
        return;
      }
      setState(() {
        _isSaving = true;
      });
      final taskViewModel = context.read<TaskViewModel>();

      for (int i = 0; i < _subtasks.length; i++) {
        if (i < _subtaskControllers.length) {
          _subtasks[i].title = _subtaskControllers[i].text.trim();
        }
      }
      _subtasks.removeWhere((st) => st.title.isEmpty);

      final List<String> newAttachmentPaths = [
        for (final file in _selectedFiles)
          if (file.path != null) file.path!,
      ];
      final List<String> finalAttachments = [
        ..._existingAttachmentIdentifiers,
        ...newAttachmentPaths,
      ];

      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDate,
        setDueDateNull: _selectedDate == null,
        dueTime: _selectedTime,
        setDueTimeNull: _selectedTime == null,
        subtasks: _subtasks,
        category: _selectedCategory,
        setCategoryNull: _selectedCategory == null,
        sticker: _selectedSticker,
        setStickerNull: _selectedSticker == null,
        attachments: finalAttachments,
      );
      try {
        await taskViewModel.updateTask(updatedTask);
        if (!mounted) return;

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật "${updatedTask.title}"')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi cập nhật: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  String _getAttachmentDisplayName(String attachmentIdentifier) {
    try {
      return attachmentIdentifier.split(Platform.pathSeparator).last;
    } catch (_) {
      if (attachmentIdentifier.length > 20) {
        return "...${attachmentIdentifier.substring(attachmentIdentifier.length - 15)}";
      }
      return attachmentIdentifier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final availableCategories = context.watch<CategoryViewModel>().categories;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: const Text('Chỉnh Sửa Công Việc'),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveTask,
            tooltip: 'Lưu thay đổi',
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
                              : Colors.grey,
                    ),
                    tooltip: 'Chọn Sticker',
                    onPressed: _showStickerDialog,
                    splashRadius: 24,
                    padding: const EdgeInsets.only(right: 10),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề công việc...',
                        labelStyle: TextStyle(fontSize: 18),
                        hintText: 'Nhập tiêu đề công việc',
                        border: UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Thêm mô tả chi tiết công việc...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 24),
              const Text(
                'Ưu tiên:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
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
                            selectedColor: p.priorityColor.withAlpha(204),
                            avatar: Icon(
                              Icons.flag,
                              size: 16,
                              color:
                                  _selectedPriority == p
                                      ? Colors.white
                                      : p.priorityColor,
                            ),
                            labelStyle: TextStyle(
                              color:
                                  _selectedPriority == p
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            visualDensity: VisualDensity.compact,
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
                  border: OutlineInputBorder(),
                ),
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
              const Text(
                'Hạn chót:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                          border: OutlineInputBorder(),
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
                                _selectedDate == null ? Colors.grey[700] : null,
                          ),
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
                          prefixIcon: Icon(Icons.access_time, size: 20),
                          border: OutlineInputBorder(),
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
                                _selectedTime == null ? Colors.grey[700] : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Công việc con:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    title: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Công việc con...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      style: TextStyle(
                        decoration:
                            subtask.isDone ? TextDecoration.lineThrough : null,
                        color: subtask.isDone ? Colors.grey[600] : null,
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
                        color: Colors.red.shade300,
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
                    child: Icon(Icons.add, color: Colors.grey.shade400),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _subtaskTitleController,
                      decoration: const InputDecoration(
                        hintText: 'Thêm công việc con mới...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
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
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _addSubtask,
                    tooltip: 'Thêm công việc con',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Đính kèm:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  ..._existingAttachmentIdentifiers.asMap().entries.map((
                    entry,
                  ) {
                    int idx = entry.key;
                    String identifier = entry.value;
                    return Chip(
                      label: Text(
                        _getAttachmentDisplayName(identifier),
                        style: const TextStyle(fontSize: 12),
                      ),
                      avatar: Icon(
                        Icons.cloud_done_outlined,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      deleteIconColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      onDeleted: () => _removeExistingAttachment(idx),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }),
                  ..._selectedFiles.asMap().entries.map((entry) {
                    int idx = entry.key;
                    PlatformFile file = entry.value;
                    return Chip(
                      label: Text(
                        file.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      avatar: Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      deleteIconColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      onDeleted: () => _removeNewAttachment(idx),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Chọn/Thêm tệp'),
                onPressed: _pickFiles,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
