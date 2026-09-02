// receipt_paper_format.dart
// lib/create_receipt/receipt_paper_format.dart
//
// Paper format selection for receipts — A4 (standard) or thermal
// 58mm/80mm (POS/portable printers). Stored on ReceiptData as a plain
// String (paperFormat), same pattern as businessLogoShape — this file
// owns the enum + string conversion helpers, mirroring how LogoShape
// lives in widgets/shared_logo_picker.dart rather than in the model file.

enum ReceiptPaperFormat { a4, thermal58, thermal80 }

extension ReceiptPaperFormatX on ReceiptPaperFormat {
  String get storageName {
    switch (this) {
      case ReceiptPaperFormat.a4:
        return 'a4';
      case ReceiptPaperFormat.thermal58:
        return 'thermal58';
      case ReceiptPaperFormat.thermal80:
        return 'thermal80';
    }
  }

  String get label {
    switch (this) {
      case ReceiptPaperFormat.a4:
        return 'A4';
      case ReceiptPaperFormat.thermal58:
        return '58mm';
      case ReceiptPaperFormat.thermal80:
        return '80mm';
    }
  }

  String get description {
    switch (this) {
      case ReceiptPaperFormat.a4:
        return 'Standard full-page PDF';
      case ReceiptPaperFormat.thermal58:
        return 'Small/portable Bluetooth printers';
      case ReceiptPaperFormat.thermal80:
        return 'Standard POS/cash-register printers';
    }
  }

  bool get isThermal => this != ReceiptPaperFormat.a4;

  /// Physical roll width in millimetres. Only meaningful for thermal
  /// formats — A4 uses the existing kPageW/kPageH constants instead.
  double get widthMm {
    switch (this) {
      case ReceiptPaperFormat.a4:
        return 210.0;
      case ReceiptPaperFormat.thermal58:
        return 58.0;
      case ReceiptPaperFormat.thermal80:
        return 80.0;
    }
  }
}

ReceiptPaperFormat receiptPaperFormatFromString(String? s) {
  switch (s) {
    case 'thermal58':
      return ReceiptPaperFormat.thermal58;
    case 'thermal80':
      return ReceiptPaperFormat.thermal80;
    default:
      return ReceiptPaperFormat.a4;
  }
}
