// customise_shared_widgets.dart
// lib/screens/invoice_create_section/step_customize/customise_shared_widgets.dart
//
// FILE-SPLIT PASS: pulled out of the former monolithic step_customise.dart.
// Holds the small, generic building blocks every other Customise section
// file needs: the collapsible SectionCard shell, the plain (non-collapsible)
// section header row, and the InvoiceColor -> Color mapping helper. Nothing
// in here is specific to any one section (logo/background/fields/etc) —
// that's what makes it shared rather than living in one of those files.
//
// Renamed from their original private (`_`) names so they're importable
// from sibling files in this folder: _SectionCard -> SectionCard,
// _plainSectionHeader -> plainSectionHeader, _colorForScheme ->
// colorForScheme. Behavior is unchanged from the original monolithic file.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/invoice_data.dart' show InvoiceColor;

Color colorForScheme(InvoiceColor scheme) {
  const map = {
    InvoiceColor.blue:   Color(0xFF1565C0),
    InvoiceColor.green:  Color(0xFF2E7D32),
    InvoiceColor.purple: Color(0xFF6A1B9A),
    InvoiceColor.orange: Color(0xFFE65100),
    InvoiceColor.red:    Color(0xFFC62828),
    InvoiceColor.teal:   Color(0xFF00695C),
    InvoiceColor.black:  Color(0xFF212121),
    InvoiceColor.indigo: Color(0xFF283593),
  };
  return map[scheme] ?? const Color(0xFF1565C0);
}

Widget plainSectionHeader(
  BuildContext context,
  String label,
  Color accent, {
  IconData? icon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration:
              BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        if (icon != null) ...[
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// Reusable section card
//
// COLLAPSIBLE SECTIONS PASS (earlier): SectionCard supports an optional
// `sectionKey`. When provided, the header row becomes tappable and shows
// an up/down chevron on the right (mirroring the arrow used by
// step_templates.dart's _CollapsibleGroup) — tapping it (or the header
// itself) expands/collapses the card's body, and the state is persisted
// per sectionKey via SharedPreferences so it's remembered next time this
// screen opens, independent of every other collapsible card here.
//
// Omitting sectionKey keeps the card exactly as it was before that pass:
// always expanded, no chevron, no persistence.
// =============================================================================

const _kCustomiseSectionExpandedPrefPrefix = 'invoice_customise_section_expanded_';

class SectionCard extends StatefulWidget {
  final IconData icon;
  final String   title;
  final Widget   child;
  final String?  sectionKey;
  final bool     initiallyExpanded;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.sectionKey,
    this.initiallyExpanded = true,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool _expanded = true;

  bool get _collapsible => widget.sectionKey != null;
  String get _prefKey => '$_kCustomiseSectionExpandedPrefPrefix${widget.sectionKey}';

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    if (_collapsible) _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getBool(_prefKey);
    if (persisted == null || !mounted) return;
    setState(() => _expanded = persisted);
  }

  Future<void> _setExpanded(bool v) async {
    setState(() => _expanded = v);
    if (!_collapsible) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, v);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final showChild = !_collapsible || _expanded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _collapsible ? () => _setExpanded(!_expanded) : null,
            child: Row(
              children: [
                Icon(widget.icon, size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.55)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface)),
                ),
                if (_collapsible)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
              ],
            ),
          ),
          if (showChild) ...[
            const SizedBox(height: 12),
            widget.child,
          ],
        ],
      ),
    );
  }
}
