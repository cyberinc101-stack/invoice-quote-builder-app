// quote_template_chooser_screen.dart
// lib/screens/quote_template_chooser_screen.dart
//
// Mirrors invoice_template_chooser_screen.dart, including edit-existing
// support (pass existingQuoteId). In that mode, "Save & Continue" calls
// provider.loadSavedQuote(id) before pushing QuoteEditorScreen, so its
// initState (which seeds from provider.quoteData) picks up the real saved
// fields.
//
// KNOWN GAP (documented in quote_editor_screen.dart itself): the editor's
// Business Info / Client steps require re-selecting a saved profile/client
// card — they don't auto-match the loaded quote's raw business/client
// strings back to a saved profile. Editing an existing quote via this path
// will land on populated Quote Details/Line Items/Review, but Business
// Info and Client & Details will show as "not yet selected" until the
// user re-picks the matching saved card (or adds a new one). Flag if you
// want this reconciled — it needs either fuzzy-matching against the saved
// library by field values, or synthesizing a placeholder profile/client
// from the quote's own stored strings.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/quote_provider.dart';
import '../widgets/template_full_preview_modal.dart';
import 'quote_editor_screen.dart';
import 'create_quote_section/quote_step_template_chooser_registry.dart';
import 'create_quote_section/quote_template_chooser_01/preview_registry.dart';

const String _kLastQuoteTemplateKey = 'last_quote_template_id';

class QuoteTemplateChooserScreen extends StatefulWidget {
  /// When set, this chooser is being opened to edit an EXISTING saved
  /// quote rather than start a new one.
  final String? existingQuoteId;

  const QuoteTemplateChooserScreen({super.key, this.existingQuoteId});

  @override
  State<QuoteTemplateChooserScreen> createState() => _QuoteTemplateChooserScreenState();
}

class _QuoteTemplateChooserScreenState extends State<QuoteTemplateChooserScreen> {
  int? _selectedId;

  bool get _isEditingExisting => widget.existingQuoteId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialSelection();
  }

  Future<void> _loadInitialSelection() async {
    if (_isEditingExisting) {
      final provider = context.read<QuoteProvider>();
      final existing = provider.getQuoteById(widget.existingQuoteId!);
      if (existing != null && mounted) {
        setState(() => _selectedId = existing.data.layoutTemplateId);
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kLastQuoteTemplateKey);
    if (saved != null && mounted) {
      setState(() => _selectedId = saved);
    }
  }

  Future<void> _persistSelected(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastQuoteTemplateKey, id);
  }

  void _tapCard(QuoteTemplateInfo info) {
    if (!info.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${info.name} is coming soon.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _selectedId = info.id);
  }

  void _continue() {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a template to continue'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _persistSelected(_selectedId!);

    if (_isEditingExisting) {
      final provider = context.read<QuoteProvider>();
      provider.loadSavedQuote(widget.existingQuoteId!);
      provider.updateLayoutTemplateId(_selectedId!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuoteEditorScreen(layoutTemplateId: _selectedId!),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteEditorScreen(layoutTemplateId: _selectedId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
                childAspectRatio: 0.66,
              ),
              itemCount: kQuoteTemplates.length,
              itemBuilder: (context, i) {
                final info = kQuoteTemplates[i];
                return _TemplateCard(
                  info: info,
                  selected: _selectedId == info.id,
                  onTap: () => _tapCard(info),
                  onLongPress: () => showGenericTemplateFullPreview(
                    context,
                    name: info.name,
                    description: info.description,
                    accentColor: info.accentColor,
                    isPremium: info.isPremium,
                    preview: buildQuotePreview(info.id, sampleQuoteData()),
                  ),
                );
              },
            ),
          ),
          _buildContinueBar(context),
        ],
      ),
    );
  }

  Widget _buildContinueBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = _selectedId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      child: GestureDetector(
        onTap: _continue,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasSelection
                  ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                  : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: hasSelection
                ? const [BoxShadow(color: Color(0x504CAF50), blurRadius: 12, offset: Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: hasSelection ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Save & Continue',
                style: TextStyle(
                  color: hasSelection ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose a Design',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEditingExisting
                          ? 'Keep the current design or pick a new one'
                          : 'Pick a template to start your quote',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid card
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final QuoteTemplateInfo info;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _TemplateCard({required this.info, required this.selected, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: selected
                    ? Border.all(color: info.accentColor, width: 2.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: info.accentColor.withValues(alpha: info.available ? (selected ? 0.35 : 0.22) : 0.08),
                    blurRadius: selected ? 16 : 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.white),
                    Opacity(
                      opacity: info.available ? 1.0 : 0.45,
                      child: QuoteStepChooserScaledPreview(templateId: info.id),
                    ),
                    if (info.isPremium && info.available)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 11),
                              SizedBox(width: 3),
                              Text('PRO', style: TextStyle(
                                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    if (!info.available)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Coming Soon',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    if (selected && info.available)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: info.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                        ),
                      ),
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        height: 3,
                        color: info.accentColor.withValues(alpha: info.available ? 1 : 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  info.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: info.available
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected && info.available)
                Icon(Icons.radio_button_checked_rounded, size: 15, color: info.accentColor)
              else if (info.available)
                Icon(Icons.radio_button_off_rounded, size: 15, color: colorScheme.onSurface.withValues(alpha: 0.25)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            info.tag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: info.available
                  ? info.accentColor
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
