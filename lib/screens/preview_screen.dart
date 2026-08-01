import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/invoice_provider.dart';
import '../services/pdf_generator.dart';
import '../language_keys/lang_en_english.dart'; // swap for active locale map at runtime

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  // Active translation map — replace with the user's chosen locale map at runtime.
  static const Map<String, String> _t = enEnglish;

  Future<void> _downloadPDF(BuildContext context) async {
    try {
      final provider = context.read<CVProvider>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final file = await PDFGenerator.generatePDF(
        provider.cvData,
        provider.selectedTemplate,
      );
      if (context.mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'My CV - ${provider.cvData.fullName}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _printPDF(BuildContext context) async {
    try {
      final provider = context.read<CVProvider>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final file = await PDFGenerator.generatePDF(
        provider.cvData,
        provider.selectedTemplate,
      );
      if (context.mounted) {
        Navigator.pop(context);
        await Printing.layoutPdf(
          onLayout: (format) => file.readAsBytes(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _PreviewHeader(
            onBack:     () => Navigator.pop(context),
            onPrint:    () => _printPDF(context),
            onDownload: () => _downloadPDF(context),
          ),
          Expanded(
            child: Consumer<CVProvider>(
              builder: (context, provider, _) {
                return FutureBuilder(
                  future: PDFGenerator.generatePDF(
                    provider.cvData,
                    provider.selectedTemplate,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _t['preview_generating']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF3B1F1F)
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.error_outline_rounded,
                                    size: 36, color: Color(0xFFEF5350)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _t['preview_failed_title']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                // Replace {error} token at runtime
                                (_t['preview_failed_error'] ?? 'Error: {error}')
                                    .replaceAll('{error}',
                                        '${snapshot.error}'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A2E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _t['preview_go_back']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          _t['preview_no_data']!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                      );
                    }

                    return PdfPreview(
                      build: (format) => snapshot.data!.readAsBytes(),
                      canChangePageFormat:   false,
                      canChangeOrientation:  false,
                      canDebug:              false,
                      allowPrinting:         false,
                      allowSharing:          false,
                    );
                  },
                );
              },
            ),
          ),
          _BottomBar(
            onPrint:    () => _printPDF(context),
            onDownload: () => _downloadPDF(context),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _PreviewHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  // Translation map accessible from a StatelessWidget by referencing the
  // parent's static const — or import directly here for standalone use.
  static const Map<String, String> _t = enEnglish;

  const _PreviewHeader({
    required this.onBack,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x40000000),
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t['preview_header_title']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3),
                    ),
                    Text(
                      _t['preview_header_sub']!,
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onPrint,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.print_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDownload,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  static const Map<String, String> _t = enEnglish;

  const _BottomBar({required this.onPrint, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          // Print button
          GestureDetector(
            onTap: onPrint,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withOpacity(0.3)
                      : const Color(0xFFE8E8E8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_rounded,
                      color: colorScheme.onSurface, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _t['preview_btn_print']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Download & Share button
          Expanded(
            child: GestureDetector(
              onTap: onDownload,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x504CAF50),
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _t['preview_btn_download']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
