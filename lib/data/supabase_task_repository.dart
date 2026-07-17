import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_item.dart';
import 'task_repository.dart';

class SupabaseTaskRepository implements TaskRepository {
  const SupabaseTaskRepository({
    required SupabaseClient client,
    required String userId,
  }) : _client = client,
       _userId = userId;

  final SupabaseClient _client;
  final String _userId;

  @override
  Future<List<TaskItem>> loadTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return rows.map(TaskItem.fromJson).toList();
  }

  @override
  Future<void> saveTask(TaskItem task) async {
    await _client.from('tasks').upsert(task.toJson(userId: _userId));
  }

  @override
  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id).eq('user_id', _userId);
  }
}
