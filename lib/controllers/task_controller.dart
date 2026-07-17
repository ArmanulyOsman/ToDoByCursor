import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/task_repository.dart';
import '../models/task_item.dart';

enum TaskFilter { all, today, upcoming, completed }

class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final TaskRepository _repository;
  final List<TaskItem> _tasks = [];

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  TaskFilter filter = TaskFilter.all;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  List<TaskItem> get visibleTasks {
    final today = _dateOnly(DateTime.now());
    final filtered = _tasks.where((task) {
      return switch (filter) {
        TaskFilter.all => !task.isCompleted,
        TaskFilter.today =>
          !task.isCompleted &&
              task.dueDate != null &&
              _dateOnly(task.dueDate!) == today,
        TaskFilter.upcoming =>
          !task.isCompleted &&
              task.dueDate != null &&
              _dateOnly(task.dueDate!).isAfter(today),
        TaskFilter.completed => task.isCompleted,
      };
    }).toList();

    filtered.sort((first, second) {
      if (first.dueDate == null && second.dueDate != null) return 1;
      if (first.dueDate != null && second.dueDate == null) return -1;
      final dueComparison = first.dueDate?.compareTo(second.dueDate!) ?? 0;
      if (dueComparison != 0) return dueComparison;
      return second.priority.index.compareTo(first.priority.index);
    });
    return filtered;
  }

  int get completedCount => _tasks.where((task) => task.isCompleted).length;

  int get pendingCount => _tasks.length - completedCount;

  double get progress => _tasks.isEmpty ? 0 : completedCount / _tasks.length;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final loadedTasks = await _repository.loadTasks();
      _tasks
        ..clear()
        ..addAll(loadedTasks);
    } catch (_) {
      errorMessage = 'Не удалось загрузить задачи';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(TaskFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  Future<bool> createTask({
    required String title,
    required String notes,
    required DateTime? dueDate,
    required TaskPriority priority,
  }) {
    final task = TaskItem(
      id: const Uuid().v4(),
      title: title.trim(),
      notes: notes.trim(),
      dueDate: dueDate,
      priority: priority,
      createdAt: DateTime.now(),
    );
    return _persist(task);
  }

  Future<bool> updateTask(
    TaskItem task, {
    required String title,
    required String notes,
    required DateTime? dueDate,
    required TaskPriority priority,
  }) {
    return _persist(
      task.copyWith(
        title: title.trim(),
        notes: notes.trim(),
        dueDate: dueDate,
        clearDueDate: dueDate == null,
        priority: priority,
      ),
    );
  }

  Future<void> toggleTask(TaskItem task) async {
    await _persist(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<bool> deleteTask(TaskItem task) async {
    final oldIndex = _tasks.indexWhere((item) => item.id == task.id);
    if (oldIndex == -1) return false;
    _tasks.removeAt(oldIndex);
    notifyListeners();

    try {
      await _repository.deleteTask(task.id);
      return true;
    } catch (_) {
      if (!_tasks.any((item) => item.id == task.id)) {
        final restoreIndex = oldIndex > _tasks.length
            ? _tasks.length
            : oldIndex;
        _tasks.insert(restoreIndex, task);
      }
      errorMessage = 'Не удалось удалить задачу';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _persist(TaskItem task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    final previous = index == -1 ? null : _tasks[index];
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveTask(task);
      return true;
    } catch (_) {
      if (previous == null) {
        _tasks.removeWhere((item) => item.id == task.id);
      } else {
        final currentIndex = _tasks.indexWhere((item) => item.id == task.id);
        if (currentIndex == -1) {
          _tasks.add(previous);
        } else {
          _tasks[currentIndex] = previous;
        }
      }
      errorMessage = 'Не удалось сохранить задачу';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
