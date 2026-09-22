// frontend/lib/models/heatmap_data.dart

/// One day's income/expense summary — one square on the HeatmapCalendar.
class DailySummary {
  final DateTime date;
  final double income;
  final double expense;

  const DailySummary({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  /// Intensity bucket used by HeatmapCalendar to pick a shade of green.
  /// (light <500, medium 500-1000, dark >1000, per the design spec)
  HeatmapIntensity get intensity {
    if (income < 500) return HeatmapIntensity.light;
    if (income <= 1000) return HeatmapIntensity.medium;
    return HeatmapIntensity.dark;
  }

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: DateTime.parse(json['date'] as String),
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'income': income,
        'expense': expense,
      };
}

enum HeatmapIntensity { none, light, medium, dark }

/// Result of `GET /analytics/heatmap` — a window of [DailySummary]s plus
/// the derived insights shown on the Heatmap screen's insight cards.
class HeatmapData {
  final List<DailySummary> days;

  const HeatmapData({required this.days});

  /// Highest-average-income weekday across the window, or null if there's
  /// no data yet (empty state is handled by the screen, not this model).
  ({String weekday, double avgIncome})? get bestDay =>
      _weekdayExtreme(max: true);
  ({String weekday, double avgIncome})? get worstDay =>
      _weekdayExtreme(max: false);

  /// Percentage change in income between the most recent 7 days and the
  /// 7 days before that. Null when there isn't two full weeks of data.
  double? get weekOverWeekTrend {
    if (days.length < 14) return null;
    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final last7 = sorted.sublist(sorted.length - 7);
    final prev7 = sorted.sublist(sorted.length - 14, sorted.length - 7);
    final lastAvg = last7.fold(0.0, (s, d) => s + d.income) / 7;
    final prevAvg = prev7.fold(0.0, (s, d) => s + d.income) / 7;
    if (prevAvg == 0) return null;
    return ((lastAvg - prevAvg) / prevAvg) * 100;
  }

  ({String weekday, double avgIncome})? _weekdayExtreme({required bool max}) {
    if (days.isEmpty) return null;
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final totals = <int, double>{};
    final counts = <int, int>{};
    for (final day in days) {
      final weekday = day.date.weekday; // 1=Mon..7=Sun
      totals[weekday] = (totals[weekday] ?? 0) + day.income;
      counts[weekday] = (counts[weekday] ?? 0) + 1;
    }
    final averages = totals
        .map((weekday, total) => MapEntry(weekday, total / counts[weekday]!));
    final entries = averages.entries.toList();
    entries.sort((a, b) =>
        max ? b.value.compareTo(a.value) : a.value.compareTo(b.value));
    final best = entries.first;
    return (weekday: weekdayNames[best.key - 1], avgIncome: best.value);
  }

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      days: (json['days'] as List<dynamic>)
          .map((e) => DailySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'days': days.map((d) => d.toJson()).toList(),
      };
}
