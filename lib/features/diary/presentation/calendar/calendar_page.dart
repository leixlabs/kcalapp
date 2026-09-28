import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../application/diary_providers.dart';
import '../../../../core/utils/format_utils.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final monthlyKcalAsync = ref.watch(monthlyMealsProvider(_focusedDay));

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          monthlyKcalAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
            data: (kcalMap) => TableCalendar(
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => FormatUtils.isSameDay(day, selectedDate),
              onDaySelected: (selected, focused) {
                setState(() {
                  _focusedDay = focused;
                });
                ref.read(selectedDateProvider.notifier).state = selected;
                context.pop();
              },
              onPageChanged: (focused) {
                setState(() {
                  _focusedDay = focused;
                });
              },
              locale: 'zh_CN',
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(theme, day, kcalMap);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildDayCell(theme, day, kcalMap, isSelected: true);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildDayCell(theme, day, kcalMap, isToday: true);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(ThemeData theme, DateTime day, Map<int, double> kcalMap,
      {bool isSelected = false, bool isToday = false}) {
    final kcal = kcalMap[day.day];
    final hasKcal = kcal != null && kcal > 0;

    Color? bgColor;
    Color textColor = theme.colorScheme.onSurface;

    if (isSelected) {
      bgColor = theme.colorScheme.primary;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = theme.colorScheme.primaryContainer;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (hasKcal)
            Text(
              '${kcal.round()}k',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? Colors.white70 : theme.colorScheme.primary,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
