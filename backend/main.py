# backend/main.py
#
# FastAPI app implementing the 6 documented endpoints. Request/response
# JSON shapes are matched deliberately against what the Flutter app's
# api_service.dart already expects (built in an earlier phase of this
# project) — see the inline "matches ..." comments below for exactly
# which frontend model each response shape is contractually tied to.


from __future__ import annotations


from datetime import datetime
from typing import Optional
from pathlib import Path
from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session


import analytics
import credit_scorer
import gst_generator
import transaction_pipeline
import tax_assistant
from config import settings
from database import init_db, get_db, CustomerRecord, TransactionRecord


app = FastAPI(title="VyapaarSaathi Backend", version="1.0.0")


app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)



@app.on_event("startup")
def on_startup() -> None:
    init_db()



# ---------------------------------------------------------------------
# Request/response models
# ---------------------------------------------------------------------


class CaptureRequest(BaseModel):
    image_base64: Optional[str] = None
    audio_base64: Optional[str] = None
    audio_only: bool = False
    customer_id: Optional[str] = None
    customer_name: Optional[str] = None



class InvoiceItemRequest(BaseModel):
    id: str
    name: str
    quantity: float
    unit_price: float = Field(alias="unit_price")
    gst_rate: int


    class Config:
        populate_by_name = True



class InvoiceRequest(BaseModel):
    customer_phone: Optional[str] = None
    items: list[InvoiceItemRequest]



class VerifyCustomerRequest(BaseModel):
    customer_id: str
    phone_number: str


class TaxAssistantRequest(BaseModel):
    query: str


# ---------------------------------------------------------------------
# 1. POST /api/v1/transactions/capture
# ---------------------------------------------------------------------


@app.post("/api/v1/transactions/capture")
def capture_transaction(payload: CaptureRequest, db: Session = Depends(get_db)):
    try:
        result = transaction_pipeline.process_capture(
            db,
            image_base64=payload.image_base64,
            audio_base64=payload.audio_base64,
            audio_only=payload.audio_only,
            customer_id=payload.customer_id,
            customer_name=payload.customer_name,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e


    if result.is_audio_only:
        return {"transcript": result.transcript}


    return {
        "confidence": result.confidence,
        "transaction": transaction_pipeline.transaction_to_dict(result.transaction),
    }



# ---------------------------------------------------------------------
# 2. GET /api/v1/credit-score
# ---------------------------------------------------------------------


@app.get("/api/v1/credit-score")
def get_credit_score(days: int = 30, db: Session = Depends(get_db)):
    return credit_scorer.compute_credit_score(db, days=days)



# ---------------------------------------------------------------------
# 3. POST /api/v1/gst/invoice
# ---------------------------------------------------------------------


@app.post("/api/v1/gst/invoice")
def generate_gst_invoice(payload: InvoiceRequest, db: Session = Depends(get_db)):
    if not payload.items:
        raise HTTPException(status_code=400, detail="At least one item is required")


    items = [
        gst_generator.InvoiceItemInput(
            id=i.id, name=i.name, quantity=i.quantity, unit_price=i.unit_price, gst_rate=i.gst_rate
        )
        for i in payload.items
    ]


    customer_name = None
    customer_id = None
    if payload.customer_phone:
        customer = (
            db.query(CustomerRecord)
            .filter(CustomerRecord.phone_hash == _hash_phone(payload.customer_phone))
            .first()
        )
        if customer:
            customer_name = customer.name
            customer_id = customer.id


    pdf_path = gst_generator.generate_invoice_pdf(
        items, customer_name=customer_name, customer_phone=payload.customer_phone
    )


    # Extract just the filename from the full path
    pdf_filename = Path(pdf_path).name
    
    # Return the filename instead of full path - frontend will construct download URL
    return {
        "customer_id": customer_id,
        "customer_name": customer_name,
        "items": [
            {
                "id": i.id,
                "name": i.name,
                "quantity": i.quantity,
                "unit_price": i.unit_price,
                "gst_rate": i.gst_rate,
            }
            for i in items
        ],
        "pdf_path": pdf_filename,  # Just the filename, not full path
    }



# ---------------------------------------------------------------------
# 4. GET /api/v1/analytics/heatmap
# ---------------------------------------------------------------------


@app.get("/api/v1/analytics/heatmap")
def get_heatmap(days: int = 30, db: Session = Depends(get_db)):
    return analytics.compute_heatmap(db, days=days)



# ---------------------------------------------------------------------
# 5. GET /api/v1/transactions
# ---------------------------------------------------------------------


@app.get("/api/v1/transactions")
def list_transactions(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[str] = None,
    customer_id: Optional[str] = None,
    db: Session = Depends(get_db),
):
    query = db.query(TransactionRecord)
    if start_date:
        query = query.filter(TransactionRecord.timestamp >= start_date)
    if end_date:
        query = query.filter(TransactionRecord.timestamp <= end_date)
    if category:
        query = query.filter(TransactionRecord.category == category)
    if customer_id:
        query = query.filter(TransactionRecord.customer_id == customer_id)


    records = query.order_by(TransactionRecord.timestamp.desc()).all()
    return [transaction_pipeline.transaction_to_dict(r) for r in records]



# ---------------------------------------------------------------------
# 6. POST /api/v1/customers/verify
# ---------------------------------------------------------------------


@app.post("/api/v1/customers/verify")
def verify_customer(payload: VerifyCustomerRequest, db: Session = Depends(get_db)):
    phone_hash = _hash_phone(payload.phone_number)
    customer = db.query(CustomerRecord).filter(CustomerRecord.id == payload.customer_id).first()


    if customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")


    customer.is_verified = customer.phone_hash == phone_hash
    db.commit()
    db.refresh(customer)


    return {
        "id": customer.id,
        "name": customer.name,
        "phone_hash": customer.phone_hash,
        "is_verified": customer.is_verified,
    }


# ---------------------------------------------------------------------
# 7. POST /api/v1/tax-assistant/query
# ---------------------------------------------------------------------


@app.post("/api/v1/tax-assistant/query")
def query_tax_assistant(payload: TaxAssistantRequest, db: Session = Depends(get_db)):
    """Voice-First Tax Assistant - Answers natural language financial queries."""
    response = tax_assistant.process_tax_query(db, query=payload.query)
    return {"answer": response}


# ---------------------------------------------------------------------
# NEW: PDF Download Endpoint
# ---------------------------------------------------------------------


@app.get("/api/v1/invoices/{filename}")
async def download_invoice(filename: str):
    """Download generated invoice PDF"""
    file_path = settings.invoices_dir / filename
    if file_path.exists():
        return FileResponse(str(file_path), media_type="application/pdf", filename=filename)
    raise HTTPException(status_code=404, detail="Invoice not found")



def _hash_phone(phone_number: str) -> str:
    """Never store or compare raw phone numbers — matches the privacy
    design already committed to on the frontend (Customer.phoneHash)."""
    import hashlib


    return hashlib.sha256(phone_number.encode("utf-8")).hexdigest()



if __name__ == "__main__":
    import uvicorn


    uvicorn.run("main:app", host=settings.host, port=settings.port, reload=True)