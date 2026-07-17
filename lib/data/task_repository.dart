import '../models/task_item.dart';

abstract interface class TaskRepository {
  Future<List<TaskItem>> loadTasks();

  Future<void> saveTask(TaskItem task);

  Future<void> deleteTask(String id);
}

class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository([Iterable<TaskItem> initialTasks = const []])
    : _tasks = List.of(initialTasks);

  final List<TaskItem> _tasks;

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(_tasks);

  @override
  Future<void> saveTask(TaskItem task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
  }
}
