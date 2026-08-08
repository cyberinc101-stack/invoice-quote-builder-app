import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({Key? key}) : super(key: key);

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  static const String _contactEmail = 'cyberinc101@gmail.com';

  final List<_FaqItem> _faqItems = [
    _FaqItem(
      category: 'Getting Started',
      question: 'How do I create my first invoice?',
      answer:
          'Tap the "+" button on the home screen and choose Invoice. Fill in your business profile, add your client\'s details, then add line items with descriptions, quantities, and prices. Your progress is saved automatically as you go.',
    ),
    _FaqItem(
      category: 'Getting Started',
      question: 'Can I create quotes and receipts too, not just invoices?',
      answer:
          'Yes. The App supports all three document types — Invoices, Quotes, and Receipts — from the same "+" menu on the home screen. Each has its own fields relevant to that document type (for example, quotes have an expiry date instead of a due date).',
    ),
    _FaqItem(
      category: 'Invoices',
      question: 'How do I mark an invoice as paid?',
      answer:
          'Open the invoice from your saved documents, tap the status badge or the 3-dot menu, and select "Mark as Paid." The paid date is recorded automatically and will show in the invoice\'s activity history.',
    ),
    _FaqItem(
      category: 'Invoices',
      question: 'Can I get reminders about overdue or upcoming invoices?',
      answer:
          'Yes. The Alerts feature (bell icon) tracks overdue invoices, invoices due soon, and expiring quotes automatically. You can turn Alerts on or off entirely in Settings.',
    ),
    _FaqItem(
      category: 'Quotes',
      question: 'What happens when a quote expires?',
      answer:
          'An expired quote is flagged in your saved documents and in Alerts, but it isn\'t deleted — you can still view, edit, resend, or convert it at any time.',
    ),
    _FaqItem(
      category: 'Templates & Previews',
      question: 'How do I preview what my document will look like before exporting?',
      answer:
          'While creating or editing a document, tap "Preview" to see a full-page rendering that matches the layout, fonts, and colours of the final exported PDF.',
    ),
    _FaqItem(
      category: 'Templates & Previews',
      question: 'Are more templates coming?',
      answer:
          'Yes — the Executive template is available now across invoices, quotes, and receipts, with more template designs planned for future updates.',
    ),
    _FaqItem(
      category: 'Exporting & Sharing',
      question: 'How do I export a document as a PDF?',
      answer:
          'Open the document and tap "Download" to save the PDF to your device, or "Share" to send it directly via email, messaging apps, or any other app installed on your device.',
    ),
    _FaqItem(
      category: 'Exporting & Sharing',
      question: 'Can I export multiple documents at once?',
      answer:
          'Yes. From your saved documents list, enter selection mode (long-press any document), select the ones you want, and use the bulk export option to export them together.',
    ),
    _FaqItem(
      category: 'Data & Privacy',
      question: 'Where is my data stored?',
      answer:
          'All your business profile, client details, invoices, quotes, and receipts are stored locally on your device. We do not upload this information to our servers unless you explicitly export or share a document.',
    ),
    _FaqItem(
      category: 'Data & Privacy',
      question: 'How do I back up my documents?',
      answer:
          'Your data is included in your device\'s standard backup (Google Drive backup on Android, iCloud on iOS) if you have backup enabled in your device settings. You can also export individual documents as PDFs, or use the bulk export feature, to keep separate copies.',
    ),
    _FaqItem(
      category: 'Troubleshooting',
      question: 'My document isn\'t exporting correctly. What should I do?',
      answer:
          'Make sure you have enough storage space on your device, and check that your business logo (if used) isn\'t an unusually large file. If the problem continues, please contact our support team.',
    ),
    _FaqItem(
      category: 'Troubleshooting',
      question: 'The app is running slowly. What should I do?',
      answer:
          'Try closing and reopening the app. If the problem persists, restart your device and ensure you have the latest version of the app installed from the Play Store / App Store.',
    ),
    _FaqItem(
      category: 'Troubleshooting',
      question: 'I forgot to save — is my work lost?',
      answer:
          'Not at all. The app saves your progress continuously as you edit a document, so you shouldn\'t lose your work if you navigate away.',
    ),
  ];

  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = _faqItems.map((e) => e.category).toSet().toList();
    return ['All', ...cats];
  }

  List<_FaqItem> get _filteredItems {
    return _faqItems.where((item) {
      return _selectedCategory == 'All' || item.category == _selectedCategory;
    }).toList();
  }

  Future<void> _launchContactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      queryParameters: {
        'subject': 'Invoice & Quote Generator Pro - Support Request',
        'body': 'Hi Support Team,\n\nI need help with the following:\n\n',
      },
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open email app. Please email cyberinc101@gmail.com'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & FAQ',
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
      body: Column(
        children: [
          // ── Category chips ────────────────────────────────────────
          Container(
            color: colorScheme.surface,
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                    backgroundColor: isDark
                        ? colorScheme.surfaceContainerHighest
                        : const Color(0xFFF0F2F5),
                    labelStyle: TextStyle(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),

          // ── FAQ list ───────────────────────────────────────────────
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      return _FaqTile(item: _filteredItems[index]);
                    },
                  ),
          ),

          // ── Contact support banner — always dark gradient ──────────
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Still need help?',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Our team is here for you.',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: _launchContactSupport,
                    child: const Text('Contact',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;

  const _FaqItem(
      {required this.category,
      required this.question,
      required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;

  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: colorScheme.surface,
      child: Theme(
        // Remove the default ExpansionTile divider colour
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            widget.item.question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.question_answer_outlined,
                size: 18, color: colorScheme.primary),
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down,
                color: colorScheme.primary),
          ),
          onExpansionChanged: (val) => setState(() => _expanded = val),
          children: [
            Text(
              widget.item.answer,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
