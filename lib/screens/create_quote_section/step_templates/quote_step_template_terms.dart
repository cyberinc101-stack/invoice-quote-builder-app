part of 'quote_step_template.dart';

// =============================================================================
// _QuoteTermsSection — Terms & Conditions text for the quote template.
// Mirrors Invoice's _TermsSection (step_templates_terms.dart) exactly,
// including its 250-char cap. Wired to QuoteTemplate.termsAndConditions
// — NOT yet synced onto QuoteData at template-select time (see
// quote_step_template.dart's file header for the pending sync step).
//
// Deliberately has no Payment Terms / Due Note field — matches Invoice,
// which removed that field entirely (see Invoice's PAYMENT TERMS
// REMOVAL PASS); Quote never had it to begin with.
//
// Named distinctly from Invoice's _TermsSection so both part-file
// libraries can coexist in the app without symbol collisions.
// =============================================================================

class _QuoteTermsSection extends StatelessWidget {
  final TextEditingController termsAndConditionsCtrl;
  final Color accent;

  const _QuoteTermsSection({
    required this.termsAndConditionsCtrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuoteFieldLite(
          ctrl: termsAndConditionsCtrl,
          label: 'Terms & Conditions',
          hint: 'e.g. This quote is valid for 14 days from issue...',
          icon: Icons.gavel_rounded,
          max: 250,
          maxLines: 6,
          accent: accent,
        ),
        _counter(context, termsAndConditionsCtrl.text.length, 250),
      ],
    );
  }
}
