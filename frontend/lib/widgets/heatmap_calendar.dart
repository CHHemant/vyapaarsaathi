// frontend/lib/widgets/heatmap_calendar.dart

import 'package:flutter/material.dart';
import '../models/heatmap_data.dart';
import '../theme/kirana_colors.dart';

class HeatmapCalendar extends StatelessWidget {
  final List<DailySummary> days;
  final double squareSize;
  final double squareSpacing;

  const HeatmapCalendar({
    super.key,
    required this.days,
    this.squareSize = 20,
    this.squareSpacing = 4,
  });

  static const List<String> _weekdayLabels = [
    'Mon',
    '',
    'Wed',
    '',
    'Fri',
    '',
    ''
  ];

  Color _colorFor(DailySummary? day, bool isDark) {
    if (day == null) return Colors.transparent;
    final baseColor = KiranaColors.secondary;
    return switch (day.intensity) {
      HeatmapIntensity.none => isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
      HeatmapIntensity.light => baseColor.withValues(alpha: 0.2),
      HeatmapIntensity.medium => baseColor.withValues(alpha: 0.5),
      HeatmapIntensity.dark => baseColor,
    };
  }

  List<List<DailySummary?>> _bucketIntoWeeks() {
    if (days.isEmpty) return [];
    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));

    final firstDate = sorted.first.date;
    final firstMonday =
        firstDate.subtract(Duration(days: firstDate.weekday - 1));

    final weeks = <int, List<DailySummary?>>{};
    for (final day in sorted) {
      final weekIndex = day.date.difference(firstMonday).inDays ~/ 7;
      final dayOfWeek = day.date.weekday - 1;
      weeks.putIfAbsent(weekIndex, () => List.filled(7, null, growable: false));
      weeks[weekIndex]![dayOfWeek] = day;
    }

    final maxWeek = weeks.keys.reduce((a, b) => a > b ? a : b);
    return [
      for (var w = 0; w <= maxWeek; w++) weeks[w] ?? List.filled(7, null)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (days.isEmpty) {
      return const _EmptyHeatmapState();
    }

    final weeks = _bucketIntoWeeks();
    final cellExtent = squareSize + squareSpacing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: cellExtent * 7,
          child: Column(
            children: _weekdayLabels
                .map((label) => SizedBox(
                      height: cellExtent,
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: weeks
                  .map((week) => Padding(
                        padding: EdgeInsets.only(right: squareSpacing),
                        child: Column(
                          children: week
                              .map((day) => Padding(
                                    padding:
                                        EdgeInsets.only(bottom: squareSpacing),
                                    child: _DaySquare(
                                      day: day,
                                      size: squareSize,
                                      color: _colorFor(day, isDark),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DaySquare extends StatelessWidget {
  final DailySummary? day;
  final double size;
  final Color color;

  const _DaySquare(
      {required this.day, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final square = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );

    if (day == null) return square;

    return Tooltip(
      message:
          '${day!.date.day}/${day!.date.month}: ₹${day!.income.toStringAsFixed(0)}',
      child: square,
    );
  }
}

class _EmptyHeatmapState extends StatelessWidget {
  const _EmptyHeatmapState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 32,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            Text(
              'No data yet',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
