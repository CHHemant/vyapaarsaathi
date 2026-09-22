// frontend/lib/models/credit_score.dart

/// Loan eligibility tier, derived from [CreditScore.score].
/// Kept as an enum (not computed inline in the widget) so the Home,
/// Credit, and PDF-report code paths can never disagree on the thresholds.
enum LoanEligibility {
  low, // <40
  medium, // 40-70
  high; // >70

  static LoanEligibility fromScore(int score) {
    if (score < 40) return LoanEligibility.low;
    if (score <= 70) return LoanEligibility.medium;
    return LoanEligibility.high;
  }

  String get label => switch (this) {
        LoanEligibility.low => 'Low - Up to ₹5,000',
        LoanEligibility.medium => 'Medium - Up to ₹15,000',
        LoanEligibility.high => 'High - Up to ₹50,000',
      };
}

/// Breakdown of the three factors that make up the overall score.
/// A record would work here too, but a named class reads better once
/// this gets passed through Riverpod providers and widget constructors.
class CreditBreakdown {
  final int consistency; // 0-100, calendar icon
  final int diversity; // 0-100, people icon
  final double avgDailyIncome; // rupees/day

  const CreditBreakdown({
    required this.consistency,
    required this.diversity,
    required this.avgDailyIncome,
  });

  factory CreditBreakdown.fromJson(Map<String, dynamic> json) {
    return CreditBreakdown(
      consistency: (json['consistency'] as num).toInt(),
      diversity: (json['diversity'] as num).toInt(),
      avgDailyIncome: (json['avg_daily_income'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'consistency': consistency,
        'diversity': diversity,
        'avg_daily_income': avgDailyIncome,
      };
}

/// Result of `GET /credit-score`. [fetchedAt] is stamped locally (not from
/// the backend) so the "Last updated: 2 hours ago" cached-data badge can
/// be computed without relying on the backend to echo a timestamp back.
class CreditScore {
  final int score; // 0-100
  final CreditBreakdown breakdown;
  final DateTime fetchedAt;

  const CreditScore({
    required this.score,
    required this.breakdown,
    required this.fetchedAt,
  });

  LoanEligibility get eligibility => LoanEligibility.fromScore(score);

  factory CreditScore.fromJson(Map<String, dynamic> json) {
    return CreditScore(
      score: (json['score'] as num).toInt(),
      breakdown:
          CreditBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
      fetchedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'breakdown': breakdown.toJson(),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  /// Rebuild from a cached Hive entry, where fetchedAt was actually
  /// persisted (unlike fromJson, which stamps "now" for a fresh fetch).
  factory CreditScore.fromCache(Map<String, dynamic> json) {
    return CreditScore(
      score: (json['score'] as num).toInt(),
      breakdown:
          CreditBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
    );
  }
}
