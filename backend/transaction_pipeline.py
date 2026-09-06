# backend/transaction_pipeline.py
#
# Orchestrates POST /transactions/capture. Two distinct request shapes
# share this one endpoint (per the original frontend spec):
#   1. Normal capture: image_base64 (+ optional audio_base64 for a
#      voice-tagged category) -> OCR the amount, return a full
#      transaction + confidence.
#   2. audio_only=true: a spoken navigation command from the app's
#      wake-word flow -> just transcribe and return the text, no OCR,
#      no transaction persisted. This branch exists because
#      voice_service.dart's transcribeAudio() hits this same endpoint
#      expecting a {"transcript": "..."} shape, not a transaction shape
#      — see the ASSUMPTION note in the Flutter app's api_service.dart.

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.orm import Session

import ai_models
from config import settings
from database import TransactionRecord

# Categories that, in this app's domain (a kirana shop owner logging
# their OWN cash movements), represent money leaving the till rather
# than a sale — used to set the income/expense split that
# analytics.py's heatmap aggregation depends on. This is a heuristic
# assumption, not something derivable from the image/audio: "auto"
# (rickshaw fare) is almost always an expense; "groceries"/"vegetables"
# are ambiguous in general but assumed here to mean the owner's own
# stock purchases (expense) unless voice-tagged otherwise — see the
# note in README.md's Known Limitations for why this can't be fully
# resolved without a richer capture UI (an explicit income/expense
# toggle would remove the ambiguity entirely and is the recommended
# fix if this heuristic misclassifies too often in practice).
_EXPENSE_CATEGORIES = {"auto", "groceries", "vegetables"}


def _infer_transaction_type(category: str) -> str:
    return "expense" if category in _EXPENSE_CATEGORIES else "income"


@dataclass
class CaptureResult:
    is_audio_only: bool
    transcript: str | None = None
    transaction: TransactionRecord | None = None
    confidence: int = 0


def process_capture(
    db: Session,
    *,
    image_base64: str | None,
    audio_base64: str | None,
    audio_only: bool,
    customer_id: str | None = None,
    customer_name: str | None = None,
) -> CaptureResult:
    if audio_only:
        if not audio_base64:
            raise ValueError("audio_only=true requires audio_base64")
        transcript = ai_models.transcribe_audio(audio_base64)
        return CaptureResult(is_audio_only=True, transcript=transcript)

    if not image_base64:
        raise ValueError("image_base64 is required unless audio_only=true")

    image = ai_models.decode_base64_image(image_base64)
    ocr_result = ai_models.extract_amount(image)

    transcript = ai_models.transcribe_audio(audio_base64) if audio_base64 else None
    category = ai_models.extract_category_from_transcript(transcript)

    amount = ocr_result.amount if ocr_result.amount is not None else 0.0
    confidence = ocr_result.confidence if ocr_result.amount is not None else 0

    record = TransactionRecord(
        id=str(uuid.uuid4()),
        amount=amount,
        category=category,
        type=_infer_transaction_type(category),
        timestamp=datetime.now(timezone.utc),
        confidence=confidence,
        customer_id=customer_id,
        customer_name=customer_name,
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return CaptureResult(is_audio_only=False, transaction=record, confidence=confidence)


def transaction_to_dict(record: TransactionRecord) -> dict:
    """Shape matches Transaction.fromJson in the Flutter app exactly —
    changing a key name here silently breaks the frontend, so this is
    the one place that mapping is allowed to happen."""
    return {
        "id": record.id,
        "amount": record.amount,
        "category": record.category,
        "timestamp": record.timestamp.isoformat(),
        "confidence": record.confidence,
        "customer_id": record.customer_id,
        "customer_name": record.customer_name,
        "is_synced": True,
    }
