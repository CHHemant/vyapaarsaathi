import 'dart:ui';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/invoice.dart';

class PaymentSlipService {
  Future<String> createPaidSlip({
    required Invoice invoice,
    required DateTime paidAt,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/payment_slips');
    await directory.create(recursive: true);

    final number = invoice.invoiceNumber ?? 'invoice';
    final safe = number.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${directory.path}/$safe-paid.pdf');

    final document = PdfDocument();
    try {
      final page = document.pages.add();
      final size = page.getClientSize();

      final title = PdfStandardFont(
        PdfFontFamily.helvetica,
        22,
        style: PdfFontStyle.bold,
      );
      final heading = PdfStandardFont(
        PdfFontFamily.helvetica,
        11,
        style: PdfFontStyle.bold,
      );
      final body = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final small = PdfStandardFont(PdfFontFamily.helvetica, 8);

      page.graphics.drawString(
        'VYAPAARSAATHI',
        title,
        bounds: Rect.fromLTWH(24, 24, size.width - 48, 30),
      );
      page.graphics.drawString(
        'PAYMENT RECEIPT',
        heading,
        brush: PdfBrushes.darkGray,
        bounds: Rect.fromLTWH(24, 58, size.width - 48, 20),
      );
      page.graphics.drawLine(
        PdfPen(PdfColor(210, 210, 210)),
        Offset(24, 88),
        Offset(size.width - 24, 88),
      );

      double y = 105;

      void line(String label, String value, {bool bold = false}) {
        page.graphics.drawString(
          label,
          small,
          brush: PdfBrushes.darkGray,
          bounds: Rect.fromLTWH(24, y, 140, 18),
        );
        page.graphics.drawString(
          value,
          bold ? heading : body,
          bounds: Rect.fromLTWH(164, y, size.width - 188, 22),
        );
        y += 27;
      }

      line('Invoice number', number);
      line('Customer', invoice.customerName ?? 'Customer');
      line('GSTIN', invoice.customerId ?? 'N/A');
      line('Paid on', paidAt.toLocal().toString().substring(0, 19));

      y += 8;
      page.graphics.drawString(
        'ITEMS',
        heading,
        bounds: Rect.fromLTWH(24, y, size.width - 48, 20),
      );
      y += 27;

      for (final item in invoice.items) {
        page.graphics.drawString(
          item.name,
          body,
          bounds: Rect.fromLTWH(24, y, size.width - 190, 20),
        );
        page.graphics.drawString(
          'Rs ${item.lineTotal.toStringAsFixed(2)}',
          body,
          bounds: Rect.fromLTWH(size.width - 165, y, 140, 20),
        );
        y += 22;
      }

      y += 8;
      page.graphics.drawLine(
        PdfPen(PdfColor(210, 210, 210)),
        Offset(24, y),
        Offset(size.width - 24, y),
      );
      y += 14;

      line('Taxable value', 'Rs ${invoice.subtotal.toStringAsFixed(2)}');
      line('GST', 'Rs ${invoice.gstTotal.toStringAsFixed(2)}');
      line(
        'Amount paid',
        'Rs ${invoice.grandTotal.toStringAsFixed(2)}',
        bold: true,
      );

      y += 18;
      page.graphics.drawString(
        'PAYMENT COMPLETED',
        heading,
        brush: PdfSolidBrush(PdfColor(25, 120, 70)),
        bounds: Rect.fromLTWH(24, y, size.width - 48, 22),
      );
      y += 26;
      page.graphics.drawString(
        'Stored locally on this device for offline access.',
        small,
        brush: PdfBrushes.darkGray,
        bounds: Rect.fromLTWH(24, y, size.width - 48, 20),
      );

      await file.writeAsBytes(await document.save());
    } finally {
      document.dispose();
    }

    return file.path;
  }
}
