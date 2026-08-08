// quote_template_chooser_screen.dart
// lib/screens/quote_template_chooser_screen.dart
//
// Shown when "Create Quote" is pressed, BEFORE the quote editor stepper.
// Mirrors invoice_template_chooser_screen.dart exactly (same grid layout,
// same "Coming Soon" stub handling) — the only differences are the model
// types (QuoteTemplateInfo/kQuoteTemplates instead of the invoice ones)
// and the destination screen (QuoteEditorScreen instead of EditorScreen).
//
// As of this pass there is no quote layout template built yet (no
// lib/quote_layout_templates/ folder exists), so every card renders as
// "Coming Soon" — same starting point the invoice chooser had before
// Executive was built. Wiring a real design later is: build the layout,
// flip `available: true` on its entry in preview_registry.dart, and add
// its id to buildQuotePreview() there — nothing in this file changes.

import 'package:flutter/material.dart';
import 'quote_editor_screen.dart';
import 'create_quote_section/quote_step_template_chooser_registry.dart';
import 'create_quote_section/quote_template_chooser_01/preview_registry.dart';

class QuoteTemplateChooserScreen extends StatelessWidget {
  const QuoteTemplateChooserScreen({super.key});

  void _select(BuildContext context, QuoteTemplateInfo info) {
    if (!info.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${info.name} is coming soon.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteEditorScreen(layoutTemplateId: info.id),
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
                  onTap: () => _select(context, info),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose a Design',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pick a template to start your quote',
                      style: TextStyle(
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
  final VoidCallback onTap;
  const _TemplateCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: info.accentColor.withValues(alpha: info.available ? 0.22 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
          Text(
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
