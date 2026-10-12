// Smoke-тест многостраничного приложения AIChatFlutter.
//
// Проверяет, что приложение собирается, отображает нижнюю навигацию
// с четырьмя страницами и переключается между ними.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Импорт для мокирования хранилища настроек в тесте
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_chat_flutter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Навигация: приложение отображает 4 страницы и переключается',
      (WidgetTester tester) async {
    // Мокаем хранилище настроек (иначе SharedPreferences
    // недоступен в тестовом окружении)
    SharedPreferences.setMockInitialValues({});

    // Собираем приложение
    await tester.pumpWidget(const ErrorBoundaryWidget(child: MyApp()));
    await tester.pump(const Duration(milliseconds: 100));

    // На нижней панели навигации 4 пункта
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Чат'), findsOneWidget);
    expect(find.text('Статистика'), findsOneWidget);
    expect(find.text('Расходы'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);

    // Переход на страницу настроек
    await tester.tap(find.text('Настройки'));
    await tester.pump(const Duration(milliseconds: 100));

    // Проверка элементов страницы настроек
    expect(find.text('Провайдер API'), findsOneWidget);
    expect(find.text('OpenRouter.ai'), findsOneWidget);
    expect(find.text('VseGPT.ru'), findsOneWidget);
    expect(find.text('API ключ'), findsOneWidget);

    // Переход на страницу статистики
    await tester.tap(find.text('Статистика'));
    await tester.pump(const Duration(milliseconds: 300));

    // Проверка заголовка статистики
    expect(find.text('Статистика токенов'), findsOneWidget);

    // Переход на страницу расходов
    await tester.tap(find.text('Расходы'));
    await tester.pump(const Duration(milliseconds: 300));

    // Проверка заголовка расходов
    expect(find.text('Расходы по дням'), findsOneWidget);
  });
}
