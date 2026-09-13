part of 'step_templates.dart';

// =============================================================================
// _TermsSection — Terms & Conditions text for the invoice template.
// Wired to BusinessInfo.termsAndConditions (see client_info.dart's
// PAYMENT INFO / TERMS & SIGNATURE PASS), which syncs onto InvoiceData's
// matching field at template-select time (step_create_invoice.dart).
//
// PAYMENT TERMS REMOVAL PASS (this update): the "Payment Terms / Due
// Note" field has been removed from this section entirely —
// paymentTermsCtrl parameter, its _SheetField, and its counter are all
// gone. Matches the corresponding removal in client_info.dart
// (BusinessInfo.paymentTerms), invoice_data.dart (InvoiceData.paymentTerms),
// step_templates.dart (the controller + BusinessInfo(...) constructor
// call), step_customise.dart (the toggle row), step_create_invoice.dart
// (the sync step), and the two render sites
// (executive_invoice_payment_terms_signature.dart,
// invoice_pdf_extra_sections.dart). Terms & Conditions is now the only
// field in this section.
//
// FIELD LENGTH TIGHTENING PASS v3 (earlier): Terms & Conditions -> 250
// (400 -> 250) — still enough room for 2-3 genuine sentences of
// boilerplate while meaningfully shortening the single biggest text
// block in the footer.
// =============================================================================

class _TermsSection extends StatelessWidget {
  final TextEditingController termsAndConditionsCtrl;
  final Color accent;

  const _TermsSection({
    required this.termsAndConditionsCtrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetField(
          ctrl: termsAndConditionsCtrl,
          label: 'Terms & Conditions',
          hint: 'e.g. Late payments incur a 2% monthly fee...',
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
