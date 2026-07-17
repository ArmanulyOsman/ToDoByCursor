enum TaskPriority { low, medium, high }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime? dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return dueDate!.isBefore(startOfToday);
  }

  TaskItem copyWith({
    String? title,
    String? notes,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      dueDate: json['due_date'] == null
          ? null
          : _parseDueDate(json['due_date'] as String),
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson({String? userId}) {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'due_date': dueDate == null ? null : _formatDueDate(dueDate!),
      'priority': priority.name,
      'is_completed': isCompleted,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (userId != null) 'user_id': userId,
    };
  }

  static DateTime _parseDueDate(String value) {
    final parsed = DateTime.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _formatDueDate(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';
  }
}
