// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт пакета для работы с .env файлами
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Импорт пакета для локализации приложения
import 'package:flutter_localizations/flutter_localizations.dart';
// Импорт пакета для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт кастомного провайдера для управления состоянием чата
import 'providers/chat_provider.dart';
// Импорт сервиса конфигурации (провайдер, ключ, параметры)
import 'services/config_service.dart';
// Импорт экранов приложения
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spending_screen.dart';
import 'screens/stats_screen.dart';

// Виджет для обработки и отлова ошибок в приложении
class ErrorBoundaryWidget extends StatelessWidget {
  // Дочерний виджет, который будет обернут в обработчик ошибок
  final Widget child;

  // Конструктор с обязательным параметром child
  const ErrorBoundaryWidget({super.key, required this.child});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем Builder для создания нового контекста
    return Builder(
      // Функция построения виджета с обработкой ошибок
      builder: (context) {
        // Пытаемся построить дочерний виджет
        try {
          // Возвращаем дочерний виджет, если ошибок нет
          return child;
          // Ловим и обрабатываем ошибки
        } catch (error, stackTrace) {
          // Логируем ошибку в консоль
          debugPrint('Error in ErrorBoundaryWidget: $error');
          // Логируем стек вызовов для отладки
          debugPrint('Stack trace: $stackTrace');
          // Возвращаем MaterialApp с экраном ошибки
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// Основная точка входа в приложение
void main() async {
  try {
    // Инициализация Flutter биндингов
    WidgetsFlutterBinding.ensureInitialized();

    // Настройка обработки ошибок Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };

    // Загрузка переменных окружения из .env файла.
    // Ошибка не критична: провайдер и ключ можно ввести
    // на странице «Настройки» во время работы приложения.
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('Environment loaded');
    } catch (e) {
      debugPrint('Warning: .env not loaded: $e');
    }

    // Инициализация конфигурации (провайдер, ключ, параметры генерации)
    await ConfigService().init();

    // Запуск приложения с обработчиком ошибок
    runApp(const ErrorBoundaryWidget(child: MyApp()));
  } catch (e, stackTrace) {
    // Логирование ошибки запуска приложения
    debugPrint('Error starting app: $e');
    debugPrint('Stack trace: $stackTrace');
    // Запуск приложения с экраном ошибки
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error starting app: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Основной виджет приложения
class MyApp extends StatelessWidget {
  // Конструктор с ключом
  const MyApp({super.key});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем ChangeNotifierProvider для управления состоянием
    return ChangeNotifierProvider<ConfigService>.value(
      // Передаём существующий экземпляр конфигурации (Singleton)
      value: ConfigService(),
      child: ChangeNotifierProvider(
        // Функция создания провайдера чата
        create: (_) {
          try {
            // Создаем экземпляр ChatProvider
            return ChatProvider();
            // Логирование ошибки создания провайдера
          } catch (e, stackTrace) {
            debugPrint('Error creating ChatProvider: $e');
            debugPrint('Stack trace: $stackTrace');
            // Повторный выброс исключения
            rethrow;
          }
        },
        // Основной виджет MaterialApp
        child: MaterialApp(
          // Настройка поведения прокрутки
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: ScrollBehavior(),
              child: child!,
            );
          },
          // Заголовок приложения
          title: 'AI Chat',
          // Скрытие баннера debug
          debugShowCheckedModeBanner: false,
          // Установка локали по умолчанию (русский)
          locale: const Locale('ru', 'RU'),
          // Поддерживаемые локали
          supportedLocales: const [
            Locale('ru', 'RU'), // Русский
            Locale('en', 'US'), // Английский (США)
          ],
          // Делегаты для локализации
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate, // Локализация Material виджетов
            GlobalWidgetsLocalizations.delegate, // Локализация базовых виджетов
            GlobalCupertinoLocalizations
                .delegate, // Локализация Cupertino виджетов
          ],
          // Настройка темы приложения
          theme: ThemeData(
            // Цветовая схема на основе синего цвета
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, // Основной цвет
              brightness: Brightness.dark, // Темная тема
            ),
            // Использование Material 3
            useMaterial3: true,
            // Цвет фона Scaffold
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            // Настройка темы AppBar
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF262626), // Цвет фона
              foregroundColor: Colors.white, // Цвет текста
            ),
            // Настройка темы диалогов
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF333333), // Цвет фона
              titleTextStyle: TextStyle(
                color: Colors.white, // Цвет заголовка
                fontSize: 20, // Размер шрифта
                fontWeight: FontWeight.bold, // Жирный шрифт
                fontFamily: 'Roboto', // Шрифт
              ),
              contentTextStyle: TextStyle(
                color: Colors.white70, // Цвет текста
                fontSize: 16, // Размер шрифта
                fontFamily: 'Roboto', // Шрифт
              ),
            ),
            // Настройка текстовой темы
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 16, // Размер шрифта
                color: Colors.white, // Цвет текста
              ),
              bodyMedium: TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 14, // Размер шрифта
                color: Colors.white, // Цвет текста
              ),
            ),
            // Настройка темы кнопок
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // Цвет текста
                textStyle: const TextStyle(
                  fontFamily: 'Roboto', // Шрифт
                  fontSize: 14, // Размер шрифта
                ),
              ),
            ),
            // Настройка темы текстовых кнопок
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // Цвет текста
                textStyle: const TextStyle(
                  fontFamily: 'Roboto', // Шрифт
                  fontSize: 14, // Размер шрифта
                ),
              ),
            ),
          ),
          // Главная оболочка приложения с навигацией
          home: const AppShell(),
        ),
      ),
    );
  }
}

// Оболочка приложения с многостраничной навигацией
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Индекс выбранной страницы
  int _selectedIndex = 0;

  // Список страниц приложения
  static const List<Widget> _pages = <Widget>[
    ChatScreen(), // 0. Главная страница — чат
    StatsScreen(), // 1. Статистика использования токенов
    SpendingScreen(), // 2. График расходов по дням
    SettingsScreen(), // 3. Настройки провайдера и ключей
  ];

  // Метод переключения страницы
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack сохраняет состояние всех страниц,
      // поэтому чат не пересоздаётся при переключении
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Нижняя панель навигации
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF262626),
        indicatorColor: const Color(0xFF1A3A5C),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF1A73E8)),
            label: 'Чат',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF1A73E8)),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up, color: Colors.white54),
            selectedIcon: Icon(Icons.trending_up, color: Color(0xFF1A73E8)),
            label: 'Расходы',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF1A73E8)),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}

