part of 'receipt_step_template.dart';

// =============================================================================
// _ReceiptPaymentInfoSection — bank/payment fields for the receipt
// template. Mirrors Invoice's _PaymentInfoSection
// (step_templates_payment.dart) and Quote's _QuotePaymentInfoSection
// (quote_step_template_payment.dart) exactly, including field caps
// (Bank Name 40, Account Name 40, Account Number 34 — IBAN max, Other
// Payment Details 90). Wired to ReceiptTemplate's bankName/accountName/
// accountNumber/otherPaymentDetails — NOT yet synced onto ReceiptData at
// template-select time (see receipt_step_template.dart's file header
// for the pending sync step).
//
// Named distinctly from Invoice's _PaymentInfoSection and Quote's
// _QuotePaymentInfoSection so all three part-file libraries can coexist
// in the app without symbol collisions.
// =============================================================================

class _ReceiptPaymentInfoSection extends StatelessWidget {
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController otherPaymentDetailsCtrl;
  final Color accent;

  const _ReceiptPaymentInfoSection({
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
        ReceiptField(
          ctrl: bankNameCtrl,
          label: 'Bank Name',
          hint: 'e.g. First National Bank',
          accent: accent,
          icon: Icons.account_balance_rounded,
          max: 40,
        ),
        _counter(context, bankNameCtrl.text.length, 40),
        const SizedBox(height: 12),
        ReceiptField(
          ctrl: accountNameCtrl,
          label: 'Account Name',
          hint: 'e.g. Acme Solutions Ltd',
          accent: accent,
          icon: Icons.badge_outlined,
          max: 40,
        ),
        _counter(context, accountNameCtrl.text.length, 40),
        const SizedBox(height: 12),
        ReceiptField(
          ctrl: accountNumberCtrl,
          label: 'Account Number',
          hint: 'e.g. 0123456789',
          accent: accent,
          icon: Icons.pin_rounded,
          max: 34,
        ),
        _counter(context, accountNumberCtrl.text.length, 34),
        const SizedBox(height: 12),
        ReceiptField(
          ctrl: otherPaymentDetailsCtrl,
          label: 'Other Payment Details',
          hint: 'e.g. IBAN, SWIFT/BIC, routing/sort code, PayPal',
          accent: accent,
          icon: Icons.notes_outlined,
          max: 90,
          maxLines: 3,
        ),
        _counter(context, otherPaymentDetailsCtrl.text.length, 90),
      ],
    );
  }
}
