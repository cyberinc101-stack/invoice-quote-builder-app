// executive_receipt_logic_data.dart
// lib/document_layout_templates/01_executive/executive_receipt_logic_data.dart
//
// Mirrors document_layout_templates/01_executive/executive_invoice_logic_data.dart
// and document_layout_templates/01_executive/executive_quote_logic_data.dart
// exactly. No pagination — receipts are always a single page, same as
// invoices and quotes. This file's only job is: render
// ReceiptExecutiveContent off-screen, measure its natural height, and
// apply a uniform Transform.scale so it always fits within one page.
//
// If receipts ever routinely need multiple pages, that's the signal to
// port over the CV app's smart_layout pagination logic instead of scaling
// further — same note as the invoice and quote versions.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../models/receipt_data.dart';
import 'executive_receipt_stationary_layout.dart';

/// Floor so text never scales down past legibility. If content still
/// doesn't fit at this scale, it will clip rather than shrink further.
const double kMinReceiptScale = 0.72;

class ExecutiveReceiptPreview extends StatefulWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveReceiptPreview({super.key, required this.data, this.onPageCount});

  @override
  State<ExecutiveReceiptPreview> createState() => _ExecutiveReceiptPreviewState();
}

class _ExecutiveReceiptPreviewState extends State<ExecutiveReceiptPreview> {
  final GlobalKey _contentKey = GlobalKey();
  double _scale = 1.0;
  int    _retryCount = 0;
  static const _kMaxRetries = 20;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(ExecutiveReceiptPreview old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _retryCount = 0;
      SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (!mounted) return;
    final rb = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || !rb.hasSize) {
      if (_retryCount++ < _kMaxRetries) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
      }
      return;
    }
    final naturalH   = rb.size.height;
    final availableH = kPageH - kPagePadV * 2;
    if (naturalH <= 0) return;

    final needed = naturalH > availableH
        ? (availableH / naturalH).clamp(kMinReceiptScale, 1.0)
        : 1.0;

    if ((needed - _scale).abs() > 0.001) {
      setState(() => _scale = needed);
    }
    widget.onPageCount?.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final ac = receiptAccent(widget.data);

    // OverflowBox lets the content lay out at its true natural height with
    // no RenderFlex overflow warnings — same approach as the invoice and
    // quote versions' main-column measuring.
    final scaledContent = OverflowBox(
      alignment: Alignment.topCenter,
      minWidth: kContentW, maxWidth: kContentW,
      minHeight: 0, maxHeight: double.infinity,
      child: Transform.scale(
        scale: _scale,
        alignment: Alignment.topCenter,
        child: SizedBox(
          key: _contentKey,
          width: kContentW,
          child: ReceiptExecutiveContent(data: widget.data, accent: ac),
        ),
      ),
    );

    return SizedBox(
      width: kPageW,
      height: kPageH,
      child: Material(
        color: Colors.white,
        elevation: 2,
        child: ClipRect(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPagePadH, vertical: kPagePadV),
            child: scaledContent,
          ),
        ),
      ),
    );
  }
}
