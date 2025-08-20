import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service = TaskService();
  List<Task> _all = [];
  String _filter = '';
  bool _busy = true;

  List<Task> get tasks => _filter.isEmpty
      ? _all
      : _all.where((t) => t.title.toLowerCase().contains(_filter)).toList();

  bool get isBusy => _busy;

  Future<void> fetchTasks() async {
    _busy = true;
    notifyListeners();
    try {
      _all = await _service.getTasksOnce();
    } catch (e) {
      print("Error fetching tasks: $e");
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void setFilter(String query) {
    _filter = query.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> saveTask(Task t) async {
    if (t.id.isEmpty) {
      await _service.addTask(t);
    } else {
      await _service.updateTask(t);
    }
    await fetchTasks();
  }

  Future<void> deleteTask(String id) async {
    await _service.deleteTask(id);
    await fetchTasks();
  }
}

