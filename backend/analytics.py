# backend/analytics.py
#
# Powers GET /analytics/heatmap. Aggregates real stored transactions by
# calendar day — no synthetic/demo data injected here; an empty window
# returns an empty days list, and the Flutter HeatmapCalendar widget
# already has a real empty state for exactly that case (see
# heatmap_calendar.dart's _EmptyHeatmapState).

from __future__ import annotations

from collections import defaultdict
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from database import TransactionRecord


def compute_heatmap(db: Session, days: int = 30) -> dict:
    window_start = datetime.now(timezone.utc) - timedelta(days=days)
    records: list[TransactionRecord] = (
        db.query(TransactionRecord)
        .filter(TransactionRecord.timestamp >= window_start)
        .order_by(TransactionRecord.timestamp.asc())
        .all()
    )

    daily_income: dict = defaultdict(float)
    daily_expense: dict = defaultdict(float)
    for r in records:
        day_key = r.timestamp.date()
        if r.type == "income":
            daily_income[day_key] += r.amount
        else:
            daily_expense[day_key] += r.amount

    all_days = sorted(set(daily_income.keys()) | set(daily_expense.keys()))

    return {
        "days": [
            {
                "date": datetime(day.year, day.month, day.day, tzinfo=timezone.utc).isoformat(),
                "income": round(daily_income.get(day, 0.0), 2),
                "expense": round(daily_expense.get(day, 0.0), 2),
            }
            for day in all_days
        ]
    }
