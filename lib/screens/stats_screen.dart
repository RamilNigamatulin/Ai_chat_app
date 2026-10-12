// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт сервиса конфигурации (для валюты)
import '../services/config_service.dart';

// Экран статистики использования токенов моделями
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

// Состояние экрана статистики
class _StatsScreenState extends State<StatsScreen> {
  // Агрегированная статистика из БД
  Map<String, dynamic>? _stats;

  // Ошибка загрузки
  String? _error;

  // Флаг первой загрузки
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Загрузка статистики при открытии экрана
    _load();
  }

  // Метод загрузки статистики
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await context.read<ChatProvider>().getModelUsageStatistics();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Форматирование количества (разделитель разрядов)
  String _fmt(num value) => value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );

  @override
  Widget build(BuildContext context) {
    // Знак валюты текущего провайдера
    final currency = ConfigService().currencySymbol;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Статистика токенов',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          // Кнопка обновления статистики
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            tooltip: 'Обновить',
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(currency)),
    );
  }

  // Построение тела экрана в зависимости от состояния
  Widget _buildBody(String currency) {
    // Индикатор загрузки
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    // Сообщение об ошибке
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Ошибка загрузки статистики: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      );
    }

    // Данные статистики
    final stats = _stats ?? {};
    final totalMessages = stats['total_messages'] ?? 0;
    final totalTokens = stats['total_tokens'] ?? 0;
    final modelUsage =
        (stats['model_usage'] as Map<String, dynamic>?) ?? {};

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Общие показатели
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.chat_bubble_outline,
                label: 'Сообщений',
                value: _fmt(totalMessages),
                color: const Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.bolt,
                label: 'Токенов',
                value: _fmt(totalTokens),
                color: const Color(0xFF33CC33),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Заголовок списка моделей
        Text(
          'Использование по моделям (${modelUsage.length})',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Список моделей или пустое состояние
        if (modelUsage.isEmpty)
          _buildEmptyState()
        else
          ...modelUsage.entries.map(
            (entry) => _buildModelCard(
              modelId: entry.key,
              data: (entry.value as Map?)?.cast<String, dynamic>() ?? {},
              currency: currency,
            ),
          ),
      ],
    );
  }

  // Построение сводной карточки (сообщения/токены)
  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Построение карточки одной модели
  Widget _buildModelCard({
    required String modelId,
    required Map<String, dynamic> data,
    required String currency,
  }) {
    // Количество сообщений и токенов по модели
    final count = data['count'] ?? 0;
    final tokens = data['tokens'] ?? 0;

    // Долю модели в общем количестве токенов
    final totalTokens = _stats?['total_tokens'] ?? 0;
    final share = totalTokens > 0 ? (tokens / totalTokens * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Идентификатор модели
          Text(
            modelId,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Количество сообщений и токенов
          Row(
            children: [
              _buildModelStat('Сообщений', _fmt(count)),
              const SizedBox(width: 16),
              _buildModelStat('Токенов', _fmt(tokens)),
            ],
          ),
          const SizedBox(height: 8),
          // Индикатор доли использования
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalTokens > 0 ? share / 100 : 0,
                    backgroundColor: const Color(0xFF1E1E1E),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF33CC33)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${share.toStringAsFixed(1)}%',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Построение одного показателя внутри карточки модели
  Widget _buildModelStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // Построение пустого состояния (нет данных)
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.bar_chart, color: Colors.white24, size: 48),
          SizedBox(height: 12),
          Text(
            'Пока нет данных.\nОтправьте несколько сообщений, чтобы увидеть статистику.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

