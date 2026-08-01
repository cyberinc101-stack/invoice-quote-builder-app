// executive_cv_logic_data.dart
// lib/invoice_layout_templates/01_executive_cv_layout/executive_cv_logic_data.dart
//
// Filename kept consistent with the CV app's naming for parity across the
// two codebases. Unlike the CV version, there's no pagination here —
// invoices are always a single page. This file's only job is: render
// InvoiceExecutiveContent off-screen, measure its natural height, and
// apply a uniform Transform.scale so it always fits within one page.
//
// If invoices ever routinely need multiple pages (e.g. 30+ line items
// shrinking illegibly), that's the signal to port over the CV app's
// smart_layout pagination logic instead of scaling further.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../models/invoice_data.dart';
import 'executive_page_stationary_layout.dart';

/// Floor so text never scales down past legibility. If content still
/// doesn't fit at this scale, it will clip rather than shrink further.
const double kMinInvoiceScale = 0.72;

class ExecutiveInvoicePreview extends StatefulWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  const ExecutiveInvoicePreview({super.key, required this.data, this.onPageCount});

  @override
  State<ExecutiveInvoicePreview> createState() => _ExecutiveInvoicePreviewState();
}

class _ExecutiveInvoicePreviewState extends State<ExecutiveInvoicePreview> {
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
  void didUpdateWidget(ExecutiveInvoicePreview old) {
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
        ? (availableH / naturalH).clamp(kMinInvoiceScale, 1.0)
        : 1.0;

    if ((needed - _scale).abs() > 0.001) {
      setState(() => _scale = needed);
    }
    widget.onPageCount?.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final ac = invoiceAccent(widget.data);

    // OverflowBox lets the content lay out at its true natural height with
    // no RenderFlex overflow warnings, exactly like the CV smart layout's
    // main-column measuring approach — just applied to the whole page here.
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
          child: InvoiceExecutiveContent(data: widget.data, accent: ac),
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