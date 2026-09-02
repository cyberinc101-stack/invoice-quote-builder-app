// doc_completion_bar.dart
// lib/widgets/saved_documents/cards/doc_completion_bar.dart
//
// Split out of the former doc_cards.dart — see doc_card_list.dart's header
// comment for the full rationale. _CompletionProgressBar is used by the
// List and Logo Banner layouts (doc_card_list.dart) under the metadata
// rows. Unchanged in behaviour from the previous pass — no style drift
// was found here, since this widget already had its own fixed palette
// (_trackColor/_fillColor) independent of any per-layout values.

part of '../saved_documents_section.dart';

class _CompletionProgressBar extends StatelessWidget {
  final int percent;
  final String? typeLabel;
  final Color? typeColor;
  const _CompletionProgressBar({required this.percent, this.typeLabel, this.typeColor});

  static const Color _trackColor = Color(0xFFE8EAED);
  static const Color _fillColor = Color(0xFF43A047);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clamped = percent.clamp(0, 100);
    final hasBadge = typeLabel != null && typeLabel!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (hasBadge) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (typeColor ?? cs.primary).withValues(alpha: kDocChipAlpha + 0.02),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: typeColor ?? cs.primary,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              'Completion',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const Spacer(),
            Text(
              '$clamped%',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped / 100,
            backgroundColor: _trackColor,
            valueColor: const AlwaysStoppedAnimation<Color>(_fillColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
