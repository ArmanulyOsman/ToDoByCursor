import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodoCalendarApp());
}

class TodoCalendarApp extends StatelessWidget {
  const TodoCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Календарь задач',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: const TodoCalendarPage(),
    );
  }
}

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.date,
    required this.createdAt,
    this.isDone = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final DateTime createdAt;
  final bool isDone;

  TodoItem copyWith({String? title, DateTime? date, bool? isDone}) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      createdAt: createdAt,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': _dateKey(date),
      'createdAt': createdAt.toIso8601String(),
      'isDone': isDone,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: _parseDateKey(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}

class LocalTodoStore {
  static const _storageKey = 'local_calendar_todos_v1';

  Future<List<TodoItem>> loadTodos() async {
    final preferences = await SharedPreferences.getInstance();
    final rawTodos = preferences.getString(_storageKey);
    if (rawTodos == null || rawTodos.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawTodos) as List<dynamic>;
    return decoded
        .map((item) => TodoItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTodos(List<TodoItem> todos) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(todos.map((todo) => todo.toJson()).toList());
    await preferences.setString(_storageKey, encoded);
  }
}

class TodoCalendarPage extends StatefulWidget {
  const TodoCalendarPage({super.key});

  @override
  State<TodoCalendarPage> createState() => _TodoCalendarPageState();
}

class _TodoCalendarPageState extends State<TodoCalendarPage> {
  final _store = LocalTodoStore();
  final _taskController = TextEditingController();
  final List<TodoItem> _todos = [];

  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _selectedDate = today;
    _visibleMonth = DateTime(today.year, today.month);
    _loadTodos();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final savedTodos = await _store.loadTodos();
    if (!mounted) {
      return;
    }

    setState(() {
      _todos
        ..clear()
        ..addAll(savedTodos);
      _isLoading = false;
    });
  }

  Future<void> _saveTodos() => _store.saveTodos(_todos);

  Future<void> _addTodo() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) {
      return;
    }

    setState(() {
      _todos.add(
        TodoItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          date: _selectedDate,
          createdAt: DateTime.now(),
        ),
      );
      _sortTodos();
      _taskController.clear();
    });
    await _saveTodos();
  }

  Future<void> _toggleTodo(TodoItem todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      return;
    }

    setState(() {
      _todos[index] = todo.copyWith(isDone: !todo.isDone);
      _sortTodos();
    });
    await _saveTodos();
  }

  Future<void> _deleteTodo(TodoItem todo) async {
    setState(() {
      _todos.removeWhere((item) => item.id == todo.id);
    });
    await _saveTodos();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    final daysInMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final safeDay = _selectedDate.day > daysInMonth
        ? daysInMonth
        : _selectedDate.day;

    setState(() {
      _visibleMonth = nextMonth;
      _selectedDate = DateTime(nextMonth.year, nextMonth.month, safeDay);
    });
  }

  List<TodoItem> get _selectedTodos {
    final selectedKey = _dateKey(_selectedDate);
    return _todos.where((todo) => _dateKey(todo.date) == selectedKey).toList();
  }

  int _todoCountFor(DateTime date) {
    final key = _dateKey(date);
    return _todos.where((todo) => _dateKey(todo.date) == key).length;
  }

  void _sortTodos() {
    _todos.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTodos = _selectedTodos;
    final completedCount = selectedTodos.where((todo) => todo.isDone).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Календарь задач'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CalendarHeader(
              visibleMonth: _visibleMonth,
              onPreviousMonth: () => _changeMonth(-1),
              onNextMonth: () => _changeMonth(1),
            ),
            _CalendarGrid(
              visibleMonth: _visibleMonth,
              selectedDate: _selectedDate,
              todoCountFor: _todoCountFor,
              onDateSelected: _selectDate,
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _TodoListSection(
                      selectedDate: _selectedDate,
                      todos: selectedTodos,
                      completedCount: completedCount,
                      taskController: _taskController,
                      onAddTodo: _addTodo,
                      onToggleTodo: _toggleTodo,
                      onDeleteTodo: _deleteTodo,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.visibleMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime visibleMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Предыдущий месяц',
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Следующий месяц',
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.todoCountFor,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final int Function(DateTime date) todoCountFor;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final days = _visibleCalendarDays(visibleMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Row(
                children: _weekDays
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final date = days[index];
                  return _CalendarDayTile(
                    date: date,
                    isSelected: _isSameDay(date, selectedDate),
                    isCurrentMonth: date.month == visibleMonth.month,
                    isToday: _isSameDay(date, DateTime.now()),
                    todoCount: todoCountFor(date),
                    onTap: () => onDateSelected(date),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.date,
    required this.isSelected,
    required this.isCurrentMonth,
    required this.isToday,
    required this.todoCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isCurrentMonth;
  final bool isToday;
  final int todoCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? colorScheme.primary
        : isToday
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : isCurrentMonth
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: isToday && !isSelected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            if (todoCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$todoCount',
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _TodoListSection extends StatelessWidget {
  const _TodoListSection({
    required this.selectedDate,
    required this.todos,
    required this.completedCount,
    required this.taskController,
    required this.onAddTodo,
    required this.onToggleTodo,
    required this.onDeleteTodo,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final int completedCount;
  final TextEditingController taskController;
  final Future<void> Function() onAddTodo;
  final Future<void> Function(TodoItem todo) onToggleTodo;
  final Future<void> Function(TodoItem todo) onDeleteTodo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _formatSelectedDate(selectedDate),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          todos.isEmpty
              ? 'На этот день задач пока нет'
              : 'Готово $completedCount из ${todos.length}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: taskController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Новая задача',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAddTodo(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAddTodo,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (todos.isEmpty)
          const _EmptyTodosCard()
        else
          ...todos.map(
            (todo) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: todo.isDone,
                onChanged: (_) => onToggleTodo(todo),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                secondary: IconButton(
                  tooltip: 'Удалить задачу',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDeleteTodo(todo),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyTodosCard extends StatelessWidget {
  const _EmptyTodosCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Выберите дату и добавьте первую задачу.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

const _weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

const _monthNames = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _monthNamesGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

List<DateTime> _visibleCalendarDays(DateTime visibleMonth) {
  final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
  final daysBeforeMonth = firstDay.weekday - DateTime.monday;
  final firstVisibleDay = firstDay.subtract(Duration(days: daysBeforeMonth));

  return List.generate(
    42,
    (index) => _dateOnly(firstVisibleDay.add(Duration(days: index))),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime _parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String _formatSelectedDate(DateTime date) {
  return '${date.day} ${_monthNamesGenitive[date.month - 1]} ${date.year}';
}
