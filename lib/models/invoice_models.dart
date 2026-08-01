// lib/models/invoice_models.dart
//
// Single re-export + alias file.
// Everything lives in invoice_data.dart and client_info.dart;
// this file just exposes the aliases that the invoice screens use.

export 'invoice_data.dart';
export 'client_info.dart';

import 'invoice_data.dart';
import 'client_info.dart';

/// InvoiceItem  →  LineItem  (from invoice_data.dart)
typedef InvoiceItem = LineItem;

/// Customer  →  ClientInfo  (from client_info.dart)
typedef Customer = ClientInfo;

/// InvoiceColorScheme  →  InvoiceColor  (from invoice_data.dart)
typedef InvoiceColorScheme = InvoiceColor;