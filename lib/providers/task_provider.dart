import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service = TaskService();
  List<Task> _all = [];
  String _filter = '';
  bool _busy = true;
  String? _errorMessage;
  bool _publicOnly = false;

  List<Task> get tasks {
    Iterable<Task> items = _all;
    if (_filter.isNotEmpty) {
      final q = _filter;
      items = items.where((t) =>
          t.title.toLowerCase().contains(q) || (t.description ?? '').toLowerCase().contains(q));
    }
    if (_publicOnly) {
      items = items.where((t) => t.publicVisible == true);
    }
    return items.toList();
  }

  bool get isBusy => _busy;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  bool get publicOnly => _publicOnly;

  Future<void> fetchTasks() async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _all = await _service.getTasksOnce();
    } catch (e) {
      _errorMessage = e.toString();
      // ignore: avoid_print
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

  void setPublicOnly(bool value) {
    _publicOnly = value;
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
