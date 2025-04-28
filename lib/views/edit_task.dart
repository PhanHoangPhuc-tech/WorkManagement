import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/models/task_model.dart';

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
  late List<String> _attachmentNames;
  bool _isSaving = false;
  // Lỗi unused_field sẽ được sửa khi khôi phục hàm _showStickerDialog
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
    _attachmentNames = List<String>.from(widget.task.attachments);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentCategories = context.read<CategoryViewModel>().categories;
      if (_selectedCategory != null &&
          !currentCategories.contains(_selectedCategory)) {
        setState(() => _selectedCategory = null);
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
    // --- Sửa LỖI 4 (Line 75): Thêm super.dispose() ---
    super.dispose();
  }

  // --- Khôi phục đầy đủ các hàm UI ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    // --- Sửa LỖI 1 (Line 82): Dùng đúng biến picked ---
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    // --- Sửa LỖI 2 (Line 87): Dùng đúng biến picked ---
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addSubtask() {
    if (_subtaskTitleController.text.isNotEmpty) {
      final newTitle = _subtaskTitleController.text;
      setState(() {
        _subtasks.add(Subtask(title: newTitle));
        _subtaskControllers.add(TextEditingController(text: newTitle));
        _subtaskTitleController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
      _subtasks.removeAt(index);
    });
  }

  void _showStickerDialog() {
    // Khôi phục nội dung hàm để sử dụng _stickerOptions
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Chọn Sticker'),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount:
                    _stickerOptions.length, // Sử dụng _stickerOptions ở đây
                itemBuilder: (ctxGrid, idx) {
                  final icon = _stickerOptions[idx];
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedSticker = icon);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 30,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đính kèm chưa cài đặt.')),
    );
  }

  void _removeAttachment(int index) {
    setState(() => _attachmentNames.removeAt(index));
  }
  // --- Hết phần khôi phục hàm UI ---

  Future<void> _saveTask() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isSaving) {
        return;
      }
      setState(() {
        _isSaving = true;
      });
      final taskViewModel = context.read<TaskViewModel>();

      // --- Sửa LỖI 5 (Line 121): Thêm dấu ngoặc nhọn cho for ---
      for (int i = 0; i < _subtasks.length; i++) {
        _subtasks[i].title = _subtaskControllers[i].text.trim();
      }
      _subtasks.removeWhere((st) => st.title.isEmpty);

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
        attachments:
            _attachmentNames.isNotEmpty ? List.from(_attachmentNames) : [],
      );
      try {
        await taskViewModel.updateTask(updatedTask);
        if (!mounted) return;
        // --- Sửa LỖI 6 (Line 149): Thêm dấu ngoặc nhọn cho if ---
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

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final availableCategories = context.watch<CategoryViewModel>().categories;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005AE0),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: const Text('Chỉnh sửa công việc'),
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
                    : const Icon(Icons.check, color: Colors.white),
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
                children: [
                  if (_selectedSticker != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        _selectedSticker,
                        size: 30,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề công việc...',
                      ),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Vui lòng nhập tiêu đề'
                                  : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sticky_note_2_outlined),
                    tooltip: 'Chọn Sticker',
                    onPressed: _showStickerDialog,
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết công việc...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              const Text(
                'Ưu tiên:',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                              horizontal: 10,
                              vertical: 6,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Chọn phân loại'),
                decoration: const InputDecoration(
                  labelText: 'Phân loại',
                  prefixIcon: Icon(Icons.label_outline),
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
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Chưa chọn ngày'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color:
                                _selectedDate == null ? Colors.grey[600] : null,
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
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Chưa chọn giờ'
                              : localizations.formatTimeOfDay(
                                _selectedTime!,
                                alwaysUse24HourFormat: true,
                              ),
                          style: TextStyle(
                            color:
                                _selectedTime == null ? Colors.grey[600] : null,
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subtasks.length,
                itemBuilder: (ctx, idx) {
                  final subtask = _subtasks[idx];
                  final controller = _subtaskControllers[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: subtask.isDone,
                      onChanged:
                          (v) => setState(() => subtask.isDone = v ?? false),
                      visualDensity: VisualDensity.compact,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    title: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Tiêu đề công việc con...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      style: TextStyle(
                        decoration:
                            subtask.isDone ? TextDecoration.lineThrough : null,
                        color: subtask.isDone ? Colors.grey[600] : null,
                      ),
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
                  const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _subtaskTitleController,
                      decoration: const InputDecoration(
                        hintText: 'Thêm công việc con mới...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _addSubtask(),
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    _attachmentNames
                        .asMap()
                        .entries
                        .map(
                          (entry) => Chip(
                            label: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIconColor: Colors.red[400],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            onDeleted: () => _removeAttachment(entry.key),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
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
