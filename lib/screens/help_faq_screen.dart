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
      question: 'How do I create my first CV?',
      answer:
          'Tap the "+" button on the home screen to start a new CV. Choose a template that suits your style, then fill in your personal details, work experience, education, and skills step by step. Your progress is saved automatically.',
    ),
    _FaqItem(
      category: 'Getting Started',
      question: 'Can I create more than one CV?',
      answer:
          'Yes! You can create multiple CVs for different roles or industries. Each CV is saved separately, so you can tailor them to specific job applications.',
    ),
    _FaqItem(
      category: 'Templates',
      question: 'How do I change my CV template?',
      answer:
          'Open your CV, tap the template icon at the top of the screen, and browse through available templates. Tap any template to preview it with your existing content. Confirm to apply it.',
    ),
    _FaqItem(
      category: 'Templates',
      question: 'Are there free and premium templates?',
      answer:
          'Yes. A selection of professional templates is available for free. Premium templates with advanced designs and colour palettes are available through a one-time purchase or subscription.',
    ),
    _FaqItem(
      category: 'Editing',
      question: 'How do I add or remove sections?',
      answer:
          'In the CV editor, scroll to the bottom of the screen and tap "Add Section" to include extras like Languages, Certifications, or Volunteer Work. To remove a section, tap the section header and select "Remove."',
    ),
    _FaqItem(
      category: 'Editing',
      question: 'How do I reorder sections?',
      answer:
          'Long-press the drag handle (≡) next to any section header and drag it to your preferred position. Changes are saved automatically.',
    ),
    _FaqItem(
      category: 'Exporting',
      question: 'How do I export my CV as a PDF?',
      answer:
          'Open your CV and tap the export button (share icon) in the top-right corner. Select "Export as PDF." You can then save it to your device, share it via email, WhatsApp, or upload it directly to job boards.',
    ),
    _FaqItem(
      category: 'Exporting',
      question: 'What file formats are supported?',
      answer:
          'Currently the App supports exporting your CV as a high-quality PDF. Additional formats may be added in future updates.',
    ),
    _FaqItem(
      category: 'Data & Privacy',
      question: 'Where is my CV data stored?',
      answer:
          'All your CV data is stored locally on your device. We do not upload your personal information to our servers. This means your data stays private and accessible offline.',
    ),
    _FaqItem(
      category: 'Data & Privacy',
      question: 'How do I back up my CVs?',
      answer:
          'Your CVs are included in your device\'s standard backup (Google Drive backup on Android, iCloud on iOS) if you have backup enabled in your device settings. You can also export individual CVs as PDFs to keep a copy.',
    ),
    _FaqItem(
      category: 'Troubleshooting',
      question: 'The app is running slowly. What should I do?',
      answer:
          'Try closing and reopening the app. If the problem persists, restart your device. Ensure you have the latest version of the app installed from the Play Store / App Store.',
    ),
    _FaqItem(
      category: 'Troubleshooting',
      question: 'My CV isn\'t exporting correctly. What should I do?',
      answer:
          'Make sure you have enough storage space on your device. Try reducing large images in your CV. If the problem continues, please contact our support team.',
    ),
    _FaqItem(
      category: 'Troubleshooting',
      question: 'I forgot to save — is my work lost?',
      answer:
          'Not at all! The app saves your progress continuously as you edit.',
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
        'subject': 'CV Builder App - Support Request',
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
          // ── Category chips ────────────────────────────────────────────
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
                    selectedColor: colorScheme.primary.withOpacity(0.15),
                    backgroundColor: isDark
                        ? colorScheme.surfaceContainerHighest
                        : const Color(0xFFF0F2F5),
                    labelStyle: TextStyle(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? colorScheme.primary.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),

          // ── FAQ list ─────────────────────────────────────────────────
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64,
                            color: colorScheme.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4),
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

          // ── Contact support banner — always dark gradient ─────────────
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
                    color: const Color(0xFF1A1A2E).withOpacity(0.3),
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
              color: colorScheme.primary.withOpacity(0.1),
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
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}