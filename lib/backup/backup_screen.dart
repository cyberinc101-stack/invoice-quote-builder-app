// backup_screen.dart
// lib/backup/backup_screen.dart
//
// Settings -> Backup & Restore. Two actions:
//   - Export Backup: builds the combined JSON (AppBackupService.
//     exportToFile()) and hands it to the OS share sheet (share_plus) so
//     the user can save it to Drive/Files/email/etc — same "generate a
//     file, then let the OS share sheet decide where it goes" pattern the
//     existing CSV export flow already uses.
//   - Restore from Backup: lets the user pick a .json file (file_picker),
//     shows a destructive-action confirmation (this OVERWRITES whatever
//     invoices/quotes/receipts/expenses currently exist for any document
//     type present in the backup), then calls AppBackupService.
//     restoreFromFile() and reloads every provider from the now-updated
//     SharedPreferences so the UI reflects the restored data immediately
//     without requiring an app restart.
//
// Requires (add if not already present):
//   flutter pub add file_picker share_plus

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../providers/expense_provider.dart';
import 'app_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _exporting = false;
  bool _restoring = false;

  Future<void> _handleExport() async {
    setState(() => _exporting = true);
    try {
      final file = await AppBackupService.instance.exportToFile();
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice & Quote Builder backup',
        text: 'App backup exported ${DateTime.now().toLocal()}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup ready — choose where to save it.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Restore from backup?'),
        content: const Text(
          'This will replace your current invoices, quotes, receipts, and '
          "expenses with whatever's in the backup file — for each document "
          "type the backup contains. This can't be undone. Make sure this "
          "is the backup you want before continuing.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Restore', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _restoring = true);
    try {
      final restoreResult = await AppBackupService.instance.restoreFromFile(File(path));
      if (!mounted) return;

      if (!restoreResult.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restoreResult.errorMessage ?? 'Restore failed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Reload every provider from the now-updated SharedPreferences so
      // the UI reflects the restored data immediately, without requiring
      // an app restart. Each of these is the exact same method each
      // provider already calls once on app startup.
      await Future.wait([
        context.read<InvoiceProvider>().loadPersistedInvoices(),
        context.read<QuoteProvider>().loadPersistedQuotes(),
        context.read<ReceiptProvider>().loadPersistedReceipts(),
        context.read<ExpenseProvider>().loadPersistedExpenses(),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup & Restore',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1B2E) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Backs up all your saved invoices, quotes, receipts, and '
                    "expenses to a single file. It doesn't include app "
                    'settings like theme or language.',
                    style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.7), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _ActionCard(
            icon: Icons.upload_file_rounded,
            iconColor: const Color(0xFF2196F3),
            title: 'Export Backup',
            subtitle: 'Save a copy of everything to a file you control',
            buttonLabel: 'Export',
            loading: _exporting,
            onTap: _exporting ? null : _handleExport,
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.download_rounded,
            iconColor: const Color(0xFFE53935),
            title: 'Restore from Backup',
            subtitle: 'Replace current data with a previously exported file',
            buttonLabel: 'Restore',
            loading: _restoring,
            destructive: true,
            onTap: _restoring ? null : _handleRestore,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool loading;
  final bool destructive;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.loading,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: loading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: destructive ? const Color(0xFFE53935) : iconColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(buttonLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
    );
  }
}