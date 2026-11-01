import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  final Box _box;

  TaskProvider({required Box box}) : _box = box;

  // ============ GETTER ============
  List<Task> get tasks => _box.values.whereType<Task>().toList();

  Task? get nearestTask {
    final pendingTasks = tasks.where((t) => t.status != 'Selesai').toList();
    if (pendingTasks.isEmpty) return null;
    pendingTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    return pendingTasks.first;
  }

  // ============ CRUD ============
  void addTask(Task task) {
    _box.put(task.id, task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    _box.put(updatedTask.id, updatedTask);
    notifyListeners();
  }

  void deleteTask(String id) {
    _box.delete(id);
    notifyListeners();
  }
}
