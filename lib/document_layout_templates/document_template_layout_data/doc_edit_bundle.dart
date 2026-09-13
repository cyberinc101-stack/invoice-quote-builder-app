// doc_edit_bundle.dart
// lib/document_layout_templates/document_template_layout_data/doc_edit_bundle.dart
//
// Generic edit-bundle type replacing InvoiceEditBundle/QuoteEditBundle/
// ReceiptEditBundle (previously defined separately in each doc type's own
// executive_*_stationary_layout.dart). One shape, used by all three doc
// types via DocTemplateAdapter/TemplateDocument, instead of three
// structurally identical classes hand-copied per type.
//
// Field names are intentionally generic ("docNumberCtrl" not
// "invoiceNumberCtrl", "onTapMetaDate1/2" not "onTapIssueDate/onTapDueDate")
// because DocTemplateAdapter already made this exact generalization for
// read-only data (docNumber, metaLabel1/metaValue1, etc) — this bundle
// mirrors that same shape for the editable path.
//
// Mapping from the old per-type bundles, for reference when porting a
// screen over:
//   InvoiceEditBundle.invoiceNumberCtrl  -> docNumberCtrl
//   InvoiceEditBundle.onInvoiceNumberChanged -> onDocNumberChanged
//   InvoiceEditBundle.onTapIssueDate     -> onTapMetaDate1
//   InvoiceEditBundle.onTapDueDate       -> onTapMetaDate2
//   QuoteEditBundle.quoteNumberCtrl      -> docNumberCtrl
//   QuoteEditBundle.onTapIssueDate       -> onTapMetaDate1
//   QuoteEditBundle.onTapExpiryDate      -> onTapMetaDate2
//   ReceiptEditBundle.receiptNumberCtrl  -> docNumberCtrl
//   ReceiptEditBundle.onTapPaymentDate   -> onTapMetaDate1
//     (onTapMetaDate2 is null for Receipt — it only has one date; the
//     header's _ExecutiveMetaRow already treats metaLabel2/metaValue2 as
//     optional the same way for read-only rendering)
//
// Per-line-item controllers are grouped into DocLineItemControllers
// instead of three parallel List<TextEditingController> (desc/qty/price)
// — same data, easier to pass around and index without three separate
// lists staying in lockstep by construction.

import 'package:flutter/material.dart';

class DocLineItemControllers {
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  const DocLineItemControllers({
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
  });
}

class DocEditBundle {
  // ── Business identity ──────────────────────────────────────────────
  final TextEditingController businessNameCtrl;
  final TextEditingController businessEmailCtrl;
  final TextEditingController businessPhoneCtrl;
  final TextEditingController businessAddressCtrl;
  final ValueChanged<String> onBusinessNameChanged;
  final ValueChanged<String> onBusinessEmailChanged;
  final ValueChanged<String> onBusinessPhoneChanged;
  final ValueChanged<String> onBusinessAddressChanged;
  final ValueChanged<String?> onLogoChanged;

  // ── Document identity ───────────────────────────────────────────────
  final TextEditingController docNumberCtrl;
  final ValueChanged<String> onDocNumberChanged;

  // ── Client / recipient ──────────────────────────────────────────────
  final TextEditingController clientNameCtrl;
  final TextEditingController clientEmailCtrl;
  final TextEditingController clientPhoneCtrl;
  final TextEditingController clientAddressCtrl;
  final ValueChanged<String> onClientNameChanged;
  final ValueChanged<String> onClientEmailChanged;
  final ValueChanged<String> onClientPhoneChanged;
  final ValueChanged<String> onClientAddressChanged;

  // ── Meta row dates ───────────────────────────────────────────────────
  // metaDate2 is null for doc types with only one date (Receipt's
  // Payment Date) — the header treats a null callback the same way
  // DocTemplateAdapter's read-only metaLabel2/metaValue2 are already
  // treated as optional.
  final VoidCallback onTapMetaDate1;
  final VoidCallback? onTapMetaDate2;

  // ── Notes / tax / discount ───────────────────────────────────────────
  final TextEditingController notesCtrl;
  final TextEditingController taxRateCtrl;
  final TextEditingController discountRateCtrl;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<String> onTaxRateChanged;
  final ValueChanged<String> onDiscountRateChanged;

  // ── Line items ───────────────────────────────────────────────────────
  final List<DocLineItemControllers> itemCtrls;
  final void Function(int index) onItemFieldChanged;
  final void Function(int index) onRemoveItem;

  const DocEditBundle({
    required this.businessNameCtrl,
    required this.businessEmailCtrl,
    required this.businessPhoneCtrl,
    required this.businessAddressCtrl,
    required this.onBusinessNameChanged,
    required this.onBusinessEmailChanged,
    required this.onBusinessPhoneChanged,
    required this.onBusinessAddressChanged,
    required this.onLogoChanged,
    required this.docNumberCtrl,
    required this.onDocNumberChanged,
    required this.clientNameCtrl,
    required this.clientEmailCtrl,
    required this.clientPhoneCtrl,
    required this.clientAddressCtrl,
    required this.onClientNameChanged,
    required this.onClientEmailChanged,
    required this.onClientPhoneChanged,
    required this.onClientAddressChanged,
    required this.onTapMetaDate1,
    this.onTapMetaDate2,
    required this.notesCtrl,
    required this.taxRateCtrl,
    required this.discountRateCtrl,
    required this.onNotesChanged,
    required this.onTaxRateChanged,
    required this.onDiscountRateChanged,
    required this.itemCtrls,
    required this.onItemFieldChanged,
    required this.onRemoveItem,
  });
}
