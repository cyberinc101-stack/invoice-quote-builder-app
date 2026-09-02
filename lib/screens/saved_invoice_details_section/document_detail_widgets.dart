import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Stat card used in the stats row
//
// FORMAL REDESIGN: dropped the tinted gradient background, colored top
// rule, and gradient icon badge — those read as consumer-app decoration
// rather than a financial-document metric. Now a plain neutral card
// (hairline border, no color wash) with a small gray outline icon. The
// number itself carries the weight; iconColor is kept as a parameter for
// call-site compatibility but is no longer used to tint the card.
//
// BUGFIX (this pass): call sites in saved_document_detail_screen.dart
// were already passing `neutralAccent: kHeroGradient[0]`, but this class
// never declared that parameter — that's what broke the build
// ("No named parameter with the name 'neutralAccent'"). Added below, and
// used to tint the hairline border with the app's own navy instead of a
// flat unrelated gray.
// ---------------------------------------------------------------------------
class DetailStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  /// The app's own navy (kHeroGradient[0]) — tints the card's hairline
  /// border so it reads as this app's brand color rather than generic gray.
  final Color neutralAccent;

  const DetailStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.neutralAccent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = neutralAccent.withValues(alpha: isDark ? 0.28 : 0.16);
    final mutedIconColor = colorScheme.onSurface.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: mutedIconColor),
              const Spacer(),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: colorScheme.onSurface.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section heading label
//
// FORMALIZED: uppercase + wider letter-spacing, smaller/lighter weight —
// reads as a document section header (INVOICE / LINE ITEMS style) rather
// than an app-UI heading.
// ---------------------------------------------------------------------------
class DetailSectionLabel extends StatelessWidget {
  final String label;

  const DetailSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        letterSpacing: 1.0,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity row (icon + label + value)
// ---------------------------------------------------------------------------
class DetailActivityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const DetailActivityRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Line item row (description / qty / unit price / total)
// ---------------------------------------------------------------------------
class DetailLineItemRow extends StatelessWidget {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;
  final String currency;
  final bool striped;

  const DetailLineItemRow({
    super.key,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.currency,
    this.striped = false,
  });

  String _qty() =>
      quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: striped
          ? (isDark ? Colors.white.withValues(alpha: 0.025) : const Color(0xFFFAFAFB))
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              description.isEmpty ? '(No description)' : description,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_qty()} × $currency ${unitPrice.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              '$currency ${total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar action button (wide)
//
// FORMALIZED: dropped the saturated colored drop-shadow (read as a
// playful consumer-app "glow") for a plain neutral shadow — the button's
// own fill color still carries the accent, it just no longer casts
// colored light.
// ---------------------------------------------------------------------------
class DetailActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const DetailActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar icon-only button
// ---------------------------------------------------------------------------
class DetailIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const DetailIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Options bottom sheet row
// ---------------------------------------------------------------------------
class DetailSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const DetailSheetOption({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
