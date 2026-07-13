import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apppilot_app/main.dart';

void main() {
  testWidgets('adds a todo for the selected calendar day', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TodoCalendarApp());
    await tester.pumpAndSettle();

    expect(find.text('Sdelat'), findsWidgets);
    expect(find.text('На этот день задач пока нет'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Купить продукты');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('Купить продукты'), findsOneWidget);
    expect(find.text('Готово 0 из 1'), findsOneWidget);
  });
}
