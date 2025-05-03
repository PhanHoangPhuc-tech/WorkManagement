import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanagement/models/task_model.dart';
import 'package:workmanagement/viewmodels/task_viewmodel.dart';
import 'package:workmanagement/views/widgets/task_form.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  bool _isSaving = false;
  final GlobalKey<TaskFormState> _taskFormStateKey = GlobalKey<TaskFormState>();

  Future<void> _handleSave(Task constructedTask) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final taskViewModel = context.read<TaskViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await taskViewModel.addTask(constructedTask);
      if (!mounted) return;
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Đã thêm "${constructedTask.title}"')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm: ${e.toString().replaceFirst('Exception: ', '')}'),
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
        title: const Text('Tạo Công Việc'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : () => _taskFormStateKey.currentState?.submitForm(),
            tooltip: 'Lưu công việc',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: TaskForm(
          key: _taskFormStateKey,
          onSubmit: _handleSave,
          isParentSaving: _isSaving,
        ),
      ),
    );
  }
}