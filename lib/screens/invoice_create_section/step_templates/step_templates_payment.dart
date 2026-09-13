part of 'step_templates.dart';

// =============================================================================
// _PaymentInfoSection — bank/payment fields for the invoice template.
// Wired to BusinessInfo's bankName/accountName/accountNumber/
// otherPaymentDetails (see client_info.dart's PAYMENT INFO / TERMS &
// SIGNATURE PASS), which is intended to sync onto InvoiceData's matching
// fields (invoice_data.dart's PAYMENT INFO / TERMS & CONDITIONS /
// SIGNATURE PASS) at template-select time. NOT yet wired into that sync —
// see StepCreateInvoice._syncToProvider() (pending).
//
// FIELD LENGTH TIGHTENING PASS v3 (this update): Other Payment Details
// now renders inside the narrower "accounts" column beside Payment
// Terms instead of the old full-width panel (see
// executive_invoice_payment_terms_signature.dart's PAYMENT TERMS
// LEFT-OF-ACCOUNTS PASS) — the same character count wraps onto more
// lines at that reduced width, so its cap is shaved to match:
//   - Other Payment Details -> 90 (120 -> 90). Still fits 2 short
//     entries ("PayPal: name@example.com", "Zelle: 555-123-4567" — 45
//     chars combined) with a little room, without ballooning to 5+
//     wrapped lines in the narrower column the way 120 did.
// Bank Name/Account Name/Account Number are UNCHANGED — each already
// wraps to only 1-2 lines in the accounts column at their existing caps
// (40/40/34), so shaving them further would start clipping real values
// (Account Number is still the IBAN-max 34 for the same reason as
// before) rather than trimming excess.
//
// FIELD LENGTH TIGHTENING PASS v2 (earlier): the previous pass's caps
// still let enough text through to overflow the printed invoice's
// PAYMENT DETAILS panel. Account Name inherits the same 40-char cap
// step_customers.dart's Name field uses (60 -> 40). Bank Name -> 40
// (50 -> 40). Other Payment Details -> 120 (200 -> 120). Account
// Number left at 34 (IBAN max).
//
// FIELD LENGTH TIGHTENING PASS (earlier): caps shaved to match the
// tightened scale used elsewhere on this sheet — Bank Name 80 -> 50,
// Account Name 100 -> 60, Other Payment Details 300 -> 200. Account
// Number left at 34 for the same IBAN reasoning as above.
//
// GROUPED SECTIONS PASS (earlier): the internal _sectionLabel('Payment
// Info') call was removed — this widget is now always rendered inside a
// _CollapsibleGroup (step_templates.dart) whose own header already shows
// the 'Payment Info' label, icon and expand/collapse switch, so a second
// label here would just duplicate it.
// =============================================================================

class _PaymentInfoSection extends StatelessWidget {
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController otherPaymentDetailsCtrl;
  final Color accent;

  const _PaymentInfoSection({
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
        _SheetField(
          ctrl: bankNameCtrl,
          label: 'Bank Name',
          hint: 'e.g. First National Bank',
          icon: Icons.account_balance_rounded,
          max: 40,
          accent: accent,
        ),
        _counter(context, bankNameCtrl.text.length, 40),
        const SizedBox(height: 12),
        _SheetField(
          ctrl: accountNameCtrl,
          label: 'Account Name',
          hint: 'e.g. Acme Solutions Ltd',
          icon: Icons.badge_outlined,
          max: 40,
          accent: accent,
        ),
        _counter(context, accountNameCtrl.text.length, 40),
        const SizedBox(height: 12),
        _SheetField(
          ctrl: accountNumberCtrl,
          label: 'Account Number',
          hint: 'e.g. 0123456789',
          icon: Icons.pin_rounded,
          max: 34,
          accent: accent,
        ),
        _counter(context, accountNumberCtrl.text.length, 34),
        const SizedBox(height: 12),
        _SheetField(
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