# backend/gst_generator.py
#
# Powers POST /gst/invoice. Generates a REAL PDF (via reportlab, not a
# stub/mock path) with an itemized table, GST breakdown, and total.
#
# HONESTY NOTE, connecting back to a gap flagged on the frontend side:
# credit_screen.dart's "Download Credit Report" button also calls this
# same endpoint (per the original spec, which has no dedicated
# report-generation endpoint) with a single dummy line item. The PDF
# that comes back for that call WILL look like an invoice — itemized
# table, GST columns — not a purpose-built credit report layout, because
# that's what this function actually renders. If a real credit-report
# layout is wanted, it needs its own function/endpoint, which is outside
# the given 6-endpoint contract.


from __future__ import annotations


import uuid
from dataclasses import dataclass


from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet


from config import settings



@dataclass
class InvoiceItemInput:
    id: str
    name: str
    quantity: float
    unit_price: float
    gst_rate: int  # 0, 5, 12, 18, or 28


    @property
    def line_subtotal(self) -> float:
        return self.quantity * self.unit_price


    @property
    def line_gst(self) -> float:
        return self.line_subtotal * self.gst_rate / 100


    @property
    def line_total(self) -> float:
        return self.line_subtotal + self.line_gst



def generate_invoice_pdf(
    items: list[InvoiceItemInput],
    customer_name: str | None,
    customer_phone: str | None,
) -> str:
    """Renders the PDF to disk and returns its absolute path. Path is a
    local filesystem path (not a URL) — see the ASSUMPTION note in the
    Flutter app's invoice_screen.dart, which this matches."""
    subtotal = sum(i.line_subtotal for i in items)
    gst_total = sum(i.line_gst for i in items)
    grand_total = subtotal + gst_total


    filename = f"invoice_{uuid.uuid4().hex[:10]}.pdf"
    path = settings.invoices_dir / filename


    doc = SimpleDocTemplate(str(path), pagesize=A4, topMargin=20 * mm, bottomMargin=20 * mm)
    styles = getSampleStyleSheet()
    story = []


    story.append(Paragraph("VyapaarSaathi", styles["Title"]))
    story.append(Paragraph(f"GSTIN: {settings.business_gstin_placeholder}", styles["Normal"]))
    story.append(Spacer(1, 12))


    story.append(Paragraph(f"Bill To: {customer_name or 'Walk-in Customer'}", styles["Normal"]))
    if customer_phone:
        story.append(Paragraph(f"Phone: {customer_phone}", styles["Normal"]))
    story.append(Spacer(1, 16))


    table_data = [["Item", "Qty", "Unit Price (Rs.)", "GST %", "Line Total (Rs.)"]]
    for item in items:
        table_data.append([
            item.name,
            f"{item.quantity:g}",
            f"{item.unit_price:.2f}",
            f"{item.gst_rate}%",
            f"{item.line_total:.2f}",
        ])


    item_table = Table(table_data, colWidths=[70 * mm, 20 * mm, 30 * mm, 20 * mm, 30 * mm])
    item_table.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#FF9933")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("ALIGN", (1, 0), (-1, -1), "RIGHT"),
            ("BOTTOMPADDING", (0, 0), (-1, 0), 8),
            ("TOPPADDING", (0, 0), (-1, 0), 8),
        ])
    )
    story.append(item_table)
    story.append(Spacer(1, 16))


    summary_data = [
        ["Subtotal", f"Rs. {subtotal:.2f}"],
        ["GST", f"Rs. {gst_total:.2f}"],
        ["Total", f"Rs. {grand_total:.2f}"],
    ]
    summary_table = Table(summary_data, colWidths=[140 * mm, 30 * mm])
    summary_table.setStyle(
        TableStyle([
            ("ALIGN", (1, 0), (1, -1), "RIGHT"),
            ("FONTNAME", (0, 2), (-1, 2), "Helvetica-Bold"),
            ("LINEABOVE", (0, 2), (-1, 2), 1, colors.black),
        ])
    )
    story.append(summary_table)


    doc.build(story)
    return str(path)