// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт сервиса конфигурации
import '../services/config_service.dart';

// Экран настройки провайдера и ввода API ключа
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Состояние экрана настроек
class _SettingsScreenState extends State<SettingsScreen> {
  // Контроллер поля ввода API ключа
  late final TextEditingController _apiKeyController;

  // Контроллер поля максимального количества токенов
  late final TextEditingController _maxTokensController;

  // Контроллер поля температуры генерации
  late final TextEditingController _temperatureController;

  // Текущий выбранный провайдер
  late ApiProviderType _selectedProvider;

  // Флаг видимости API ключа
  bool _obscureKey = true;

  // Флаг сохранения настроек
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Инициализация полей текущими значениями из конфигурации
    final config = ConfigService();
    _apiKeyController = TextEditingController(text: config.apiKey);
    _maxTokensController =
        TextEditingController(text: config.maxTokens.toString());
    _temperatureController =
        TextEditingController(text: config.temperature.toString());
    _selectedProvider = config.provider;
  }

  @override
  void dispose() {
    // Освобождение контроллеров
    _apiKeyController.dispose();
    _maxTokensController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  // Метод сохранения настроек
  Future<void> _save() async {
    // Валидация максимального количества токенов
    final maxTokens = int.tryParse(_maxTokensController.text.trim());
    if (maxTokens == null || maxTokens <= 0) {
      _showMessage('Некорректное значение токенов', isError: true);
      return;
    }

    // Валидация температуры (диапазон 0.0 - 2.0)
    final temperature = double.tryParse(_temperatureController.text.trim());
    if (temperature == null || temperature < 0 || temperature > 2) {
      _showMessage('Температура должна быть в диапазоне 0.0 - 2.0',
          isError: true);
      return;
    }

    setState(() => _saving = true);

    // Сохранение настроек в конфигурации
    await ConfigService().update(
      provider: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      maxTokens: maxTokens,
      temperature: temperature,
    );

    // Обновление данных чата (модели и баланс) с новыми настройками
    if (mounted) {
      await context.read<ChatProvider>().refresh();
    }

    if (!mounted) return;
    setState(() => _saving = false);

    _showMessage('Настройки сохранены');
  }

  // Вспомогательный метод отображения уведомления
  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontSize: 12)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Настройки',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Выбор провайдера API
            const Text(
              'Провайдер API',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildProviderCard(
              provider: ApiProviderType.openrouter,
              title: 'OpenRouter.ai',
              subtitle: 'Баланс в долларах, цены за 1M токенов',
              icon: Icons.cloud,
            ),
            const SizedBox(height: 8),
            _buildProviderCard(
              provider: ApiProviderType.vsetgpt,
              title: 'VseGPT.ru',
              subtitle: 'Баланс в рублях, цены за 1K токенов',
              icon: Icons.cloud_sync,
            ),
            const SizedBox(height: 24),

            // Ввод API ключа
            const Text(
              'API ключ',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Введите API ключ...',
                hintStyle:
                    const TextStyle(color: Colors.white54, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF333333),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Параметры генерации
            const Text(
              'Параметры генерации',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Максимальное количество токенов
                Expanded(
                  child: TextField(
                    controller: _maxTokensController,
                    keyboardType: TextInputType.number,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Max токенов',
                      labelStyle: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF333333),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Температура генерации
                Expanded(
                  child: TextField(
                    controller: _temperatureController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Температура',
                      labelStyle: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF333333),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Кнопка сохранения
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  _saving ? 'Сохранение...' : 'Сохранить настройки',
                  style: const TextStyle(fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Построение карточки выбора провайдера
  Widget _buildProviderCard({
    required ApiProviderType provider,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    // Флаг выбранного провайдера
    final isSelected = _selectedProvider == provider;

    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF1A3A5C) : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.blue : Colors.white54, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF1A73E8), size: 20),
          ],
        ),
      ),
    );
  }
}

