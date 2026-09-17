// customise_fields_section.dart
// lib/screens/invoice_create_section/step_customize/customise_fields_section.dart
//
// FILE-SPLIT PASS: pulled out of the former monolithic step_customise.dart
// (was `_FieldsSection`, `_FieldToggleSpec`, `_FieldGroupSpec`, and the
// signature-font constant list — now `FieldsSection`, `FieldToggleSpec`,
// `FieldGroupSpec`, `kSignatureFonts`). Behavior unchanged from the
// original file.
//
// BUSINESS NAME TOGGLE PASS (earlier): adds a "Business Name" entry
// to the Header & Meta group, right alongside Business Logo. Wires
// straight into the generic enabledFields['businessName'] map — no
// special handling needed here since doc_header.dart's
// buildSharedHeaderIdentity() already reads docFieldOn(a,
// 'businessName') to decide whether to render the business name text
// in the header; that check previously had no UI hooked up to it at
// all. This is what makes the free-header-logo idea (drag/enlarge the
// logo across the header once both the business name and tagline are
// hidden) possible in the first place — see customise_logo_section.dart's
// "Position in Header" control.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/invoice_provider.dart';
import '../../../models/invoice_data.dart';
import 'customise_shared_widgets.dart';

const List<String> kSignatureFonts = [
  'Dancing Script',
  'Great Vibes',
  'Sacramento',
  'Pacifico',
  'Alex Brush',
  'Caveat',
];

class FieldToggleSpec {
  final String key;
  final String label;
  final IconData icon;
  const FieldToggleSpec(this.key, this.label, this.icon);
}

class FieldGroupSpec {
  final String label;
  final IconData icon;
  final List<FieldToggleSpec> fields;
  const FieldGroupSpec(this.label, this.icon, this.fields);
}

const _kFieldGroups = <FieldGroupSpec>[
  FieldGroupSpec('Header & Meta', Icons.tag_rounded, [
    FieldToggleSpec('invoiceNumber', 'Invoice Number', Icons.tag_rounded),
    FieldToggleSpec('date', 'Issue Date', Icons.calendar_today_rounded),
    FieldToggleSpec('dueDate', 'Due Date', Icons.event_rounded),
    FieldToggleSpec('businessName', 'Business Name', Icons.badge_outlined),
    FieldToggleSpec('businessLogo', 'Business Logo', Icons.image_rounded),
    FieldToggleSpec('businessTaglineEnabled', 'Business Tagline', Icons.short_text_rounded),
    FieldToggleSpec('footerTaglinesEnabled', 'Footer Taglines', Icons.share_rounded),
  ]),
  FieldGroupSpec('Billed To', Icons.person_rounded, [
    FieldToggleSpec('customerName', 'Customer Name', Icons.person_outline_rounded),
    FieldToggleSpec('customerEmail', 'Customer Email', Icons.email_rounded),
    FieldToggleSpec('customerPhone', 'Customer Phone', Icons.phone_rounded),
    FieldToggleSpec('customerAddress', 'Customer Address', Icons.location_on_rounded),
  ]),
  FieldGroupSpec('Invoice Details', Icons.receipt_long_rounded, [
    FieldToggleSpec('tax', 'Tax', Icons.percent_rounded),
    FieldToggleSpec('discount', 'Discount', Icons.local_offer_rounded),
    FieldToggleSpec('dueDateSummary', 'Due Date (Totals)', Icons.event_available_rounded),
    FieldToggleSpec('amountDue', 'Amount Due (Totals)', Icons.payments_rounded),
  ]),
  FieldGroupSpec('Payment Info', Icons.account_balance_rounded, [
    FieldToggleSpec('bankName', 'Bank Name', Icons.account_balance_rounded),
    FieldToggleSpec('accountName', 'Account Name', Icons.badge_outlined),
    FieldToggleSpec('accountNumber', 'Account Number', Icons.pin_rounded),
    FieldToggleSpec('otherPaymentDetails', 'Other Payment Details', Icons.notes_outlined),
    FieldToggleSpec('poNumber', 'PO / Reference Number', Icons.confirmation_number_outlined),
  ]),
  FieldGroupSpec('Terms & Signature', Icons.gavel_rounded, [
    FieldToggleSpec('termsAndConditions', 'Terms & Conditions', Icons.gavel_rounded),
    FieldToggleSpec('signature', 'Signature', Icons.draw_outlined),
  ]),
  FieldGroupSpec('Notes & Thank You', Icons.notes_rounded, [
    FieldToggleSpec('notes', 'Notes', Icons.notes_rounded),
    FieldToggleSpec('thankYouMessage', 'Thank You Message', Icons.favorite_border_rounded),
  ]),
];

const _kFieldGroupExpandedPrefPrefix = 'invoice_customise_field_group_expanded_';

bool? _specialFieldValue(InvoiceData data, String key) => switch (key) {
      'businessTaglineEnabled' => data.businessTaglineEnabled,
      'footerTaglinesEnabled' => data.footerTaglinesEnabled,
      _ => null,
    };

bool _setSpecialField(InvoiceProvider provider, String key, bool v) {
  switch (key) {
    case 'businessTaglineEnabled':
      provider.updateBusinessTaglineEnabled(v);
      return true;
    case 'footerTaglinesEnabled':
      provider.updateFooterTaglinesEnabled(v);
      return true;
    default:
      return false;
  }
}

class FieldsSection extends StatefulWidget {
  const FieldsSection({super.key});

  @override
  State<FieldsSection> createState() => _FieldsSectionState();
}

class _FieldsSectionState extends State<FieldsSection> {
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadPersistedExpand();
  }

  Future<void> _loadPersistedExpand() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, bool>{};
    for (final g in _kFieldGroups) {
      loaded[g.label] = prefs.getBool('$_kFieldGroupExpandedPrefPrefix${g.label}') ?? false;
    }
    if (!mounted) return;
    setState(() => _expanded.addAll(loaded));
  }

  Future<void> _persistExpand(String groupLabel, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kFieldGroupExpandedPrefPrefix$groupLabel', value);
  }

  bool _fieldValue(InvoiceData data, String key) =>
      _specialFieldValue(data, key) ?? (data.enabledFields[key] ?? true);

  bool _groupIsOn(InvoiceData data, FieldGroupSpec group) {
    return group.fields.every((f) => _fieldValue(data, f.key));
  }

  void _toggleGroup(InvoiceProvider provider, FieldGroupSpec group, bool v) {
    final updated = Map<String, bool>.from(provider.invoiceData.enabledFields);
    for (final f in group.fields) {
      if (_setSpecialField(provider, f.key, v)) continue;
      updated[f.key] = v;
    }
    provider.updateEnabledFields(updated);
    setState(() => _expanded[group.label] = v);
    _persistExpand(group.label, v);
  }

  void _setExpanded(String groupLabel, bool v) {
    setState(() => _expanded[groupLabel] = v);
    _persistExpand(groupLabel, v);
  }

  Widget _fieldRow(BuildContext context, InvoiceProvider provider, FieldToggleSpec f) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = colorForScheme(provider.invoiceData.colorScheme);
    final value = _fieldValue(provider.invoiceData, f.key);
    final isSignatureRow = f.key == 'signature';
    final sigSize = provider.invoiceData.signatureFontSize;
    final sigFamily = provider.invoiceData.signatureFontFamily;
    // TAGLINE SIZE PASS: footer taglines get their own size slider,
    // same "extra UI beneath the switch, only while it's on" pattern
    // the signature row already uses. Range 6-12pt matches the clamp
    // doc_footer.dart applies at render time, so the slider itself
    // never lets the user pick a value bigger than what the footer
    // band can actually show — combined with autoFitText's own
    // shrink-to-fit, this is what keeps taglines from overflowing the
    // footer even at max size with 6 items sharing the row.
    final isFooterTaglinesRow = f.key == 'footerTaglinesEnabled';
    final taglineSize = provider.invoiceData.footerTaglinesFontSize;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(9),
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : const Color(0xFFFAFAFA),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            visualDensity: VisualDensity.compact,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(f.icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.label,
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            value: value,
            activeThumbColor: accent,
            onChanged: (v) {
              if (_setSpecialField(provider, f.key, v)) return;
              final updated = Map<String, bool>.from(provider.invoiceData.enabledFields);
              updated[f.key] = v;
              provider.updateEnabledFields(updated);
            },
          ),
          if (isSignatureRow && value) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  Icon(Icons.format_size_rounded, size: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Text('Size', style: TextStyle(fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.55))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        inactiveTrackColor: accent.withValues(alpha: 0.2),
                        thumbColor: accent,
                        overlayColor: accent.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: sigSize,
                        min: 14,
                        max: 36,
                        divisions: 11,
                        onChanged: (v) => provider.updateSignatureFontSize(v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('${sigSize.toInt()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kSignatureFonts.map((font) {
                  final active = sigFamily == font;
                  return GestureDetector(
                    onTap: () => provider.updateSignatureFontFamily(active ? '' : font),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? accent
                            : (isDark
                                ? colorScheme.surfaceContainerHighest
                                : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? accent : colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        font,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 13,
                          color: active ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (isFooterTaglinesRow && value) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.format_size_rounded, size: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Text('Size', style: TextStyle(fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.55))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        inactiveTrackColor: accent.withValues(alpha: 0.2),
                        thumbColor: accent,
                        overlayColor: accent.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: taglineSize.clamp(6.0, 12.0),
                        min: 6,
                        max: 12,
                        divisions: 6,
                        onChanged: (v) => provider.updateFooterTaglinesFontSize(v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('${taglineSize.toInt()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupCard(BuildContext context, InvoiceProvider provider, FieldGroupSpec group) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = colorForScheme(provider.invoiceData.colorScheme);
    final data = provider.invoiceData;
    final groupOn = _groupIsOn(data, group);
    final isExpanded = _expanded[group.label] ?? false;
    final onCount = group.fields.where((f) => _fieldValue(data, f.key)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF23233A) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            onTap: () => _setExpanded(group.label, !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(group.icon, size: 17,
                      color: groupOn ? accent : colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$onCount/${group.fields.length}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: groupOn,
                    activeThumbColor: accent,
                    onChanged: (v) => _toggleGroup(provider, group, v),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [for (final f in group.fields) _fieldRow(context, provider, f)],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return SectionCard(
      icon: Icons.tune_rounded,
      title: 'Invoice Fields',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flip a group on/off, or tap it to expand and fine-tune individual fields.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 10),
          for (final g in _kFieldGroups) _groupCard(context, provider, g),
        ],
      ),
    );
  }
}
