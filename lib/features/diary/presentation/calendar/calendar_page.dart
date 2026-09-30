import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../application/diary_providers.dart';
import '../../../../core/utils/format_utils.dart';

class CalendarDrawer extends ConsumerWidget {
  final DateTime selectedDate;
  final DateTime focusedDay;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onFocusedDayChanged;

  const CalendarDrawer({
    super.key,
    required this.selectedDate,
    required this.focusedDay,
    required this.onDateSelected,
    required this.onFocusedDayChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monthlyKcalAsync = ref.watch(monthlyMealsProvider(focusedDay));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: monthlyKcalAsync.when(
            loading: () => const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('日历加载失败: $error'),
            ),
            data: (kcalMap) {
              return TableCalendar(
                firstDay: DateTime(2024, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) =>
                    FormatUtils.isSameDay(day, selectedDate),
                onDaySelected: (selected, focused) {
                  onFocusedDayChanged(focused);
                  onDateSelected(selected);
                },
                onPageChanged: onFocusedDayChanged,
                locale: 'zh_CN',
                rowHeight: 54,
                daysOfWeekHeight: 24,
                calendarStyle: CalendarStyle(
                  cellMargin: const EdgeInsets.all(2),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) =>
                      _buildDayCell(theme, day, kcalMap),
                  selectedBuilder: (context, day, _) =>
                      _buildDayCell(theme, day, kcalMap, isSelected: true),
                  todayBuilder: (context, day, _) =>
                      _buildDayCell(theme, day, kcalMap, isToday: true),
                  outsideBuilder: (context, day, _) =>
                      _buildDayCell(theme, day, kcalMap, isOutside: true),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    ThemeData theme,
    DateTime day,
    Map<DateTime, double> kcalMap, {
    bool isSelected = false,
    bool isToday = false,
    bool isOutside = false,
  }) {
    final date = DateTime(day.year, day.month, day.day);
    final kcal = kcalMap[date];
    final hasKcal = kcal != null && kcal > 0;
    final textColor = isSelected
        ? Colors.white
        : isOutside
        ? theme.colorScheme.outlineVariant
        : theme.colorScheme.onSurface;

    return Semantics(
      container: true,
      label: hasKcal ? '${day.day}日，${kcal.round()}千卡' : '${day.day}日',
      button: true,
      selected: isSelected,
      child: Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : isToday
                ? theme.colorScheme.primaryContainer
                : null,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (hasKcal)
                SizedBox(
                  width: 42,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      kcal.round().toString(),
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
