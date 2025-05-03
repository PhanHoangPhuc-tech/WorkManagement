import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/views/widgets/task_form.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  bool _isSaving = false;
  final GlobalKey<TaskFormState> _taskFormStateKey = GlobalKey<TaskFormState>();

  Future<void> _handleSave(Task updatedTask) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final taskViewModel = context.read<TaskViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await taskViewModel.updateTask(updatedTask);
      if (!mounted) return;
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Đã cập nhật "${updatedTask.title}"')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _isSaving ? null : () => Navigator.pop(context)),
        title: const Text('Chỉnh Sửa Công Việc'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : () => _taskFormStateKey.currentState?.submitForm(),
            tooltip: 'Lưu thay đổi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: TaskForm(
          key: _taskFormStateKey,
          initialTask: widget.task,
          onSubmit: _handleSave,
          isParentSaving: _isSaving,
        ),
      ),
    );
  }
}