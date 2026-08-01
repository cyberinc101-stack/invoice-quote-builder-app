// document_templates_screen.dart
// lib/screens/document_templates_screen.dart
//
// Grid of document template cards, reachable from the "Templates" button on
// the home screen hero banner. Cards are dummy placeholders for now — swap
// _kDummyTemplates for real template data (see
// lib/widgets/swipable_invoice_templates_homescreen_widgets/template_data.dart
// for the existing invoice template list) once quote/receipt templates exist
// and tapping a card should open an actual preview instead of a snackbar.

import 'package:flutter/material.dart';

enum _TemplateType { invoice, quote, receipt }

class _TemplateData {
  final String name;
  final String style;
  final _TemplateType type;
  final Color accent;
  final IconData icon;

  const _TemplateData({
    required this.name,
    required this.style,
    required this.type,
    required this.accent,
    required this.icon,
  });
}

// DEV DUMMY: placeholder template catalogue. Remove/replace once real
// template previews exist for quotes and receipts.
const List<_TemplateData> _kDummyTemplates = [
  _TemplateData(
    name: 'Executive',
    style: 'Invoice · Blue',
    type: _TemplateType.invoice,
    accent: Color(0xFF1565C0),
    icon: Icons.receipt_long_rounded,
  ),
  _TemplateData(
    name: 'Nordic',
    style: 'Invoice · Teal',
    type: _TemplateType.invoice,
    accent: Color(0xFF00897B),
    icon: Icons.receipt_long_rounded,
  ),
  _TemplateData(
    name: 'Minimal',
    style: 'Invoice · Black',
    type: _TemplateType.invoice,
    accent: Color(0xFF1A1A2E),
    icon: Icons.receipt_long_rounded,
  ),
  _TemplateData(
    name: 'Bold',
    style: 'Invoice · Red',
    type: _TemplateType.invoice,
    accent: Color(0xFFD32F2F),
    icon: Icons.receipt_long_rounded,
  ),
  _TemplateData(
    name: 'Vibrant',
    style: 'Quote · Purple',
    type: _TemplateType.quote,
    accent: Color(0xFF7B1FA2),
    icon: Icons.request_quote_rounded,
  ),
  _TemplateData(
    name: 'Editorial',
    style: 'Quote · Orange',
    type: _TemplateType.quote,
    accent: Color(0xFFEF6C00),
    icon: Icons.request_quote_rounded,
  ),
  _TemplateData(
    name: 'Classic',
    style: 'Quote · Indigo',
    type: _TemplateType.quote,
    accent: Color(0xFF3949AB),
    icon: Icons.request_quote_rounded,
  ),
  _TemplateData(
    name: 'Emerald',
    style: 'Receipt · Green',
    type: _TemplateType.receipt,
    accent: Color(0xFF2E7D32),
    icon: Icons.receipt_rounded,
  ),
  _TemplateData(
    name: 'Slate',
    style: 'Receipt · Grey',
    type: _TemplateType.receipt,
    accent: Color(0xFF37474F),
    icon: Icons.receipt_rounded,
  ),
];

class DocumentTemplatesScreen extends StatefulWidget {
  const DocumentTemplatesScreen({super.key});

  @override
  State<DocumentTemplatesScreen> createState() => _DocumentTemplatesScreenState();
}

class _DocumentTemplatesScreenState extends State<DocumentTemplatesScreen> {
  _TemplateType? _selectedType; // null == All

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedType == null
        ? _kDummyTemplates
        : _kDummyTemplates.where((t) => t.type == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Document Templates')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _TypeChip(
                  label: 'All',
                  isSelected: _selectedType == null,
                  onTap: () => setState(() => _selectedType = null),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Invoices',
                  isSelected: _selectedType == _TemplateType.invoice,
                  onTap: () => setState(() => _selectedType = _TemplateType.invoice),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Quotes',
                  isSelected: _selectedType == _TemplateType.quote,
                  onTap: () => setState(() => _selectedType = _TemplateType.quote),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Receipts',
                  isSelected: _selectedType == _TemplateType.receipt,
                  onTap: () => setState(() => _selectedType = _TemplateType.receipt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No templates in this category yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, i) => _TemplateCard(data: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _TypeChip
// -----------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? const Color(0xFF1A1A2E)
        : (isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F5F5));
    final fg = isSelected ? Colors.white : cs.onSurface.withOpacity(0.55);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _TemplateCard
// -----------------------------------------------------------------------------

class _TemplateCard extends StatelessWidget {
  final _TemplateData data;

  const _TemplateCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.name} template preview coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [data.accent, data.accent.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, color: Colors.white, size: 34),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.style,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
