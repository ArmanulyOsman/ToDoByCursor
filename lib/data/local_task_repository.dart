import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';
import 'task_repository.dart';

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'app_pilot_tasks_v1';
  final SharedPreferencesAsync _preferences;
  Future<void> _mutation = Future<void>.value();

  @override
  Future<List<TaskItem>> loadTasks() {
    return _mutation.then((_) => _readTasks());
  }

  Future<List<TaskItem>> _readTasks() async {
    final storedValue = await _preferences.getString(_storageKey);
    if (storedValue == null || storedValue.isEmpty) return [];

    final decoded = jsonDecode(storedValue) as List<dynamic>;
    return decoded
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveTask(TaskItem task) {
    return _enqueue(() async {
      final tasks = await _readTasks();
      final index = tasks.indexWhere((item) => item.id == task.id);
      if (index == -1) {
        tasks.add(task);
      } else {
        tasks[index] = task;
      }
      await _saveAll(tasks);
    });
  }

  @override
  Future<void> deleteTask(String id) {
    return _enqueue(() async {
      final tasks = await _readTasks();
      tasks.removeWhere((task) => task.id == id);
      await _saveAll(tasks);
    });
  }

  Future<void> _saveAll(List<TaskItem> tasks) {
    return _preferences.setString(
      _storageKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _mutation.then((_) => operation());
    _mutation = result.catchError((Object _, StackTrace _) {});
    return result;
  }
}
