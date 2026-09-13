part of 'quote_step_template.dart';

// =============================================================================
// _QuotePaymentInfoSection — bank/payment fields for the quote template.
// Mirrors Invoice's _PaymentInfoSection (step_templates_payment.dart)
// exactly, including its field caps (Bank Name 40, Account Name 40,
// Account Number 34 — IBAN max, Other Payment Details 90). Wired to
// QuoteTemplate's bankName/accountName/accountNumber/
// otherPaymentDetails — NOT yet synced onto QuoteData at template-select
// time (see quote_step_template.dart's file header for the pending sync
// step).
//
// Named distinctly from Invoice's _PaymentInfoSection so both part-file
// libraries can coexist in the app without symbol collisions.
// =============================================================================

class _QuotePaymentInfoSection extends StatelessWidget {
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController otherPaymentDetailsCtrl;
  final Color accent;

  const _QuotePaymentInfoSection({
    required this.bankNameCtrl,
    required this.accountNameCtrl,
    required this.accountNumberCtrl,
    required this.otherPaymentDetailsCtrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuoteFieldLite(
          ctrl: bankNameCtrl,
          label: 'Bank Name',
          hint: 'e.g. First National Bank',
          icon: Icons.account_balance_rounded,
          max: 40,
          accent: accent,
        ),
        _counter(context, bankNameCtrl.text.length, 40),
        const SizedBox(height: 12),
        QuoteFieldLite(
          ctrl: accountNameCtrl,
          label: 'Account Name',
          hint: 'e.g. Nova Studio Co.',
          icon: Icons.badge_outlined,
          max: 40,
          accent: accent,
        ),
        _counter(context, accountNameCtrl.text.length, 40),
        const SizedBox(height: 12),
        QuoteFieldLite(
          ctrl: accountNumberCtrl,
          label: 'Account Number',
          hint: 'e.g. 0123456789',
          icon: Icons.pin_rounded,
          max: 34,
          accent: accent,
        ),
        _counter(context, accountNumberCtrl.text.length, 34),
        const SizedBox(height: 12),
        QuoteFieldLite(
          ctrl: otherPaymentDetailsCtrl,
          label: 'Other Payment Details',
          hint: 'e.g. IBAN, SWIFT/BIC, routing/sort code, PayPal',
          icon: Icons.notes_outlined,
          max: 90,
          maxLines: 3,
          accent: accent,
        ),
        _counter(context, otherPaymentDetailsCtrl.text.length, 90),
      ],
    );
  }
}
