// receipt_template_chooser_screen.dart
// lib/create_receipt/receipt_template_chooser_screen.dart
//
// CONVERT-FLOW PICKER PASS (this update): added an optional
// onTemplateChosen(templateId, paperFormat) callback. When set, _continue()
// hands the chosen template/paper-format straight back to that callback
// instead of navigating into CreateReceiptScreen — this lets
// SavedDocumentDetailScreen's "Convert to Receipt" action reuse this same
// A4-grid / Thermal picker as a lightweight size/design chooser for a
// conversion, without dragging the caller through the full receipt editor.
// _isEditingExisting / normal "new receipt" flows are unaffected — the
// callback branch is checked first and is a no-op unless explicitly wired.
//
// STYLING CONSISTENCY PASS (earlier): _ThermalReceiptPreview (the
// static chooser mockup) now uses the same TornEdgeClipper +
// borderless-shadow-card styling as ThermalReceiptLivePreview (the real
// data-bound preview used everywhere else), so the mockup you see before
// entering the editor matches what you'll actually get. Previously this
// widget had a plain black-bordered rectangle, which read as a generic
// card rather than a receipt printout.
//
// SINGLE THERMAL LAYOUT PASS (earlier): paper format is a single
// top-level control; A4 shows the 10-design grid, thermal shows this one
// fixed preview instead — thermal only has the one layout.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/receipt_provider.dart';
import '../widgets/template_full_preview_modal.dart';
import 'create_receipt_screen.dart';
import 'receipt_paper_format.dart';
import 'receipt_paper_format_picker.dart';
import 'receipt_step_template_chooser_registry.dart';
import 'receipt_template_chooser_01/preview_registry.dart';

const String _kLastReceiptTemplateKey = 'last_receipt_template_id';
const String _kLastReceiptPaperFormatKey = 'last_receipt_paper_format';

class ReceiptTemplateChooserScreen extends StatefulWidget {
  /// When set, this chooser is being opened to edit an EXISTING saved
  /// receipt rather than start a new one.
  final String? existingReceiptId;

  /// When set, "Save & Continue" hands the chosen (templateId, paperFormat)
  /// back to this callback instead of pushing into CreateReceiptScreen.
  /// The caller is responsible for popping this screen and navigating
  /// onward — used by the invoice→receipt conversion flow to reuse this
  /// picker as a plain size/design chooser.
  final void Function(int templateId, String paperFormat)? onTemplateChosen;

  const ReceiptTemplateChooserScreen({
    super.key,
    this.existingReceiptId,
    this.onTemplateChosen,
  });

  @override
  State<ReceiptTemplateChooserScreen> createState() => _ReceiptTemplateChooserScreenState();
}

class _ReceiptTemplateChooserScreenState extends State<ReceiptTemplateChooserScreen> {
  int? _selectedId;
  ReceiptPaperFormat _paperFormat = ReceiptPaperFormat.a4;

  bool get _isEditingExisting => widget.existingReceiptId != null;
  bool get _isThermal => _paperFormat.isThermal;

  @override
  void initState() {
    super.initState();
    _loadInitialSelection();
  }

  Future<void> _loadInitialSelection() async {
    if (_isEditingExisting) {
      final provider = context.read<ReceiptProvider>();
      final existing = provider.savedReceipts
          .where((r) => r.id == widget.existingReceiptId)
          .toList();
      if (existing.isNotEmpty && mounted) {
        setState(() {
          _selectedId = existing.first.data.layoutTemplateId;
          _paperFormat = receiptPaperFormatFromString(existing.first.data.paperFormat);
        });
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kLastReceiptTemplateKey);
    final savedFormat = prefs.getString(_kLastReceiptPaperFormatKey);
    if (mounted) {
      setState(() {
        if (saved != null) _selectedId = saved;
        if (savedFormat != null) _paperFormat = receiptPaperFormatFromString(savedFormat);
      });
    }
  }

  Future<void> _persistSelected() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedId != null) {
      await prefs.setInt(_kLastReceiptTemplateKey, _selectedId!);
    }
    await prefs.setString(_kLastReceiptPaperFormatKey, _paperFormat.storageName);
  }

  void _tapCard(ReceiptTemplateInfo info) {
    if (!info.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${info.name} is coming soon.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _selectedId = info.id);
  }

  void _changePaperFormat(ReceiptPaperFormat format) {
    setState(() => _paperFormat = format);
  }

  void _continue() {
    // Thermal has exactly one layout — no template selection needed.
    if (!_isThermal && _selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a template to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _persistSelected();

    // layoutTemplateId is irrelevant for thermal output — the PDF service
    // short-circuits straight to the single thermal layout regardless of
    // this value — so a placeholder (1) is fine when _selectedId is null.
    final templateId = _selectedId ?? 1;

    // Picker mode for the conversion flow: hand the choice back and let
    // the caller decide what happens next (it owns popping this screen).
    if (widget.onTemplateChosen != null) {
      widget.onTemplateChosen!(templateId, _paperFormat.storageName);
      return;
    }

    if (_isEditingExisting) {
      final provider = context.read<ReceiptProvider>();
      provider.loadSavedReceipt(widget.existingReceiptId!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreateReceiptScreen(
            layoutTemplateId: templateId,
            paperFormat: _paperFormat.storageName,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReceiptScreen(
          layoutTemplateId: templateId,
          paperFormat: _paperFormat.storageName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          _buildFormatSelector(context),
          Expanded(
            child: _isThermal ? _buildThermalPreview(context) : _buildTemplateGrid(context),
          ),
          _buildContinueBar(context),
        ],
      ),
    );
  }

  Widget _buildFormatSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paper Format',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          ReceiptPaperFormatPicker(
            selected: _paperFormat,
            accent: const Color(0xFF2E7D32),
            onChanged: _changePaperFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.66,
      ),
      itemCount: kReceiptTemplates.length,
      itemBuilder: (context, i) {
        final info = kReceiptTemplates[i];
        return _TemplateCard(
          info: info,
          selected: _selectedId == info.id,
          onTap: () => _tapCard(info),
          onLongPress: () => showGenericTemplateFullPreview(
            context,
            name: info.name,
            description: info.description,
            accentColor: info.accentColor,
            isPremium: info.isPremium,
            preview: buildReceiptPreview(info.id, sampleReceiptData()),
          ),
        );
      },
    );
  }

  Widget _buildThermalPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  'Thermal receipts use one standard professional layout',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ThermalReceiptPreview(widthMm: _paperFormat.widthMm),
          const SizedBox(height: 8),
          Text(
            'All fields (logo, cashier, tax ID, barcode/QR, and more) are customizable on the next step.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = _isThermal || _selectedId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      child: GestureDetector(
        onTap: _continue,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasSelection
                  ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                  : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: hasSelection
                ? const [BoxShadow(color: Color(0x504CAF50), blurRadius: 12, offset: Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: hasSelection ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Save & Continue',
                style: TextStyle(
                  color: hasSelection ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose a Design',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEditingExisting
                          ? 'Keep the current design or pick a new one'
                          : 'Pick a template and paper size to start your receipt',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fixed thermal receipt preview — static mock matching the professional POS
// layout ReceiptPdfService._buildThermalPdf actually produces, styled with
// the same torn-edge card as ThermalReceiptLivePreview (real data version
// shown later in the flow). Uses fixed sample values purely for
// illustration; real data is entered on the next screen.
// ─────────────────────────────────────────────────────────────────────────────

class _ThermalReceiptPreview extends StatelessWidget {
  final double widthMm;
  const _ThermalReceiptPreview({required this.widthMm});

  @override
  Widget build(BuildContext context) {
    // Roughly maps mm roll width to an on-screen px width for the mockup —
    // purely visual, not tied to the actual PDF's point-based sizing.
    final previewWidth = widthMm * 4.2;
    const mono = 'Courier';

    const boldBlack = TextStyle(
      fontFamily: mono,
      color: Colors.black,
      fontWeight: FontWeight.w700,
    );
    const regularBlack = TextStyle(
      fontFamily: mono,
      color: Colors.black,
      fontWeight: FontWeight.w600,
    );

    Widget dashedDivider() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const gapWidth = 3.0;
              final count = (constraints.maxWidth / (dashWidth + gapWidth)).floor();
              return Row(
                children: List.generate(
                  count,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: gapWidth),
                    child: Container(width: dashWidth, height: 1.4, color: Colors.black),
                  ),
                ),
              );
            },
          ),
        );

    Widget solidDivider() => Container(height: 1.4, color: Colors.black);

    Widget metaRow(String label, String value, {TextStyle style = regularBlack}) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: style.copyWith(fontSize: 10)),
              Text(value, style: style.copyWith(fontSize: 10)),
            ],
          ),
        );

    final content = Container(
      width: previewWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Icon(Icons.storefront_rounded, size: 30, color: Colors.black)),
          const SizedBox(height: 6),
          Text('YOUR BUSINESS', textAlign: TextAlign.center, style: boldBlack.copyWith(fontSize: 15)),
          const SizedBox(height: 3),
          Text('123 Main Street', textAlign: TextAlign.center, style: regularBlack.copyWith(fontSize: 10)),
          Text('Ph: 09 123 4567', textAlign: TextAlign.center, style: regularBlack.copyWith(fontSize: 10)),
          Text('Tax ID: 123-456-789', textAlign: TextAlign.center, style: regularBlack.copyWith(fontSize: 10)),
          dashedDivider(),

          Text('TAX INVOICE / RECEIPT', textAlign: TextAlign.center, style: boldBlack.copyWith(fontSize: 11)),
          const SizedBox(height: 8),

          metaRow('Receipt No:', '00012345'),
          metaRow('Date:', '18 Aug 2026'),
          metaRow('Cashier:', 'John'),
          metaRow('POS ID:', 'POS 01'),
          dashedDivider(),

          Row(
            children: [
              Expanded(flex: 5, child: Text('Item', style: boldBlack.copyWith(fontSize: 10))),
              Expanded(
                  flex: 2,
                  child: Text('Qty', textAlign: TextAlign.center, style: boldBlack.copyWith(fontSize: 10))),
              Expanded(
                  flex: 3,
                  child: Text('Price', textAlign: TextAlign.right, style: boldBlack.copyWith(fontSize: 10))),
            ],
          ),
          const SizedBox(height: 4),
          solidDivider(),
          const SizedBox(height: 6),
          ...const [
            ['Cappuccino', '1', '\$4.50'],
            ['Flat White', '1', '\$4.50'],
            ['Blueberry Muffin', '1', '\$3.50'],
          ].map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Text(row[0], style: regularBlack.copyWith(fontSize: 10))),
                    Expanded(
                        flex: 2,
                        child: Text(row[1], textAlign: TextAlign.center, style: regularBlack.copyWith(fontSize: 10))),
                    Expanded(
                        flex: 3,
                        child: Text(row[2], textAlign: TextAlign.right, style: regularBlack.copyWith(fontSize: 10))),
                  ],
                ),
              )),
          dashedDivider(),

          metaRow('Subtotal', '\$12.50'),
          metaRow('Tax (15%)', '\$1.88'),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: boldBlack.copyWith(fontSize: 13)),
                Text('\$14.38', style: boldBlack.copyWith(fontSize: 13)),
              ],
            ),
          ),
          dashedDivider(),

          Text('Payment Method:', style: boldBlack.copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          metaRow('Card', '\$14.38'),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: previewWidth * 0.62,
              height: 34,
              color: Colors.black,
              alignment: Alignment.center,
              child: const Text('|| ||| | |||| || | ||| |||',
                  style: TextStyle(fontFamily: mono, fontSize: 8, color: Colors.white, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 4),
          Text('00012345', textAlign: TextAlign.center, style: regularBlack.copyWith(fontSize: 9)),
          const SizedBox(height: 14),

          Text('Thank you for your purchase!', textAlign: TextAlign.center, style: boldBlack.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text('We hope to see you again.', textAlign: TextAlign.center, style: regularBlack.copyWith(fontSize: 9)),
        ],
      ),
    );

    return content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A4 grid card — unchanged, minus the per-card paper format picker (now a
// single top-level control above the grid).
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final ReceiptTemplateInfo info;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _TemplateCard({required this.info, required this.selected, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: selected
                    ? Border.all(color: info.accentColor, width: 2.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: info.accentColor.withValues(alpha: info.available ? (selected ? 0.35 : 0.22) : 0.08),
                    blurRadius: selected ? 16 : 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.white),
                    Opacity(
                      opacity: info.available ? 1.0 : 0.45,
                      child: ReceiptStepChooserScaledPreview(templateId: info.id),
                    ),
                    if (info.isPremium && info.available)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 11),
                              SizedBox(width: 3),
                              Text('PRO', style: TextStyle(
                                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    if (!info.available)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Coming Soon',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    if (selected && info.available)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: info.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                        ),
                      ),
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        height: 3,
                        color: info.accentColor.withValues(alpha: info.available ? 1 : 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  info.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: info.available
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected && info.available)
                Icon(Icons.radio_button_checked_rounded, size: 15, color: info.accentColor)
              else if (info.available)
                Icon(Icons.radio_button_off_rounded, size: 15, color: colorScheme.onSurface.withValues(alpha: 0.25)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            info.tag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: info.available
                  ? info.accentColor
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
