part of 'receipt_step_template.dart';

// =============================================================================
// _ReceiptTermsSection — Terms & Conditions text for the receipt
// template. Mirrors Invoice's _TermsSection (step_templates_terms.dart)
// and Quote's _QuoteTermsSection (quote_step_template_terms.dart)
// exactly, including the 250-char cap. Wired to
// ReceiptTemplate.termsAndConditions — NOT yet synced onto ReceiptData
// at template-select time (see receipt_step_template.dart's file header
// for the pending sync step).
//
// Deliberately has no Payment Terms / Due Note field — matches Invoice
// (which removed that field entirely) and Quote (which never had it).
//
// Named distinctly from Invoice's _TermsSection and Quote's
// _QuoteTermsSection so all three part-file libraries can coexist in
// the app without symbol collisions.
// =============================================================================

class _ReceiptTermsSection extends StatelessWidget {
  final TextEditingController termsAndConditionsCtrl;
  final Color accent;

  const _ReceiptTermsSection({
    required this.termsAndConditionsCtrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptField(
          ctrl: termsAndConditionsCtrl,
          label: 'Terms & Conditions',
          hint: 'e.g. Returns accepted within 14 days with receipt...',
          accent: accent,
          icon: Icons.gavel_rounded,
          max: 250,
          maxLines: 6,
        ),
        _counter(context, termsAndConditionsCtrl.text.length, 250),
      ],
    );
  }
}
