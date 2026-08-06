// invoice_provider.dart
// lib/providers/invoice_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_data.dart';

const String _kSavedInvoicesKey = 'saved_invoices_v1';

class InvoiceProvider extends ChangeNotifier {
  InvoiceData _invoiceData = InvoiceData();

  final List<SavedInvoice> _savedInvoices = [];
  String? _activeInvoiceId;

  bool _loading = true;
  bool get isLoading => _loading;

  InvoiceData        get invoiceData      => _invoiceData;
  List<SavedInvoice> get savedInvoices    => List.unmodifiable(_savedInvoices);
  String?            get activeInvoiceId  => _activeInvoiceId;

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> loadPersistedInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kSavedInvoicesKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _savedInvoices.clear();
        for (final item in list) {
          try {
            _savedInvoices.add(
              SavedInvoice.fromJson(
                (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
              ),
            );
          } catch (e) {
            debugPrint('[InvoiceProvider] Skipped corrupt entry: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[InvoiceProvider] loadPersistedInvoices error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_savedInvoices.map((i) => i.toJson()).toList());
      await prefs.setString(_kSavedInvoicesKey, encoded);
    } catch (e) {
      debugPrint('[InvoiceProvider] _persist error: $e');
    }
  }

  // ── Active session ─────────────────────────────────────────────────────────

  void resetInvoiceData() {
    _invoiceData    = InvoiceData();
    _activeInvoiceId = null;
    notifyListeners();
  }

  void loadSavedInvoice(String id) {
    final inv = _savedInvoices.firstWhere((i) => i.id == id);
    _invoiceData     = inv.data.deepCopy();
    _activeInvoiceId = inv.id;
    notifyListeners();
  }

  void clearActiveSession() {
    _activeInvoiceId = null;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  SavedInvoice saveCurrentInvoice({
    required String title,
    required String templateName,
  }) {
    final now = DateTime.now();
    final inv = SavedInvoice(
      id:                '${now.millisecondsSinceEpoch}',
      title:             title.trim().isEmpty ? 'Invoice' : title.trim(),
      templateName:      templateName,
      data:              _invoiceData.deepCopy(),
      createdAt:         now,
      lastEditedAt:      now,
      completionPercent: _calcCompletion(),
    );
    _savedInvoices.insert(0, inv);
    _activeInvoiceId = inv.id;
    _persist();
    notifyListeners();
    return inv;
  }

  // NEW: saves a converted InvoiceData (e.g. built from a quote via
  // convertQuoteDataToInvoiceData) directly as a new saved invoice, WITHOUT
  // touching the active editor draft — unlike saveCurrentInvoice(), which
  // always saves whatever's currently in _invoiceData. Used by the
  // "Convert to Invoice" action in saved_document_detail_screen.dart.
  SavedInvoice addConvertedInvoice({
    required InvoiceData data,
    required String title,
    required String templateName,
  }) {
    final now = DateTime.now();
    final inv = SavedInvoice(
      id:                '${now.millisecondsSinceEpoch}',
      title:             title.trim().isEmpty ? 'Invoice' : title.trim(),
      templateName:      templateName,
      data:              data.deepCopy(),
      createdAt:         now,
      lastEditedAt:      now,
      completionPercent: _calcCompletionFor(data),
    );
    _savedInvoices.insert(0, inv);
    _persist();
    notifyListeners();
    return inv;
  }

  void updateSavedInvoice(String id) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(
      data:              _invoiceData.deepCopy(),
      lastEditedAt:      DateTime.now(),
      completionPercent: _calcCompletion(),
    );
    _persist();
    notifyListeners();
  }

  void renameInvoice(String id, String newTitle) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(title: trimmed);
    _persist();
    notifyListeners();
  }

  void deleteInvoice(String id) {
    _savedInvoices.removeWhere((i) => i.id == id);
    if (_activeInvoiceId == id) _activeInvoiceId = null;
    _persist();
    notifyListeners();
  }

  SavedInvoice? getInvoiceById(String id) {
    try {
      return _savedInvoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Status ─────────────────────────────────────────────────────────────────
  // Powers the tappable status chip in saved_document_detail_screen.dart.
  // Updates the SAVED entry's status directly (not the active draft), same
  // pattern as ReceiptProvider.updateSavedReceiptStatus.
  //
  // FIX (this pass): now also stamps/clears InvoiceData.paidDate —
  //   - Freshly moved TO paid (wasn't paid before)   -> stamp paidDate = now
  //   - Moved AWAY from paid                          -> clear paidDate
  //   - Re-set to paid while already paid (no-op flip)-> leave existing
  //     paidDate untouched, so re-tapping the same status doesn't reset the
  //     original paid timestamp.

  void updateSavedInvoiceStatus(String id, PaymentStatus status) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final current  = _savedInvoices[index];
    final wasPaid  = current.data.paymentStatus == PaymentStatus.paid;
    final isNowPaid = status == PaymentStatus.paid;

    InvoiceData updatedData;
    if (isNowPaid && !wasPaid) {
      updatedData = current.data.copyWith(
        paymentStatus: status,
        paidDate: DateTime.now(),
      );
    } else if (!isNowPaid) {
      updatedData = current.data.copyWith(
        paymentStatus: status,
        clearPaidDate: true,
      );
    } else {
      updatedData = current.data.copyWith(paymentStatus: status);
    }

    _savedInvoices[index] = current.copyWith(
      data: updatedData,
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  // ── Folder ─────────────────────────────────────────────────────────────────
  // NEW: assigns or clears the organizational folder for a saved invoice.
  // Pass null to remove it from whatever folder it's currently in. Updates
  // the SAVED entry directly, same pattern as updateSavedInvoiceStatus.

  void updateInvoiceFolder(String id, String? folderName) {
    final index = _savedInvoices.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _savedInvoices[index] = _savedInvoices[index].copyWith(
      folderName: folderName,
      clearFolderName: folderName == null,
      lastEditedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  // ── Data mutations ─────────────────────────────────────────────────────────

  void updateInvoiceData(InvoiceData data) {
    _invoiceData = data;
    notifyListeners();
  }

  void updateBusinessInfo({
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessLogoPath,
  }) {
    _invoiceData = _invoiceData.copyWith(
      businessName:     businessName,
      businessEmail:    businessEmail,
      businessPhone:    businessPhone,
      businessAddress:  businessAddress,
      businessLogoPath: businessLogoPath,
    );
    notifyListeners();
  }

  void updateClientInfo({
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
  }) {
    _invoiceData = _invoiceData.copyWith(
      clientName:    clientName,
      clientEmail:   clientEmail,
      clientPhone:   clientPhone,
      clientAddress: clientAddress,
    );
    notifyListeners();
  }

  void updateInvoiceDetails({
    String? invoiceNumber,
    String? issueDate,
    String? dueDate,
    String? notes,
    String? currency,
    double? taxRate,
    double? discountRate,
  }) {
    _invoiceData = _invoiceData.copyWith(
      invoiceNumber: invoiceNumber,
      issueDate:     issueDate,
      dueDate:       dueDate,
      notes:         notes,
      currency:      currency,
      taxRate:       taxRate,
      discountRate:  discountRate,
    );
    notifyListeners();
  }

  void addLineItem(LineItem item) {
    _invoiceData = _invoiceData.copyWith(
      lineItems: [..._invoiceData.lineItems, item],
    );
    notifyListeners();
  }

  void updateLineItem(int index, LineItem item) {
    final updated = List<LineItem>.from(_invoiceData.lineItems);
    updated[index] = item;
    _invoiceData = _invoiceData.copyWith(lineItems: updated);
    notifyListeners();
  }

  void removeLineItem(int index) {
    final updated = List<LineItem>.from(_invoiceData.lineItems)..removeAt(index);
    _invoiceData = _invoiceData.copyWith(lineItems: updated);
    notifyListeners();
  }

  void updatePaymentStatus(PaymentStatus status) {
    _invoiceData = _invoiceData.copyWith(paymentStatus: status);
    notifyListeners();
  }

  void updateColorScheme(InvoiceColor color) {
    _invoiceData = _invoiceData.copyWith(colorScheme: color);
    notifyListeners();
  }

  void updateFontFamily(String font) {
    _invoiceData = _invoiceData.copyWith(fontFamily: font);
    notifyListeners();
  }

  double _fontSize = 14.0;
  double get fontSize => _fontSize;
  void updateFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _calcCompletion() => _calcCompletionFor(_invoiceData);

  // NEW: pulled out of _calcCompletion() so addConvertedInvoice() can score
  // a converted InvoiceData that isn't the active draft.
  int _calcCompletionFor(InvoiceData data) {
    int score = 0;
    if (data.businessName.isNotEmpty)  score++;
    if (data.clientName.isNotEmpty)    score++;
    if (data.invoiceNumber.isNotEmpty) score++;
    if (data.lineItems.isNotEmpty)     score++;
    if (data.dueDate.isNotEmpty)       score++;
    return ((score / 5) * 100).round();
  }
}