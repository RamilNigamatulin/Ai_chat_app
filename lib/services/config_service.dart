// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';
// Импорт пакета для работы с .env файлами (значения по умолчанию)
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Импорт пакета для сохранения настроек пользователя
import 'package:shared_preferences/shared_preferences.dart';

// Тип провайдера API
enum ApiProviderType {
  // Провайдер OpenRouter.ai (баланс в долларах)
  openrouter('OpenRouter', 'https://openrouter.ai/api/v1'),
  // Провайдер VseGPT.ru (баланс в рублях)
  vsetgpt('VseGPT', 'https://api.vsetgpt.ru/v1');

  // Конструктор с названием и базовым URL провайдера
  const ApiProviderType(this.title, this.baseUrl);

  // Человекочитаемое название провайдера
  final String title;

  // Базовый URL API провайдера
  final String baseUrl;
}

// Сервис конфигурации приложения (Singleton + ChangeNotifier).
//
// Хранит выбранный провайдер, API ключ и параметры генерации.
// Значения по умолчанию берутся из .env файла, а изменения пользователя
// сохраняются в SharedPreferences и доступны во время работы приложения
// (без перезапуска).
class ConfigService extends ChangeNotifier {
  // Приватный конструктор для реализации Singleton
  ConfigService._internal();

  // Единственный экземпляр класса (Singleton)
  static final ConfigService instance = ConfigService._internal();

  // Фабричный метод для получения экземпляра
  factory ConfigService() => instance;

  // Ключи хранилища настроек
  static const String _kProvider = 'provider';
  static const String _kApiKey = 'api_key';
  static const String _kMaxTokens = 'max_tokens';
  static const String _kTemperature = 'temperature';

  // Экземпляр хранилища настроек
  SharedPreferences? _prefs;

  // Текущий провайдер API
  ApiProviderType _provider = ApiProviderType.openrouter;

  // API ключ пользователя
  String _apiKey = '';

  // Максимальное количество токенов для ответа
  int _maxTokens = 1000;

  // Температура генерации
  double _temperature = 0.7;

  // Флаг успешной инициализации
  bool _initialized = false;

  // Геттеры доступа к настройкам
  bool get initialized => _initialized;
  ApiProviderType get provider => _provider;
  String get apiKey => _apiKey;
  int get maxTokens => _maxTokens;
  double get temperature => _temperature;

  // Базовый URL текущего провайдера
  String get baseUrl => _provider.baseUrl;

  // Признак провайдера VseGPT (определяет валюту и формат цен)
  bool get isVseGpt => _provider == ApiProviderType.vsetgpt;

  // Знак валюты текущего провайдера
  String get currencySymbol => isVseGpt ? '₽' : r'$';

  // Признак наличия реального API ключа
  bool get hasApiKey =>
      _apiKey.isNotEmpty && _apiKey != 'your_api_key_here';

  // Безопасное чтение переменной окружения
  // (dotenv может быть не загружен, например в тестах)
  String? _env(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  // Определение провайдера по BASE_URL из .env файла
  ApiProviderType _detectProviderFromEnv() {
    final url = _env('BASE_URL') ?? '';
    return url.contains('vsetgpt.ru') || url.contains('vsegpt.ru')
        ? ApiProviderType.vsetgpt
        : ApiProviderType.openrouter;
  }

  // Инициализация сервиса: загрузка настроек из хранилища
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();

      // Восстановление сохранённого провайдера или определение по .env
      final savedProvider = _prefs!.getString(_kProvider);
      _provider = ApiProviderType.values.firstWhere(
        (p) => p.name == savedProvider,
        orElse: _detectProviderFromEnv,
      );

      // Восстановление ключа или значение по умолчанию из .env
      _apiKey = _prefs!.getString(_kApiKey) ??
          _env('OPENROUTER_API_KEY') ??
          '';

      // Параметры генерации
      _maxTokens =
          _prefs!.getInt(_kMaxTokens) ?? _envInt('MAX_TOKENS', 1000);
      _temperature =
          _prefs!.getDouble(_kTemperature) ?? _envDouble('TEMPERATURE', 0.7);
    } catch (e) {
      debugPrint('ConfigService init error: $e');
    }
    _initialized = true;
  }

  // Чтение целого числа из .env с значением по умолчанию
  int _envInt(String key, int defaultValue) =>
      int.tryParse(_env(key) ?? '') ?? defaultValue;

  // Чтение числа с плавающей точкой из .env с значением по умолчанию
  double _envDouble(String key, double defaultValue) =>
      double.tryParse(_env(key) ?? '') ?? defaultValue;

  // Сохранение новых настроек и уведомление слушателей
  Future<void> update({
    ApiProviderType? provider,
    String? apiKey,
    int? maxTokens,
    double? temperature,
  }) async {
    _provider = provider ?? _provider;
    _apiKey = apiKey ?? _apiKey;
    _maxTokens = maxTokens ?? _maxTokens;
    _temperature = temperature ?? _temperature;

    // Заглушка из шаблона считается отсутствием ключа
    if (_apiKey == 'your_api_key_here') {
      _apiKey = '';
    }

    // Сохранение настроек в хранилище
    await _prefs?.setString(_kProvider, _provider.name);
    await _prefs?.setString(_kApiKey, _apiKey);
    await _prefs?.setInt(_kMaxTokens, _maxTokens);
    await _prefs?.setDouble(_kTemperature, _temperature);

    // Уведомление слушателей (UI обновится автоматически)
    notifyListeners();
  }

  // Форматирование денежной суммы в валюте текущего провайдера
  String formatAmount(double amount, {int fractionDigits = 4}) {
    final formatted = amount.toStringAsFixed(fractionDigits);
    return isVseGpt ? '$formatted₽' : '\$$formatted';
  }
}
