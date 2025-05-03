import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/category_viewmodel.dart';

typedef TaskFormSubmitCallback = void Function(Task constructedTask);

class TaskForm extends StatefulWidget {
  final Task? initialTask;
  final TaskFormSubmitCallback onSubmit;
  final bool isParentSaving;

  const TaskForm({
    required Key key,
    this.initialTask,
    required this.onSubmit,
    required this.isParentSaving,
  }) : super(key: key);

  @override
  TaskFormState createState() => TaskFormState();
}

class TaskFormState extends State<TaskForm> {
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
  final List<PlatformFile> _newSelectedFiles = [];
  late List<String> _existingAttachmentIdentifiers;

  final List<IconData> _stickerOptions = [
    Icons.star_border, Icons.favorite_border, Icons.work_outline,
    Icons.lightbulb_outline, Icons.school_outlined, Icons.shopping_cart_outlined,
    Icons.home_outlined, Icons.flag_outlined, Icons.pets_outlined,
    Icons.fitness_center_outlined, Icons.music_note_outlined, Icons.code_outlined,
    Icons.attach_money_outlined, Icons.airplane_ticket_outlined, Icons.restaurant_outlined,
    Icons.directions_car_outlined,
  ];

  bool get _isEffectivelySaving => widget.isParentSaving;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _selectedPriority = task?.priority ?? Priority.medium;
    _selectedDate = task?.dueDate;
    _selectedTime = task?.dueTime;
    _subtasks = task?.subtasks.map((st) => st.copyWith()).toList() ?? [];
    _subtaskControllers = _subtasks.map((st) => TextEditingController(text: st.title)).toList();
    _selectedCategory = task?.category;
    _selectedSticker = task?.sticker;
    _existingAttachmentIdentifiers = task != null ? List<String>.from(task.attachments) : [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentCategories = context.read<CategoryViewModel>().categories;
        if (_selectedCategory != null && !currentCategories.contains(_selectedCategory)) {
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

  Future<void> _selectDate() async {
    if (_isEffectivelySaving) return;
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime(2101), locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
     if (_isEffectivelySaving) return;
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addSubtask() {
     if (_isEffectivelySaving) return;
    final text = _subtaskTitleController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(Subtask(title: text));
        _subtaskControllers.add(TextEditingController(text: text));
        _subtaskTitleController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _removeSubtask(int index) {
     if (_isEffectivelySaving) return;
    if (index < 0 || index >= _subtaskControllers.length) return;
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
      _subtasks.removeAt(index);
    });
  }

  void _showStickerDialog() {
     if (_isEffectivelySaving) return;
     final theme = Theme.of(context);
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Chọn Sticker'),
         contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
         content: SizedBox(
           width: double.maxFinite,
           child: GridView.builder(
             shrinkWrap: true,
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
             itemCount: _stickerOptions.length,
             itemBuilder: (ctxGrid, idx) {
               final icon = _stickerOptions[idx];
               final bool isSelected = _selectedSticker == icon;
               return InkWell(
                 onTap: () { setState(() => _selectedSticker = icon); Navigator.pop(ctx); },
                 borderRadius: BorderRadius.circular(8),
                 child: Container(
                   decoration: BoxDecoration(
                     border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor.withAlpha(150), width: isSelected ? 2.0 : 1.0),
                     borderRadius: BorderRadius.circular(8),
                     color: isSelected ? theme.primaryColor.withAlpha(30) : theme.dialogTheme.backgroundColor,
                   ),
                   child: Icon(icon, size: 28, color: theme.primaryColor),
                 ),
               );
             },
           ),
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
           if (_selectedSticker != null)
             TextButton(
               onPressed: () { setState(() => _selectedSticker = null); Navigator.pop(ctx); },
               child: Text('Xóa Sticker', style: TextStyle(color: theme.colorScheme.error)),
             ),
         ],
       ),
     );
   }

  Future<void> _pickFiles() async {
     if (_isEffectivelySaving) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null && !_newSelectedFiles.any((f) => f.path == file.path) && !_existingAttachmentIdentifiers.any((id) => id.contains(file.name))) {
              _newSelectedFiles.add(file);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chọn tệp: $e'))); }
      debugPrint('Lỗi chọn tệp: $e');
    }
  }

  void _removeNewAttachment(int index) {
     if (_isEffectivelySaving) return;
    if (index < 0 || index >= _newSelectedFiles.length) return;
    setState(() => _newSelectedFiles.removeAt(index));
  }

  void _removeExistingAttachment(int index) {
     if (_isEffectivelySaving) return;
     if (index < 0 || index >= _existingAttachmentIdentifiers.length) return;
    setState(() => _existingAttachmentIdentifiers.removeAt(index));
  }

  String _getAttachmentDisplayName(String attachmentIdentifier) {
    try {
      Uri uri = Uri.parse(attachmentIdentifier);
      if (uri.pathSegments.isNotEmpty) {
        String fullName = Uri.decodeComponent(uri.pathSegments.last);
        if (fullName.contains('%2F')) { return fullName.split('%2F').last; }
        return fullName;
      }
      return attachmentIdentifier.split('/').last;
    } catch (_) {
      if (attachmentIdentifier.length > 25) { return "...${attachmentIdentifier.substring(attachmentIdentifier.length - 20)}"; }
      return attachmentIdentifier;
    }
  }

  void submitForm() {
     if (_formKey.currentState?.validate() ?? false) {
        for (int i = 0; i < _subtasks.length; i++) {
          if (i < _subtaskControllers.length) { _subtasks[i].title = _subtaskControllers[i].text.trim(); }
        }
        _subtasks.removeWhere((st) => st.title.isEmpty);

        final List<String> newAttachmentPaths = [ for (final file in _newSelectedFiles) if (file.path != null) file.path! ];
        final List<String> finalAttachments = [ ..._existingAttachmentIdentifiers, ...newAttachmentPaths ];

        final taskToSubmit = Task(
          id: widget.initialTask?.id, title: _titleController.text.trim(),
          description: _descriptionController.text.trim(), priority: _selectedPriority,
          dueDate: _selectedDate, dueTime: _selectedTime, subtasks: _subtasks,
          category: _selectedCategory, sticker: _selectedSticker,
          attachments: finalAttachments, isDone: widget.initialTask?.isDone ?? false,
          createdAt: widget.initialTask?.createdAt, completedAtParam: widget.initialTask?.completedAt,
        );
        widget.onSubmit(taskToSubmit);
     }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final availableCategories = context.watch<CategoryViewModel>().categories;
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final defaultInputBorder = theme.inputDecorationTheme.border;
    final defaultRadius = (defaultInputBorder is OutlineInputBorder) ? defaultInputBorder.borderRadius.topLeft.x : 8.0;

    return Form(
      key: _formKey,
      child: AbsorbPointer(
        absorbing: _isEffectivelySaving,
        child: Opacity(
          opacity: _isEffectivelySaving ? 0.5 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_selectedSticker ?? Icons.sticky_note_2_outlined, size: 28, color: _selectedSticker != null ? theme.primaryColor : theme.iconTheme.color?.withAlpha(150)),
                    tooltip: 'Chọn Sticker', onPressed: _showStickerDialog, splashRadius: 24, padding: const EdgeInsets.only(right: 10),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề công việc...', labelStyle: TextStyle(fontSize: 18, color: theme.hintColor),
                        hintText: 'Nhập tiêu đề công việc', border: const UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor, width: 1.0)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả', hintText: 'Thêm mô tả chi tiết công việc...', alignLabelWithHint: true, prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 4, textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 24),
              Text('Ưu tiên:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: Priority.values.map((p) => ChoiceChip(
                      label: Text(p.priorityText), selected: _selectedPriority == p,
                      onSelected: (s) { if (s) { setState(() => _selectedPriority = p); } },
                      selectedColor: p.priorityColor.withAlpha(220), backgroundColor: theme.chipTheme.backgroundColor,
                      side: theme.chipTheme.side ?? BorderSide(color: theme.dividerColor),
                      avatar: Icon(Icons.flag, size: 16, color: _selectedPriority == p ? (isDarkMode ? Colors.black : Colors.white) : p.priorityColor),
                      labelStyle: TextStyle(fontSize: 13, color: _selectedPriority == p ? (isDarkMode ? Colors.black : Colors.white) : theme.chipTheme.labelStyle?.color),
                      showCheckmark: false,
                    )).toList(),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCategory, hint: const Text('Chưa phân loại'),
                decoration: const InputDecoration(labelText: 'Phân loại', prefixIcon: Icon(Icons.label_outline)),
                dropdownColor: theme.colorScheme.surface,
                items: availableCategories.map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 24),
              Text('Hạn chót:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: InkWell(onTap: _selectDate, borderRadius: BorderRadius.circular(defaultRadius), child: InputDecorator(decoration: const InputDecoration(labelText: 'Ngày', prefixIcon: Icon(Icons.calendar_today, size: 20), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15)), child: Text( _selectedDate == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(_selectedDate!), style: TextStyle(color: _selectedDate == null ? theme.hintColor : theme.textTheme.bodyLarge?.color))))),
                  const SizedBox(width: 16),
                  Expanded(child: InkWell(onTap: _selectTime, borderRadius: BorderRadius.circular(defaultRadius), child: InputDecorator(decoration: const InputDecoration(labelText: 'Giờ', prefixIcon: Icon(Icons.access_time, size: 20), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15)), child: Text(_selectedTime == null ? 'Chọn giờ' : localizations.formatTimeOfDay(_selectedTime!, alwaysUse24HourFormat: true), style: TextStyle(color: _selectedTime == null ? theme.hintColor : theme.textTheme.bodyLarge?.color))))),
                ],
              ),
              const SizedBox(height: 24),
              Text('Công việc con:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _subtasks.length,
                itemBuilder: (ctx, idx) {
                  if (idx < 0 || idx >= _subtaskControllers.length) { return const SizedBox.shrink(); }
                  final subtask = _subtasks[idx]; final controller = _subtaskControllers[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(value: subtask.isDone, onChanged: (v) { setState(() { if (idx < _subtasks.length) _subtasks[idx].isDone = v ?? false; }); }, visualDensity: VisualDensity.compact),
                    title: TextField(
                      controller: controller, decoration: InputDecoration(hintText: 'Công việc con...', border: InputBorder.none, isDense: true, hintStyle: TextStyle(color: theme.hintColor), contentPadding: const EdgeInsets.symmetric(vertical: 4)),
                      style: TextStyle(decoration: subtask.isDone ? TextDecoration.lineThrough : null, color: subtask.isDone ? theme.disabledColor : theme.textTheme.bodyLarge?.color),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) { if (controller.text.trim().isEmpty) { _removeSubtask(idx); } else if (idx < _subtasks.length) { _subtasks[idx].title = controller.text.trim(); } },
                      onTapOutside: (_) { FocusScope.of(context).unfocus(); if (controller.text.trim().isEmpty) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && idx < _subtasks.length) { _removeSubtask(idx); }}); } else if (idx < _subtasks.length) { _subtasks[idx].title = controller.text.trim(); }},
                    ),
                    trailing: IconButton(icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error.withAlpha(200)), onPressed: () => _removeSubtask(idx), splashRadius: 20, tooltip: 'Xóa công việc con'),
                  );
                },
              ),
              Row(
                children: [
                  Padding(padding: const EdgeInsets.only(left: 12.0, right: 12.0), child: Icon(Icons.add, color: theme.iconTheme.color?.withAlpha(150))),
                  Expanded(child: TextField(controller: _subtaskTitleController, decoration: InputDecoration(hintText: 'Thêm công việc con mới...', border: InputBorder.none, isDense: true, hintStyle: TextStyle(color: theme.hintColor), contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0)), onSubmitted: (_) => _addSubtask(), textInputAction: TextInputAction.done)),
                  IconButton(icon: Icon(Icons.add_circle_outline, color: theme.primaryColor), onPressed: _addSubtask, tooltip: 'Thêm công việc con'),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 16),
              Text('Đính kèm:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0, runSpacing: 8.0,
                children: [
                  ..._existingAttachmentIdentifiers.asMap().entries.map((entry) {
                    int idx = entry.key; String identifier = entry.value;
                    return Chip(
                      label: Text(_getAttachmentDisplayName(identifier)), avatar: Icon(Icons.cloud_done_outlined, size: 16, color: Colors.green[700]),
                      deleteIconColor: theme.colorScheme.error.withAlpha(200),
                      onDeleted: () { _removeExistingAttachment(idx); },
                    );
                  }),
                  ..._newSelectedFiles.asMap().entries.map((entry) {
                    int idx = entry.key; PlatformFile file = entry.value;
                    return Chip(
                      label: Text(file.name), avatar: Icon(Icons.attach_file, size: 16, color: theme.chipTheme.labelStyle?.color?.withAlpha(200)),
                      deleteIconColor: theme.colorScheme.error.withAlpha(200),
                      onDeleted: () { _removeNewAttachment(idx); },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(icon: const Icon(Icons.attach_file, size: 18), label: const Text('Chọn/Thêm tệp'), onPressed: _pickFiles),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}