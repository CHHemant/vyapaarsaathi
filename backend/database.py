# backend/database.py
#
# SQLite via SQLAlchemy. Schema note: the Transaction table has a
# `type` column ("income"/"expense") that the Flutter frontend's
# Transaction model never sees over the wire — the frontend only reads
# aggregated income/expense via GET /analytics/heatmap. `type` is
# assigned at capture time in transaction_pipeline.py, using a category
# heuristic (see the comment there) since there's no reliable way to
# infer it from the image/audio alone without real transaction context.

from datetime import datetime, timezone

from sqlalchemy import create_engine, Column, String, Float, Integer, DateTime, Boolean
from sqlalchemy.orm import declarative_base, sessionmaker, Session

from config import settings

engine = create_engine(
    f"sqlite:///{settings.db_path}",
    connect_args={"check_same_thread": False},  # FastAPI may use multiple threads
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class TransactionRecord(Base):
    __tablename__ = "transactions"

    id = Column(String, primary_key=True)
    amount = Column(Float, nullable=False)
    category = Column(String, nullable=False)  # groceries | vegetables | auto | other
    type = Column(String, nullable=False, default="income")  # income | expense
    timestamp = Column(DateTime, nullable=False, default=utcnow)
    confidence = Column(Integer, nullable=False, default=0)
    customer_id = Column(String, nullable=True)
    customer_name = Column(String, nullable=True)


class CustomerRecord(Base):
    __tablename__ = "customers"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    # Never store a raw phone number — only a hash, matching the
    # frontend's own privacy design (Customer.phoneHash in customer.dart).
    phone_hash = Column(String, nullable=False)
    is_verified = Column(Boolean, nullable=False, default=False)


def init_db() -> None:
    Base.metadata.create_all(bind=engine)


def get_db() -> Session:
    """FastAPI dependency — yields a session, always closes it after the
    request, even on an unhandled exception."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
