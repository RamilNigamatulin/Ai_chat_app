// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт сервиса конфигурации (для валюты)
import '../services/config_service.dart';

// Экран графика расходов по дням
class SpendingScreen extends StatefulWidget {
  const SpendingScreen({super.key});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

// Состояние экрана расходов
class _SpendingScreenState extends State<SpendingScreen> {
  // Данные о расходах по дням: [{'day': 'YYYY-MM-DD', 'cost': double}]
  List<Map<String, dynamic>> _daily = [];

  // Ошибка загрузки
  String? _error;

  // Флаг первой загрузки
  bool _loading = true;

  // Период выборки (в днях)
  int _days = 30;

  @override
  void initState() {
    super.initState();
    // Загрузка данных при открытии экрана
    _load();
  }

  // Метод загрузки данных о расходах
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final daily = await context
          .read<ChatProvider>()
          .getDailySpending(days: _days);
      if (!mounted) return;
      setState(() {
        _daily = daily;
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

  // Форматирование суммы в валюте провайдера
  String _fmtAmount(double value, {int fractionDigits = 2}) {
    final currency = ConfigService();
    final amount = value.toStringAsFixed(fractionDigits);
    return currency.isVseGpt ? '$amount₽' : '\$$amount';
  }

  // Форматирование короткой даты (дд.мм) из 'YYYY-MM-DD'
  String _fmtDay(String isoDay) {
    if (isoDay.length < 10) return isoDay;
    final parts = isoDay.split('-');
    return '${parts[2]}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Расходы по дням',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          // Кнопка обновления данных
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            tooltip: 'Обновить',
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  // Построение тела экрана в зависимости от состояния
  Widget _buildBody() {
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
            'Ошибка загрузки данных: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      );
    }

    // Сумма за период
    final total =
        _daily.fold<double>(0, (sum, item) => sum + (item['cost'] ?? 0));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Переключатель периода
        _buildPeriodSelector(),
        const SizedBox(height: 16),

        // Карточка с итоговой суммой
        _buildTotalCard(total),
        const SizedBox(height: 16),

        // График расходов
        if (_daily.isEmpty)
          _buildEmptyState()
        else ...[
          const Text(
            'Динамика',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildChart(),
          const SizedBox(height: 16),

          // Детальная таблица по дням
          const Text(
            'По дням',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._daily.reversed.map(_buildDayRow),
        ],
      ],
    );
  }

  // Построение переключателя периода
  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Text('Период:',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 12),
        // Кнопки выбора периода
        for (final days in const [7, 14, 30])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$days дн.',
                  style: const TextStyle(fontSize: 11)),
              selected: _days == days,
              selectedColor: const Color(0xFF1A73E8),
              backgroundColor: const Color(0xFF333333),
              labelStyle: TextStyle(
                  color: _days == days ? Colors.white : Colors.white70),
              onSelected: (_) {
                if (_days != days) {
                  setState(() => _days = days);
                  _load();
                }
              },
            ),
          ),
      ],
    );
  }

  // Построение карточки с итоговой суммой
  Widget _buildTotalCard(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet,
              color: Color(0xFF33CC33), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Всего за $_days дней',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                _fmtAmount(total, fractionDigits: 4),
                style: const TextStyle(
                    color: Color(0xFF33CC33),
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Построение строки таблицы по конкретному дню
  Widget _buildDayRow(Map<String, dynamic> item) {
    // Дата и сумма за день
    final day = item['day'] as String;
    final cost = (item['cost'] as num?)?.toDouble() ?? 0.0;

    // Максимальная сумма для расчёта доли дня
    final maxCost = _daily.fold<double>(
        0, (max, e) => (e['cost'] ?? 0) > max ? (e['cost'] ?? 0) : max);
    final fraction = maxCost > 0 ? cost / maxCost : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Дата
          SizedBox(
            width: 48,
            child: Text(_fmtDay(day),
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          // Относительная полоса расходов за день
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: const Color(0xFF1E1E1E),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1A73E8)),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Сумма за день
          SizedBox(
            width: 80,
            child: Text(
              _fmtAmount(cost, fractionDigits: 4),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Построение столбчатого графика расходов
  Widget _buildChart() {
    // Максимальная сумма для масштабирования столбцов
    final maxCost = _daily.fold<double>(
        0, (max, e) => ((e['cost'] as num?)?.toDouble() ?? 0) > max
            ? (e['cost'] as num?)!.toDouble()
            : max);
    final safeMax = maxCost > 0 ? maxCost : 1.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        // Столбцы отображаются слева направо по дням
        children: _daily.map((item) {
          // Сумма за день
          final cost = (item['cost'] as num?)?.toDouble() ?? 0.0;
          // Относительная высота столбца (минимум 2px для видимости)
          final heightFactor = cost > 0 ? (cost / safeMax) : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Столбец (жёсткая высота пропорционально сумме)
                  Container(
                    height: (heightFactor * 110).clamp(2.0, 110.0),
                    decoration: BoxDecoration(
                      color: cost > 0
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Подпись дня (отображается не каждый день,
                  // чтобы избежать наложений)
                  if (_daily.length <= 10 ||
                      _daily.indexOf(item) % 2 == 0)
                    FittedBox(
                      child: Text(
                        _fmtDay(item['day'] as String),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 8),
                      ),
                    )
                  else
                    const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Построение пустого состояния (нет данных)
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.show_chart, color: Colors.white24, size: 48),
          SizedBox(height: 12),
          Text(
            'Нет расходов за выбранный период.\nСтоимость появляется после ответов моделей.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

