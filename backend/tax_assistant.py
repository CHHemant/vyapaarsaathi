# backend/tax_assistant.py
#
# Voice-First Tax Assistant logic. This module integrates the SLM (Phi-3 Mini)
# to answer natural language queries about financial status and tax risks.
# It uses a "Stats-to-Speech" approach:
# 1. Query the database for current financial totals (UPI/Cash/Total).
# 2. Construct a prompt with these facts for the Phi-3 model.
# 3. Generate a localized response (Hindi/Telugu/English).

import os
from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from database import TransactionRecord
from llama_cpp import Llama

# Path to the model file - User should place the GGUF file here
MODEL_PATH = os.environ.get("LLM_MODEL_PATH", "models/phi-3-mini-4k-instruct-q4.gguf")

_llm: Optional[Llama] = None

def get_llm():
    global _llm
    if _llm is None:
        if not os.path.exists(MODEL_PATH):
            print(f"⚠️ Model not found at {MODEL_PATH}. Tax Assistant will use fallback logic.")
            return None

        try:
            # Initialize with NPU/GPU support if available via specific build flags
            _llm = Llama(
                model_path=MODEL_PATH,
                n_ctx=2048,
                n_threads=4,  # Adjust based on Snapdragon core count
                verbose=False
            )
        except Exception as e:
            print(f"❌ Failed to load LLM: {e}")
            return None
    return _llm

def process_tax_query(db: Session, query: str) -> str:
    """Answers financial questions using DB context + SLM reasoning."""

    # 1. Gather context from DB
    now = datetime.now()
    start_of_month = datetime(now.year, now.month, 1)

    # Get total sales for the month
    month_transactions = db.query(TransactionRecord).filter(
        TransactionRecord.timestamp >= start_of_month,
        TransactionRecord.type == "income"
    ).all()

    total_upi = sum(t.amount for t in month_transactions if t.category != "cash")
    total_sales = sum(t.amount for t in month_transactions)

    # Heuristic for GST risk (e.g. crossing 20L threshold or high UPI volume)
    gst_risk = total_upi > 10000 # Example threshold from user request

    context = (
        f"Month: {now.strftime('%B %Y')}\n"
        f"Total UPI Received: ₹{total_upi:.2f}\n"
        f"Total Sales: ₹{total_sales:.2f}\n"
        f"GST Risk: {'High (GST notice risk)' if gst_risk else 'Low'}\n"
    )

    # 2. Query the LLM
    llm = get_llm()
    if llm:
        prompt = f"""
        <|system|>
        You are a helpful Financial Assistant for small shop owners in India.
        Answer the user's question accurately based on the provided financial context.
        Use a friendly, professional tone. If the query is in Hindi or Telugu, answer in the same language.

        Context:
        {context}
        <|user|>
        {query}
        <|assistant|>
        """

        try:
            response = llm(
                prompt,
                max_tokens=128,
                stop=["<|end|>"],
                echo=False
            )
            return response["choices"][0]["text"].strip()
        except Exception as e:
            print(f"LLM Inference Error: {e}")

    # 3. Fallback logic (Rule-based)
    query_lower = query.lower()

    # Basic intent matching for common questions
    if "10,000" in query_lower or "upi" in query_lower or "kitna" in query_lower:
        if "te" in query_lower or "chudu" in query_lower: # Telugu detection (very basic)
            risk_msg = "GST notice vacche avakasam undi." if gst_risk else "Risk ledu."
            return f"Avunu, ee mahine ₹{total_upi:.0f} UPI vacchindi. {risk_msg}"
        else: # Default to Hindi/English mix as requested
            risk_msg = "GST notice ka risk hai." if gst_risk else "Sab theek hai."
            return f"Haan, is mahine ₹{total_upi:.0f} UPI aaya. {risk_msg}"

    return f"Aapka total UPI collection ₹{total_upi:.0f} hai. Sab controlled hai."
