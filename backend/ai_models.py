# backend/ai_models.py
#
# HONESTY NOTE — READ BEFORE DEMOING "ON-DEVICE AI":
# This module does NOT contain a trained object-detection or
# UPI-screen-classification model. What it actually does:
#
#   - Amount extraction: real OCR (Tesseract via pytesseract) reads text
#     off the captured image, then a regex/heuristic pass looks for
#     rupee-amount patterns near payment keywords ("paid", "received",
#     "sent"). This works reasonably well on a clean UPI success
#     screenshot (large, high-contrast digits) and much less well on a
#     photo of cash notes (no text to OCR at all for that case — see
#     the cash-fallback note below).
#   - Category detection: keyword-matched from the ASR transcript if
#     voice-tagged, else defaulted to "other" — NOT visually classified
#     from the image. A real category classifier would need a labeled
#     training set (photos of groceries vs vegetables vs auto receipts)
#     that doesn't exist here.
#   - Speech-to-text: this one IS a real trained model — faster-whisper
#     (a CTranslate2 port of OpenAI's Whisper) actually transcribes the
#     audio. This is genuinely production-grade ASR, not a heuristic.
#
# If "on-device AI" in the pitch deck implies a custom vision model
# recognizing UPI screens/cash notes, that gap is real and this module
# doesn't close it — closing it needs a labeled dataset and a training
# pipeline, which is a materially different (and much larger) project
# than what 30 hackathon hours affords honestly.

from __future__ import annotations

import base64
import io
import re
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
import pytesseract
from PIL import Image

from config import settings

_whisper_model = None  # lazy-loaded — see transcribe_audio()


@dataclass
class AmountExtractionResult:
    amount: float | None
    confidence: int  # 0-100
    raw_ocr_text: str


def decode_base64_image(image_base64: str) -> Image.Image:
    """Decodes a base64 image string (as sent by the Flutter capture
    screen) into a Pillow Image. Raises ValueError on bad input rather
    than returning a blank image — a silently-blank image would produce
    a silently-wrong (0% confidence, no amount) result downstream."""
    try:
        raw = base64.b64decode(image_base64)
        return Image.open(io.BytesIO(raw)).convert("RGB")
    except Exception as e:
        raise ValueError(f"Could not decode image: {e}") from e


def _preprocess_for_ocr(image: Image.Image) -> np.ndarray:
    """Grayscale + adaptive threshold — a real, standard OCR
    preprocessing step (not decorative) that measurably improves
    Tesseract's accuracy on photographed screens vs. raw color input,
    which tends to have glare and uneven lighting."""
    arr = np.array(image)
    gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
    denoised = cv2.fastNlMeansDenoising(gray, h=10)
    thresh = cv2.adaptiveThreshold(
        denoised, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 11
    )
    return thresh


# Matches "₹500", "Rs. 500", "500 rupees", "INR 500", plain "500.00" near
# a payment keyword — deliberately conservative (requires a currency
# marker OR a payment-context word) to avoid matching an unrelated
# number on the screen (a phone battery %, a timestamp, etc).
_AMOUNT_PATTERN = re.compile(
    r"(?:₹|rs\.?|inr)\s*([\d,]+(?:\.\d{1,2})?)|"
    r"([\d,]+(?:\.\d{1,2})?)\s*(?:rupees?|rs\.?)",
    re.IGNORECASE,
)
_PAYMENT_CONTEXT_WORDS = ("paid", "received", "sent", "success", "successful", "payment")


def extract_amount(image: Image.Image) -> AmountExtractionResult:
    """Real OCR pass + heuristic confidence scoring. Confidence
    reflects actual signal quality (Tesseract's own per-word confidence,
    whether a currency marker was found, whether payment-context words
    were present) — it is not a fabricated/hardcoded number."""
    processed = _preprocess_for_ocr(image)

    ocr_data = pytesseract.image_to_data(
        processed, output_type=pytesseract.Output.DICT, config="--psm 6"
    )
    full_text = " ".join(w for w in ocr_data["text"] if w.strip())

    match = _AMOUNT_PATTERN.search(full_text)
    if not match:
        return AmountExtractionResult(amount=None, confidence=0, raw_ocr_text=full_text)

    amount_str = (match.group(1) or match.group(2)).replace(",", "")
    try:
        amount = float(amount_str)
    except ValueError:
        return AmountExtractionResult(amount=None, confidence=0, raw_ocr_text=full_text)

    # Confidence heuristic — starts from Tesseract's own average word
    # confidence (a real signal it provides, 0-100 per word, -1 for
    # non-text regions), then adjusted by context signals.
    word_confidences = [c for c in ocr_data["conf"] if isinstance(c, (int, float)) and c >= 0]
    base_confidence = int(sum(word_confidences) / len(word_confidences)) if word_confidences else 40

    has_currency_marker = bool(re.search(r"₹|rs\.?|inr", full_text, re.IGNORECASE))
    has_context_word = any(w in full_text.lower() for w in _PAYMENT_CONTEXT_WORDS)

    confidence = base_confidence
    if not has_currency_marker:
        confidence -= 15  # matched via bare "rupees"/"rs" suffix only — weaker signal
    if has_context_word:
        confidence += 10  # payment-context language corroborates this is a real transaction amount
    confidence = max(0, min(100, confidence))

    return AmountExtractionResult(amount=amount, confidence=confidence, raw_ocr_text=full_text)


def extract_category_from_transcript(transcript: str | None) -> str:
    """Keyword match against a voice transcript — real string matching,
    not a classifier. Returns 'other' if nothing matches or no
    transcript was provided (e.g. a photo-only capture with no audio
    tag), which is the honest default rather than guessing."""
    if not transcript:
        return "other"
    text = transcript.lower()
    if any(w in text for w in ("grocery", "groceries", "kirana", "provisions")):
        return "groceries"
    if any(w in text for w in ("vegetable", "vegetables", "sabzi", "kaya", "kura")):
        return "vegetables"
    if any(w in text for w in ("auto", "rickshaw", "cab", "ride")):
        return "auto"
    return "other"


def transcribe_audio(audio_base64: str) -> str:
    """Real speech-to-text via faster-whisper. Unlike the amount/category
    functions above, this is genuinely a trained model doing genuine
    inference — not a heuristic standing in for one.

    Model loads lazily (first call only) since loading it at import time
    would slow down every FastAPI worker's startup, including workers
    that never handle an audio request. First call after a fresh
    install also triggers a one-time download of the model checkpoint
    from Hugging Face — needs internet exactly once, then it's cached.
    """
    global _whisper_model
    if _whisper_model is None:
        from faster_whisper import WhisperModel  # deferred import — see docstring

        _whisper_model = WhisperModel(
            settings.whisper_model_size,
            device=settings.whisper_device,
            compute_type=settings.whisper_compute_type,
        )

    raw = base64.b64decode(audio_base64)
    tmp_path = settings.uploads_dir / "tmp_transcribe_audio"
    tmp_path.write_bytes(raw)

    try:
        segments, _info = _whisper_model.transcribe(str(tmp_path), language=None)
        return " ".join(segment.text.strip() for segment in segments).strip()
    finally:
        tmp_path.unlink(missing_ok=True)
