// Import JSON library
import 'dart:convert';
// Import HTTP client
import 'package:http/http.dart' as http;
// Import Flutter core classes
import 'package:flutter/foundation.dart';
// Import configuration service (runtime provider/api-key settings)
import '../services/config_service.dart';

// Класс клиента для работы с API OpenRouter/VseGPT
class OpenRouterClient {
  // Статические заголовки HTTP запросов
  final Map<String, String> headers;

  // Единственный экземпляр класса (Singleton)
  static final OpenRouterClient _instance = OpenRouterClient._internal();

  // Фабричный метод для получения экземпляра
  factory OpenRouterClient() {
    return _instance;
  }

  // Сервис конфигурации (провайдер, ключ, параметры генерации)
  final ConfigService _config = ConfigService();

  // Приватный конструктор для реализации Singleton
  OpenRouterClient._internal()
      : headers = {
          'Content-Type': 'application/json', // Указание типа контента
          'X-Title': 'AI Chat Flutter', // Название приложения
        } {
    // Инициализация клиента
    _initializeClient();
  }

  // API ключ для авторизации (берётся из конфигурации в рантайме)
  String? get apiKey => _config.apiKey;

  // Базовый URL API (определяется выбранным провайдером)
  String get baseUrl => _config.baseUrl;

  // Признак провайдера VseGPT (единый источник правды — ConfigService)
  bool get isVsetgpt => _config.isVseGpt;

  // Признак наличия API ключа
  bool get hasApiKey => _config.hasApiKey;

  // Метод инициализации клиента
  void _initializeClient() {
    if (kDebugMode) {
      debugPrint('Initializing OpenRouterClient...');
      debugPrint('Base URL: $baseUrl');
      debugPrint('API key present: ${_config.hasApiKey}');
    }
  }

  // Формирование заголовков запроса с учётом текущего API ключа
  Map<String, String> get _headers => {
        ...headers,
        'Authorization': 'Bearer ${_config.apiKey}', // Заголовок авторизации
      };

  // Метод получения списка доступных моделей
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      // Выполнение GET запроса для получения моделей (с таймаутом)
      final response = await http
          .get(
            Uri.parse('$baseUrl/models'),
            headers: _headers,
          )
          .timeout(_listTimeout);

      if (kDebugMode) {
        debugPrint('Models response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о моделях (байты декодируются как UTF-8,
        // чтобы кириллические имена моделей отображались корректно)
        final modelsData = json.decode(utf8.decode(response.bodyBytes));
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List)
              .map((model) => {
                    'id': model['id'] as String,
                    // Имя модели используется как есть — API уже
                    // отдаёт его в правильной кодировке UTF-8
                    'name': (model['name'] as String?) ?? model['id'],
                    'pricing': {
                      'prompt': model['pricing']?['prompt'] ?? '0',
                      'completion': model['pricing']?['completion'] ?? '0',
                    },
                    'context_length': (model['context_length'] ??
                            model['top_provider']?['context_length'] ??
                            0)
                        .toString(),
                  })
              .toList();
        }
        throw Exception('Invalid API response format');
      } else {
        // Возвращение моделей по умолчанию, если API недоступен
        return _defaultModels();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting models: $e');
      }
      // Возвращение моделей по умолчанию в случае ошибки
      return _defaultModels();
    }
  }

  // Модели по умолчанию (используются, если список не удалось получить)
  //
  // ВАЖНО: каждая модель должна содержать 'pricing' и 'context_length',
  // иначе UI (dropdown с ценами) упадёт при попытке распарсить null.
  List<Map<String, dynamic>> _defaultModels() => [
        {
          'id': 'deepseek-coder',
          'name': 'DeepSeek',
          'pricing': {'prompt': '0', 'completion': '0'},
          'context_length': '0',
        },
        {
          'id': 'claude-3-sonnet',
          'name': 'Claude 3.5 Sonnet',
          'pricing': {'prompt': '0', 'completion': '0'},
          'context_length': '0',
        },
        {
          'id': 'gpt-3.5-turbo',
          'name': 'GPT-3.5 Turbo',
          'pricing': {'prompt': '0', 'completion': '0'},
          'context_length': '0',
        },
      ];

  // Таймауты HTTP-запросов (защита от вечного ожидания)
  static const Duration _listTimeout = Duration(seconds: 30);
  static const Duration _chatTimeout = Duration(seconds: 120);

  // Максимальное количество последних сообщений диалога,
  // передаваемых в API как контекст (защита от переполнения контекста)
  static const int _maxContextMessages = 20;

  // Метод отправки сообщения через API
  //
  // В [history] передаётся контекст предыдущих реплик диалога
  // (в хронологическом порядке, уже без текущего сообщения).
  Future<Map<String, dynamic>> sendMessage(
    String message,
    String model, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      // Ограничение контекста последними сообщениями
      final context = history.length > _maxContextMessages
          ? history.sublist(history.length - _maxContextMessages)
          : history;

      // Подготовка данных для отправки:
      // история диалога + текущее сообщение пользователя
      final data = {
        'model': model, // Модель для генерации ответа
        'messages': [
          ...context, // Предыдущие реплики (контекст для модели)
          {'role': 'user', 'content': message} // Сообщение пользователя
        ],
        'max_tokens': _config.maxTokens, // Максимальное количество токенов
        'temperature': _config.temperature, // Температура генерации
        'stream': false, // Отключение потоковой передачи
      };

      if (kDebugMode) {
        debugPrint('Sending message to API: ${json.encode(data)}');
      }

      // Выполнение POST запроса с таймаутом
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_chatTimeout);

      if (kDebugMode) {
        debugPrint('Message response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        // Успешный ответ
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        // Обработка ошибки
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'error': errorData['error']?['message'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending message: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Метод получения текущего баланса
  //
  // Возвращает отформатированную сумму или null при ошибке
  // (null позволяет сохранить прежний баланс вместо отображения 'Error').
  Future<String?> getBalance() async {
    // Отсутствие ключа — сразу нулевой баланс (без запроса к API)
    if (!_config.hasApiKey) {
      return isVsetgpt ? '0.00₽' : r'$0.00';
    }

    try {
      // Выполнение GET запроса для получения баланса (с таймаутом)
      final response = await http
          .get(
            Uri.parse(isVsetgpt ? '$baseUrl/balance' : '$baseUrl/credits'),
            headers: _headers,
          )
          .timeout(_listTimeout);

      if (kDebugMode) {
        debugPrint('Balance response status: ${response.statusCode}');
      }

      // Успешный ответ — возвращаем рассчитанную сумму
      if (response.statusCode == 200) {
        // Парсинг данных о балансе
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data != null && data['data'] != null) {
          if (isVsetgpt) {
            final credits =
                double.tryParse(data['data']['credits'].toString()) ??
                    0.0; // Доступно средств
            return '${credits.toStringAsFixed(2)}₽'; // Расчет доступного баланса
          } else {
            final credits = data['data']['total_credits'] ?? 0; // Общие кредиты
            final usage =
                data['data']['total_usage'] ?? 0; // Использованные кредиты
            return '\$${(credits - usage).toStringAsFixed(2)}'; // Расчет доступного баланса
          }
        }
      }
      // Не-200 или неожиданный формат — не обновляем баланс
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting balance: $e');
      }
      // Ошибка (сеть/таймаут) — прежний баланс сохраняется
      return null;
    }
  }

  // Метод форматирования цен
  String formatPricing(double pricing) {
    try {
      if (isVsetgpt) {
        return '${pricing.toStringAsFixed(3)}₽/K';
      } else {
        return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error formatting pricing: $e');
      }
      return '0.00';
    }
  }
}

