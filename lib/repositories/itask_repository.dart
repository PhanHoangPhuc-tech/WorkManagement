import 'package:workmanagement/models/task_model.dart';

abstract class ITaskRepository {
  Future<List<Task>> getAllTasks();
  Future<Task> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Future<void> updateTasksCategory(String oldCategory, String? newCategory);
}
