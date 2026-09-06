# backend/config.py
#
# Centralized settings. All tunable values (thresholds, weights, paths)
# live here so transaction_pipeline.py / credit_scorer.py / etc. never
# hardcode a magic number inline — one place to retune before the demo.

from pathlib import Path
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # --- Server ---
    host: str = "0.0.0.0"
    port: int = 8000
    cors_origins: list[str] = ["*"]  # locked to localhost/device bridge in practice

    # --- Storage ---
    base_dir: Path = Path(__file__).resolve().parent
    data_dir: Path = base_dir / "data"
    db_path: Path = data_dir / "vyapaarsaathi.db"
    uploads_dir: Path = data_dir / "uploads"  # temp decoded images/audio
    invoices_dir: Path = data_dir / "invoices"  # generated GST PDFs

    # --- Transaction capture ---
    # Below this confidence (0-100), the frontend shows a "Verify
    # manually?" prompt (see TransactionCaptureResponse in the Flutter
    # app) rather than silently trusting the OCR read.
    low_confidence_threshold: int = 70

    # --- Speech-to-text ---
    # "tiny" is fastest / least accurate; "base" is a reasonable
    # tradeoff for a hackathon demo. "small"+ needs more RAM than a
    # phone-adjacent dev machine may want to spare mid-demo.
    whisper_model_size: str = "base"
    whisper_device: str = "cpu"  # no GPU assumed on hackathon hardware
    whisper_compute_type: str = "int8"  # fastest CPU inference mode

    # --- Credit scoring weights (must sum to 1.0) ---
    # See credit_scorer.py for what each factor actually measures.
    weight_consistency: float = 0.4
    weight_diversity: float = 0.3
    weight_income: float = 0.3
    # Daily income (rupees) that maps to a full 100 on the income
    # sub-score — an assumed reference point, not derived from real
    # lending data. Tune this against whatever the actual target
    # customer segment's typical daily revenue looks like.
    income_score_reference: float = 1500.0

    # --- GST ---
    business_name: str = "VyapaarSaathi Kirana Store"
    business_gstin_placeholder: str = "PENDING-GSTIN-REGISTRATION"

    class Config:
        env_file = ".env"
        env_prefix = "VYAPAARSAATHI_"


settings = Settings()
settings.data_dir.mkdir(parents=True, exist_ok=True)
settings.uploads_dir.mkdir(parents=True, exist_ok=True)
settings.invoices_dir.mkdir(parents=True, exist_ok=True)
