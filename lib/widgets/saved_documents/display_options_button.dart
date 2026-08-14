// display_options_button.dart
// lib/widgets/saved_documents/display_options_button.dart
//
// Small "tune" icon button that sits next to the existing layout-mode
// dropdown on every section header (Invoices/Quotes/Receipts on Home,
// Expenses, and the Reports document list). Opens a bottom sheet of
// switches bound directly to CardDisplayPrefs — flipping a switch here
// updates every card family immediately (they all watch the same
// provider instance) and persists across app restarts.
//
// CARD STYLE PASS (this update): added a "Card Style" segmented control
// (Standard / Logo Banner) above the existing field switches, bound to
// CardDisplayPrefs.cardStyle/setCardStyle. This is deliberately separate
// from the switchTile list below it — it changes the List card's overall
// shape (side-by-side vs. full-width banner), not just which fields are
// visible, so it gets its own distinct control rather than being another
// row in the switch list. Only affects the List layout; Grid/CompactGrid/
// Compact are unaffected regardless of which style is selected, so a
// one-line note under the segmented control clarifies that.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'card_display_prefs.dart';

class DisplayOptionsButton extends StatelessWidget {
  const DisplayOptionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Icon(Icons.tune_rounded, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DisplayOptionsSheet(),
    );
  }
}

class _DisplayOptionsSheet extends StatelessWidget {
  const _DisplayOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = context.watch<CardDisplayPrefs>();

    Widget switchTile({
      required String label,
      required IconData icon,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: cs.primary),
        title: Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        contentPadding: EdgeInsets.zero,
        activeThumbColor: cs.primary,
      );
    }

    Widget styleOption({
      required String label,
      required IconData icon,
      required CardStyle value,
    }) {
      final isSelected = prefs.cardStyle == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => prefs.setCardStyle(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.6)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Card Display Options',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Choose what shows on every saved card — applies everywhere.',
                  style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 18),

                Text(
                  'CARD STYLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    styleOption(
                      label: 'Standard',
                      icon: Icons.view_agenda_outlined,
                      value: CardStyle.standard,
                    ),
                    const SizedBox(width: 10),
                    styleOption(
                      label: 'Logo Banner',
                      icon: Icons.image_outlined,
                      value: CardStyle.logoBanner,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Logo Banner applies to List view only.',
                  style: TextStyle(fontSize: 10.5, color: cs.onSurface.withValues(alpha: 0.4)),
                ),

                const SizedBox(height: 10),
                Divider(color: cs.outline.withValues(alpha: 0.15)),
                const SizedBox(height: 4),

                switchTile(
                  label: 'Business Logo',
                  icon: Icons.image_rounded,
                  value: prefs.showLogo,
                  onChanged: prefs.setShowLogo,
                ),
                switchTile(
                  label: 'Amount',
                  icon: Icons.attach_money_rounded,
                  value: prefs.showAmount,
                  onChanged: prefs.setShowAmount,
                ),
                switchTile(
                  label: 'Due / Expiry / Paid Date',
                  icon: Icons.event_rounded,
                  value: prefs.showSecondaryDate,
                  onChanged: prefs.setShowSecondaryDate,
                ),
                switchTile(
                  label: 'Created Date & Item Count',
                  icon: Icons.add_circle_outline_rounded,
                  value: prefs.showCreatedAndItems,
                  onChanged: prefs.setShowCreatedAndItems,
                ),
                switchTile(
                  label: 'Progress Bar',
                  icon: Icons.linear_scale_rounded,
                  value: prefs.showProgress,
                  onChanged: prefs.setShowProgress,
                ),
                switchTile(
                  label: 'Status Chip',
                  icon: Icons.label_rounded,
                  value: prefs.showStatusChip,
                  onChanged: prefs.setShowStatusChip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
