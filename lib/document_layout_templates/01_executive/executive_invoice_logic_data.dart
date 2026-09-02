// executive_invoice_logic_data.dart
// lib/document_layout_templates/01_executive/executive_invoice_logic_data.dart
//
// REWRITE: previously measured content height off-screen and applied a
// single Transform.scale to force everything onto one page — real
// overflow just clipped. This version delegates entirely to A4Paginator:
// line items are handed over as a flat widget list, and the paginator
// measures real rendered heights and splits them across as many A4 pages
// as needed, matching how invoice_pdf_service.dart's pw.MultiPage already
// paginates the exported PDF.
//
// Two public entry points, same underlying document:
//   ExecutiveInvoicePreview — read-only (edit bundle is null)
//   ExecutiveInvoiceEditor  — WYSIWYG editable (edit bundle required)

import 'package:flutter/material.dart';
import '../../../models/invoice_data.dart';
import '../pagination/a4_paginator.dart';
import 'executive_invoice_stationary_layout.dart';

class ExecutiveInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  Widget build(BuildContext context) {
    return _ExecutiveInvoiceDocument(data: data, edit: null, onPageCount: onPageCount);
  }
}

class ExecutiveInvoiceEditor extends StatelessWidget {
  final InvoiceData data;
  final InvoiceEditBundle edit;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveInvoiceEditor({super.key, required this.data, required this.edit, this.onPageCount});

  @override
  Widget build(BuildContext context) {
    return _ExecutiveInvoiceDocument(data: data, edit: edit, onPageCount: onPageCount);
  }
}

class _ExecutiveInvoiceDocument extends StatelessWidget {
  final InvoiceData data;
  final InvoiceEditBundle? edit;
  final void Function(int pageCount)? onPageCount;
  const _ExecutiveInvoiceDocument({required this.data, required this.edit, required this.onPageCount});

  @override
  Widget build(BuildContext context) {
    final accent = invoiceAccent(data);
    final ff = data.fontFamily;

    final items = <Widget>[
      for (int i = 0; i < data.lineItems.length; i++)
        buildLineItemRow(
          item: data.lineItems[i],
          index: i,
          currency: data.currency,
          ff: ff,
          edit: edit,
        ),
    ];

    return A4Paginator(
      pageWidth: kPageW,
      pageHeight: kPageH,
      contentWidth: kContentW,
      pagePadding: const EdgeInsets.symmetric(horizontal: kPagePadH, vertical: kPagePadV),
      items: items,
      onPageCount: onPageCount,
      headerBuilder: (pageIndex, pageCount) => pageIndex == 0
          ? buildFullHeader(data: data, accent: accent, ff: ff, edit: edit)
          : buildContinuationHeader(data: data, accent: accent, ff: ff),
      footerBuilder: (pageIndex, pageCount) => pageIndex == pageCount - 1
          ? buildFooterSection(data: data, accent: accent, ff: ff, edit: edit)
          : const SizedBox.shrink(),
    );
  }
}
