import 'package:apppilot_app/data/task_repository.dart';
import 'package:apppilot_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('пользователь добавляет и завершает задачу', (tester) async {
    await tester.pumpWidget(TodoApp(repository: InMemoryTaskRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Мои задачи'), findsOneWidget);
    expect(find.text('Здесь пока пусто'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addTaskButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('taskTitleField')),
      'Подготовить презентацию',
    );
    await tester.tap(find.byKey(const Key('saveTaskButton')));
    await tester.pumpAndSettle();

    expect(find.text('Подготовить презентацию'), findsOneWidget);
    expect(find.text('0 выполнено · 1 осталось'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('Подготовить презентацию'), findsNothing);
    expect(find.text('1 выполнено · 0 осталось'), findsOneWidget);

    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    expect(find.text('Подготовить презентацию'), findsOneWidget);
  });
}
