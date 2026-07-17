import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/task_controller.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.cloudSyncEnabled,
  });

  final TaskRepository repository;
  final bool cloudSyncEnabled;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TaskController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaskController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEditor([TaskItem? task]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskEditorSheet(
        controller: _controller,
        task: task,
      ),
    );
  }

  Future<void> _confirmDelete(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('«${task.title}» нельзя будет восстановить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.deleteTask(task);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('addTaskButton'),
            onPressed: _controller.isSaving ? null : () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Новая задача'),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _controller.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _Header(
                        cloudSyncEnabled: widget.cloudSyncEnabled,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ProgressCard(controller: _controller),
                    ),
                  ),
                  if (_controller.errorMessage != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ErrorBanner(
                          message: _controller.errorMessage!,
                          onRetry: _controller.load,
                          onClose: _controller.clearError,
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 20),
                    sliver: SliverToBoxAdapter(
                      child: _Filters(controller: _controller),
                    ),
                  ),
                  if (_controller.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_controller.visibleTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(filter: _controller.filter),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                      sliver: SliverList.separated(
                        itemCount: _controller.visibleTasks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = _controller.visibleTasks[index];
                          return _TaskCard(
                            key: ValueKey(task.id),
                            task: task,
                            onToggle: () => _controller.toggleTask(task),
                            onEdit: () => _openEditor(task),
                            onDelete: () => _confirmDelete(task),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cloudSyncEnabled});

  final bool cloudSyncEnabled;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    const months = [
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Мои задачи',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF777B8A),
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: cloudSyncEnabled
              ? 'Синхронизация Supabase включена'
              : 'Задачи хранятся на устройстве',
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: cloudSyncEnabled
                  ? const Color(0xFFE8F7EF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              cloudSyncEnabled
                  ? Icons.cloud_done_outlined
                  : Icons.phone_android_rounded,
              color: cloudSyncEnabled
                  ? const Color(0xFF239B63)
                  : const Color(0xFF686D7D),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final percent = (controller.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B55E7), Color(0xFF786EF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x305B55E7),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: controller.progress,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Прогресс',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  controller.tasks.isEmpty
                      ? 'Добавьте первую задачу'
                      : '${controller.completedCount} выполнено · '
                            '${controller.pendingCount} осталось',
                  style: const TextStyle(
                    color: Color(0xFFDCD9FF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (controller.isSaving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final TaskController controller;

  static const labels = {
    TaskFilter.all: 'Активные',
    TaskFilter.today: 'Сегодня',
    TaskFilter.upcoming: 'Предстоящие',
    TaskFilter.completed: 'Готово',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: TaskFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = TaskFilter.values[index];
          final selected = controller.filter == filter;
          return ChoiceChip(
            label: Text(labels[filter]!),
            selected: selected,
            onSelected: (_) => controller.setFilter(filter),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF656979),
              fontWeight: FontWeight.w600,
            ),
            selectedColor: const Color(0xFF2F3140),
            backgroundColor: Colors.white,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _priorityColor => switch (task.priority) {
    TaskPriority.low => const Color(0xFF43A979),
    TaskPriority.medium => const Color(0xFFE6A23A),
    TaskPriority.high => const Color(0xFFE75D66),
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: Key('taskCheckbox-${task.id}'),
                value: task.isCompleted,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(color: _priorityColor, width: 1.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: task.isCompleted
                              ? const Color(0xFF9A9DAB)
                              : const Color(0xFF282A35),
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8B8E9C),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (task.dueDate != null)
                            _MetaChip(
                              icon: task.isOverdue
                                  ? Icons.error_outline_rounded
                                  : Icons.calendar_today_outlined,
                              label: _dueLabel(task.dueDate!),
                              color: task.isOverdue
                                  ? const Color(0xFFE34D59)
                                  : const Color(0xFF737789),
                              background: task.isOverdue
                                  ? const Color(0xFFFFECEE)
                                  : const Color(0xFFF2F3F7),
                            ),
                          _MetaChip(
                            icon: Icons.flag_outlined,
                            label: switch (task.priority) {
                              TaskPriority.low => 'Низкий',
                              TaskPriority.medium => 'Средний',
                              TaskPriority.high => 'Высокий',
                            },
                            color: _priorityColor,
                            background: _priorityColor.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Действия',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF9295A2),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Изменить'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE34D59),
                      ),
                      title: Text('Удалить'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = date.difference(today).inDays;
    if (difference == 0) return 'Сегодня';
    if (difference == 1) return 'Завтра';
    if (difference == -1) return 'Вчера';
    return DateFormat('dd.MM.yyyy').format(date);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final completed = filter == TaskFilter.completed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFECEBFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed
                  ? Icons.check_circle_outline_rounded
                  : Icons.task_alt_rounded,
              size: 48,
              color: const Color(0xFF625BE8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            completed ? 'Пока ничего не выполнено' : 'Здесь пока пусто',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            completed
                ? 'Завершённые задачи появятся в этом разделе'
                : 'Добавьте задачу и двигайтесь к цели шаг за шагом',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF858897),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFECEE),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE34D59),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({
    super.key,
    required this.controller,
    this.task,
  });

  final TaskController controller;
  final TaskItem? task;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime? _dueDate;
  late TaskPriority _priority;
  bool _isSubmitting = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _notesController = TextEditingController(text: widget.task?.notes);
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Выберите дедлайн',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (selected != null) setState(() => _dueDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final success = _isEditing
        ? await widget.controller.updateTask(
            widget.task!,
            title: _titleController.text,
            notes: _notesController.text,
            dueDate: _dueDate,
            priority: _priority,
          )
        : await widget.controller.createTask(
            title: _titleController.text,
            notes: _notesController.text,
            dueDate: _dueDate,
            priority: _priority,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDADCE4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _isEditing ? 'Изменить задачу' : 'Новая задача',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('taskTitleField'),
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например, подготовить отчёт',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название задачи';
                  }
                  if (value.trim().length > 120) {
                    return 'Не больше 120 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('taskNotesField'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Дедлайн',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('dueDateButton'),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _dueDate == null
                            ? 'Без дедлайна'
                            : DateFormat('dd.MM.yyyy').format(_dueDate!),
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Убрать дедлайн',
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Приоритет',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(
                    value: TaskPriority.low,
                    label: Text('Низкий'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                  ButtonSegment(
                    value: TaskPriority.medium,
                    label: Text('Средний'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                  ButtonSegment(
                    value: TaskPriority.high,
                    label: Text('Высокий'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) {
                  setState(() => _priority = selection.first);
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('saveTaskButton'),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isEditing ? 'Сохранить' : 'Добавить задачу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
